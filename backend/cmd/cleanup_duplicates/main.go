package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"regexp"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/joho/godotenv"
)

func normalize(input string) string {
	input = strings.ToLower(strings.TrimSpace(input))
	re := regexp.MustCompile(`\s+`)
	input = re.ReplaceAllString(input, " ")
	input = strings.ReplaceAll(input, "'", "")
	input = strings.ReplaceAll(input, ",", "")
	return input
}

func main() {
	err := godotenv.Load(".env")
	if err != nil {
		log.Println("No .env file found")
	}

	dbUrl := os.Getenv("DATABASE_URL")
	if dbUrl == "" {
		log.Fatal("DATABASE_URL is not set")
	}

	ctx := context.Background()
	conn, err := pgx.Connect(ctx, dbUrl)
	if err != nil {
		log.Fatalf("Unable to connect to database: %v", err)
	}
	defer conn.Close(ctx)

	log.Println("Connected. Starting duplicate cleanup...")

	tx, err := conn.Begin(ctx)
	if err != nil {
		log.Fatalf("Failed to begin tx: %v", err)
	}
	defer tx.Rollback(ctx)

	// 1. Add fingerprint column if not exists
	_, err = tx.Exec(ctx, `ALTER TABLE products ADD COLUMN IF NOT EXISTS fingerprint VARCHAR(255);`)
	if err != nil {
		log.Fatalf("Failed to alter table: %v", err)
	}

	// 2. Fetch all products and assign fingerprint
	type Product struct {
		ID      string
		Barcode string
		Name    string
		Brand   *string
	}
	
	rows, err := tx.Query(ctx, `SELECT id, barcode, name, (SELECT name FROM brands WHERE brands.id = products.brand_id) FROM products ORDER BY created_at ASC`)
	if err != nil {
		log.Fatalf("Failed to fetch products: %v", err)
	}

	var products []Product
	for rows.Next() {
		var p Product
		if err := rows.Scan(&p.ID, &p.Barcode, &p.Name, &p.Brand); err != nil {
			log.Fatalf("Scan error: %v", err)
		}
		products = append(products, p)
	}
	rows.Close()

	fingerprints := make(map[string]string)
	canonical := make(map[string]Product)

	for _, p := range products {
		var fp string
		if p.Barcode != "" && !strings.HasPrefix(p.Barcode, "manual_") {
			fp = p.Barcode
		} else {
			brandStr := ""
			if p.Brand != nil {
				brandStr = normalize(*p.Brand)
			}
			fp = normalize(brandStr) + "|" + normalize(p.Name)
		}
		
		fingerprints[p.ID] = fp

		// Update product with fingerprint
		_, err := tx.Exec(ctx, `UPDATE products SET fingerprint = $1 WHERE id = $2`, fp, p.ID)
		if err != nil {
			log.Fatalf("Update fingerprint error: %v", err)
		}

		if existing, ok := canonical[fp]; ok {
			log.Printf("Duplicate found: %s and %s (FP: %s)", existing.ID, p.ID, fp)
			// Move dependent records to 'existing' (which is canonical)
			tables := []string{"product_nutrition", "product_ingredients", "product_claims"}
			for _, table := range tables {
				// attempt update
				_, _ = tx.Exec(ctx, fmt.Sprintf(`UPDATE %s SET product_id = $1 WHERE product_id = $2`, table), existing.ID, p.ID)
			}

			// Update barcode references
			barcodeTables := []string{"product_reviews", "product_discussions"}
			for _, table := range barcodeTables {
				_, _ = tx.Exec(ctx, fmt.Sprintf(`UPDATE %s SET product_barcode = $1 WHERE product_barcode = $2`, table), existing.Barcode, p.Barcode)
			}
			
			// Delete duplicate
			_, err = tx.Exec(ctx, `DELETE FROM products WHERE id = $1`, p.ID)
			if err != nil {
				log.Fatalf("Failed to delete duplicate product %s: %v", p.ID, err)
			}
		} else {
			canonical[fp] = p
		}
	}

	// 3. Add UNIQUE constraint to fingerprint (drop if exists first just in case)
	_, _ = tx.Exec(ctx, `ALTER TABLE products DROP CONSTRAINT IF EXISTS products_fingerprint_key;`)
	_, err = tx.Exec(ctx, `ALTER TABLE products ADD CONSTRAINT products_fingerprint_key UNIQUE (fingerprint);`)
	if err != nil {
		log.Printf("Warning: Failed to add UNIQUE constraint: %v", err)
	}

	err = tx.Commit(ctx)
	if err != nil {
		log.Fatalf("Failed to commit: %v", err)
	}

	log.Println("Duplicate cleanup completed successfully.")
}

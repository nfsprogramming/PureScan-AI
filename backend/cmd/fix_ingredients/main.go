package main

import (
	"context"
	"log"
	"os"

	"github.com/jackc/pgx/v5"
	"github.com/joho/godotenv"
)

func main() {
	godotenv.Load(".env")
	dbUrl := os.Getenv("DATABASE_URL")
	ctx := context.Background()
	conn, err := pgx.Connect(ctx, dbUrl)
	if err != nil {
		log.Fatalf("Unable to connect: %v", err)
	}
	defer conn.Close(ctx)

	// Update products with ingredients_text from product_submissions
	query := `
		UPDATE products p
		SET ingredients_text = ps.ingredients_text
		FROM product_submissions ps
		WHERE p.barcode = ps.barcode AND p.ingredients_text IS NULL AND ps.ingredients_text IS NOT NULL
	`
	tag, err := conn.Exec(ctx, query)
	if err != nil {
		log.Fatalf("Update failed: %v", err)
	}

	log.Printf("Updated %d products with ingredients text", tag.RowsAffected())
}

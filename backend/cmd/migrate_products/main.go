package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/jackc/pgx/v5"
	"github.com/joho/godotenv"
)

func main() {
	err := godotenv.Load(".env")
	if err != nil {
		log.Println("No .env file found, relying on environment variables")
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

	// We will drop products if it already exists, to apply the full schema cleanly.
	// But let's be careful. Let's just create the missing tables and modify products if needed.
	// We will just use CREATE TABLE IF NOT EXISTS.
	
	queries := []string{
		`CREATE TABLE IF NOT EXISTS brands (
			id UUID PRIMARY KEY,
			name VARCHAR(255) UNIQUE NOT NULL,
			website TEXT,
			country VARCHAR(100),
			created_at TIMESTAMP DEFAULT NOW()
		);`,
		// If products exists but lacks brand_id, we will alter it later if needed.
		// For simplicity, we drop the old products table if it's empty or we just recreate it.
		// Since we didn't use the old products table (it was just scaffolding), let's drop it to apply the correct schema.
		`DROP TABLE IF EXISTS product_nutrition CASCADE;`,
		`DROP TABLE IF EXISTS product_ingredients CASCADE;`,
		`DROP TABLE IF EXISTS product_claims CASCADE;`,
		`DROP TABLE IF EXISTS products CASCADE;`,
		
		`CREATE TABLE products (
			id UUID PRIMARY KEY,
			brand_id UUID REFERENCES brands(id),
			barcode VARCHAR(50) UNIQUE,
			name VARCHAR(255) NOT NULL,
			category VARCHAR(100),
			image_url TEXT,
			trust_score INTEGER,
			health_rating VARCHAR(50),
			ingredients_text TEXT,
			created_at TIMESTAMP DEFAULT NOW(),
			updated_at TIMESTAMP DEFAULT NOW()
		);`,
		
		`CREATE TABLE product_nutrition (
			id UUID PRIMARY KEY,
			product_id UUID REFERENCES products(id),
			calories NUMERIC,
			protein NUMERIC,
			carbohydrates NUMERIC,
			sugar NUMERIC,
			fat NUMERIC,
			saturated_fat NUMERIC,
			sodium NUMERIC,
			serving_size VARCHAR(100)
		);`,
		
		`CREATE TABLE product_ingredients (
			product_id UUID REFERENCES products(id),
			ingredient_name VARCHAR(255),
			ingredient_order INTEGER,
			PRIMARY KEY(product_id, ingredient_name)
		);`,
		
		`CREATE TABLE product_claims (
			id UUID PRIMARY KEY,
			product_id UUID REFERENCES products(id),
			claim_name VARCHAR(100),
			verified BOOLEAN,
			verification_reason TEXT
		);`,
	}

	for _, query := range queries {
		_, err := conn.Exec(ctx, query)
		if err != nil {
			log.Fatalf("Failed to execute query: %v\nError: %v", query, err)
		}
	}

	fmt.Println("Phase 2 PostgreSQL tables created successfully!")
}

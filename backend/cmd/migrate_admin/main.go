package main

import (
	"context"
	"log"
	"os"

	"github.com/jackc/pgx/v5"
	"github.com/joho/godotenv"
)

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

	log.Println("Connected to PostgreSQL. Running migrations...")

	// 1. Create product_submissions table
	_, err = conn.Exec(ctx, `
		CREATE TABLE IF NOT EXISTS product_submissions (
			id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
			barcode TEXT NOT NULL,
			product_name TEXT NOT NULL,
			user_id UUID REFERENCES auth.users(id),
			status TEXT NOT NULL DEFAULT 'pending', -- pending, approved, rejected
			created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
		);
	`)
	if err != nil {
		log.Fatalf("Failed to create product_submissions table: %v", err)
	}

	// 2. Create admins table
	_, err = conn.Exec(ctx, `
		CREATE TABLE IF NOT EXISTS admins (
			user_id UUID PRIMARY KEY REFERENCES auth.users(id),
			created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
		);
	`)
	if err != nil {
		log.Fatalf("Failed to create admins table: %v", err)
	}

	log.Println("Migrations applied successfully!")
}

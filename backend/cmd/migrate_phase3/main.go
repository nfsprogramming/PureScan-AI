package main

import (
	"context"
	"log"
	"os"

	"github.com/jackc/pgx/v5"
	"github.com/joho/godotenv"
)

func main() {
	err := godotenv.Load()
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
		log.Fatalf("Unable to connect to database: %v\n", err)
	}
	defer conn.Close(ctx)

	log.Println("Setting statement_cache_capacity=0 for PgBouncer compatibility...")
	_, err = conn.Exec(ctx, "SET statement_cache_capacity=0")
	if err != nil {
		log.Printf("Warning: Failed to set statement_cache_capacity: %v", err)
	}

	log.Println("Creating user_preferences table...")
	_, err = conn.Exec(ctx, `
		CREATE TABLE IF NOT EXISTS public.user_preferences (
			user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
			diets JSONB DEFAULT '[]'::jsonb,
			allergies JSONB DEFAULT '[]'::jsonb,
			created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
			updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
		);
	`)
	if err != nil {
		log.Fatalf("Failed to create user_preferences: %v\n", err)
	}

	log.Println("Successfully migrated Phase 3 tables!")
}

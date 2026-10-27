package main

import (
	"context"
	"log"
	"os"

	"github.com/jackc/pgx/v5"
	"github.com/joho/godotenv"
)

func main() {
	err := godotenv.Load("../../.env")
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

	log.Println("Altering user_preferences table to add notification toggles...")
	_, err = conn.Exec(ctx, `
		ALTER TABLE public.user_preferences 
		ADD COLUMN IF NOT EXISTS alerts_enabled BOOLEAN DEFAULT true,
		ADD COLUMN IF NOT EXISTS daily_digest_enabled BOOLEAN DEFAULT true;
	`)
	if err != nil {
		log.Fatalf("Failed to alter user_preferences: %v\n", err)
	}

	log.Println("Successfully migrated Push Notification columns!")
}

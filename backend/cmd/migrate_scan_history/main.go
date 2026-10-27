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
	err := godotenv.Load()
	if err != nil {
		log.Fatal("Error loading .env file")
	}

	dbUrl := os.Getenv("DATABASE_URL")
	ctx := context.Background()
	conn, err := pgx.Connect(ctx, dbUrl)
	if err != nil {
		log.Fatalf("Unable to connect to database: %v\n", err)
	}
	defer conn.Close(ctx)

	_, err = conn.Exec(ctx, `
		ALTER TABLE public.scan_history 
		ADD COLUMN IF NOT EXISTS ingredient_id UUID REFERENCES public.ingredients(id),
		ADD COLUMN IF NOT EXISTS report_json JSONB;
	`)
	
	if err != nil {
		log.Fatalf("Failed to alter table: %v\n", err)
	}

	fmt.Println("Successfully migrated scan_history table!")
}

package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"path/filepath"

	"github.com/jackc/pgx/v5"
	"github.com/joho/godotenv"
)

func main() {
	err := godotenv.Load(filepath.Join("..", "..", ".env"))
	if err != nil {
		log.Println("Warning: No .env file found or error loading it.")
	}

	dbURL := os.Getenv("DATABASE_URL")
	ctx := context.Background()
	conn, err := pgx.Connect(ctx, dbURL)
	if err != nil {
		log.Fatalf("Unable to connect to database: %v\n", err)
	}
	defer conn.Close(ctx)

	rows, err := conn.Query(ctx, "SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'ingredients'")
	if err != nil {
		log.Fatalf("Query failed: %v", err)
	}
	defer rows.Close()

	fmt.Println("Columns in 'ingredients' table:")
	for rows.Next() {
		var colName, dataType string
		rows.Scan(&colName, &dataType)
		fmt.Printf("- %s (%s)\n", colName, dataType)
	}
}

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

	var userID string
	err = conn.QueryRow(ctx, "SELECT id FROM auth.users LIMIT 1").Scan(&userID)
	if err != nil {
		log.Fatalf("Failed to fetch user: %v", err)
	}

	_, err = conn.Exec(ctx, "INSERT INTO admins (user_id) VALUES ($1) ON CONFLICT (user_id) DO NOTHING", userID)
	if err != nil {
		log.Fatalf("Failed to make admin: %v", err)
	}

	log.Printf("User %s is now an admin!", userID)
}

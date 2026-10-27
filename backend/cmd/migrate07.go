package main

import (
	"context"
	"fmt"
	"os"

	"github.com/jackc/pgx/v5"
	"github.com/joho/godotenv"
)

func main() {
	_ = godotenv.Load(".env")
	dbUrl := os.Getenv("DATABASE_URL")
	if dbUrl == "" {
		fmt.Println("No DATABASE_URL found")
		return
	}
	ctx := context.Background()
	conn, err := pgx.Connect(ctx, dbUrl)
	if err != nil {
		fmt.Println("Connect error:", err)
		return
	}
	defer conn.Close(ctx)

	sql, err := os.ReadFile("db/migrations/07_user_dietary_profiles.sql")
	if err != nil {
		fmt.Println("Read file error:", err)
		return
	}

	_, err = conn.Exec(ctx, string(sql))
	if err != nil {
		fmt.Println("Exec error:", err)
		return
	}
	fmt.Println("Migration 07 applied successfully!")
}

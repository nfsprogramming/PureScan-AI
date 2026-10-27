package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"github.com/joho/godotenv"
	"github.com/purescanai/backend/internal/db"
)

func main() {
	godotenv.Load(".env")
	db.InitDB()
	defer db.CloseDB()

	sql, err := os.ReadFile("db/migrations/08_audit_logs.sql")
	if err != nil {
		log.Fatal(err)
	}

	_, err = db.Pool.Exec(context.Background(), string(sql))
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println("Migration applied successfully!")
}

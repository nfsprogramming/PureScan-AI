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
	ctx := context.Background()
	conn, _ := pgx.Connect(ctx, dbUrl)
	defer conn.Close(ctx)

	rows, _ := conn.Query(ctx, "SELECT column_name FROM information_schema.columns WHERE table_name = 'scan_history';")
	for rows.Next() {
		var col string
		rows.Scan(&col)
		fmt.Println(col)
	}
}

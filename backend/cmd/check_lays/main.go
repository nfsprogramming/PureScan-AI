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
	godotenv.Load(".env")
	dbUrl := os.Getenv("DATABASE_URL")
	ctx := context.Background()
	conn, err := pgx.Connect(ctx, dbUrl)
	if err != nil {
		log.Fatalf("Unable to connect: %v", err)
	}
	defer conn.Close(ctx)

	query := `
		SELECT
			sh.report_json,
			i.parsed_json,
			i.trust_score_report
		FROM 
			scan_history sh
		LEFT JOIN ingredients i ON sh.ingredient_id = i.id
		WHERE sh.report_json::jsonb->>'final_score' = '63'
		LIMIT 1
	`
	rows, err := conn.Query(ctx, query)
	if err != nil {
		log.Fatalf("Query failed: %v", err)
	}
	defer rows.Close()

	if rows.Next() {
		var r1, r2, r3 *string
		rows.Scan(&r1, &r2, &r3)
		if r1 != nil { fmt.Printf("report_json: %s\n\n", *r1) } else { fmt.Println("report_json: null") }
		if r2 != nil { fmt.Printf("parsed_json: %s\n\n", *r2) } else { fmt.Println("parsed_json: null") }
		if r3 != nil { fmt.Printf("trust_score_report: %s\n\n", *r3) } else { fmt.Println("trust_score_report: null") }
	} else {
		fmt.Println("No scan with final_score = 63 found")
	}
}

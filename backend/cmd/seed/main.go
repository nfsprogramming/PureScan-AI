package main

import (
	"context"
	"encoding/csv"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/joho/godotenv"
)

func main() {
	// Load .env file from the backend root
	err := godotenv.Load(filepath.Join("..", "..", ".env"))
	if err != nil {
		log.Println("Warning: No .env file found or error loading it. Relying on environment variables.")
	}

	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		log.Fatal("DATABASE_URL environment variable is not set")
	}

	ctx := context.Background()
	conn, err := pgx.Connect(ctx, dbURL)
	if err != nil {
		log.Fatalf("Unable to connect to database: %v\n", err)
	}
	defer conn.Close(ctx)

	// Create table if it doesn't exist (just in case)
	createTableQuery := `
	CREATE TABLE IF NOT EXISTS ingredient_dictionary (
		id UUID PRIMARY KEY,
		name VARCHAR(255) UNIQUE,
		category VARCHAR(100),
		ins_number VARCHAR(50),
		description TEXT,
		purpose TEXT,
		risk_score INTEGER,
		risk_level VARCHAR(50),
		fssai_status VARCHAR(50),
		fda_status VARCHAR(50),
		efsa_status VARCHAR(50),
		allergen BOOLEAN,
		consumer_summary TEXT,
		eat_recommendation TEXT,
		created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
	);
	`
	_, err = conn.Exec(ctx, createTableQuery)
	if err != nil {
		log.Fatalf("Failed to create table: %v\n", err)
	}

	// Read CSV file
	file, err := os.Open("ingredients.csv")
	if err != nil {
		log.Fatalf("Failed to open CSV file: %v\n", err)
	}
	defer file.Close()

	reader := csv.NewReader(file)
	// Skip header
	_, err = reader.Read()
	if err != nil {
		log.Fatalf("Failed to read header: %v\n", err)
	}

	records, err := reader.ReadAll()
	if err != nil {
		log.Fatalf("Failed to read CSV records: %v\n", err)
	}

	insertedCount := 0
	updatedCount := 0

	insertQuery := `
	INSERT INTO ingredient_dictionary (
		id, name, category, ins_number, description, purpose, 
		risk_score, risk_level, fssai_status, fda_status, efsa_status, 
		allergen, consumer_summary, eat_recommendation
	) VALUES (
		gen_random_uuid(), $1, $2, $3, $4, $5, 
		$6, $7, $8, $9, $10, 
		$11, $12, $13
	)
	ON CONFLICT (name) DO UPDATE SET
		category = EXCLUDED.category,
		ins_number = EXCLUDED.ins_number,
		description = EXCLUDED.description,
		purpose = EXCLUDED.purpose,
		risk_score = EXCLUDED.risk_score,
		risk_level = EXCLUDED.risk_level,
		fssai_status = EXCLUDED.fssai_status,
		fda_status = EXCLUDED.fda_status,
		efsa_status = EXCLUDED.efsa_status,
		allergen = EXCLUDED.allergen,
		consumer_summary = EXCLUDED.consumer_summary,
		eat_recommendation = EXCLUDED.eat_recommendation;
	`

	for i, record := range records {
		if len(record) < 14 {
			log.Printf("Row %d has insufficient columns, skipping\n", i+2)
			continue
		}

		name := strings.TrimSpace(record[1])
		category := strings.TrimSpace(record[2])
		insNumber := strings.TrimSpace(record[3])
		if insNumber == "N/A" {
			insNumber = ""
		}
		description := strings.TrimSpace(record[4])
		purpose := strings.TrimSpace(record[5])
		
		riskScoreStr := strings.TrimSpace(record[6])
		riskScore, _ := strconv.Atoi(riskScoreStr)
		
		riskLevel := strings.TrimSpace(record[7])
		fssaiStatus := strings.TrimSpace(record[8])
		fdaStatus := strings.TrimSpace(record[9])
		efsaStatus := strings.TrimSpace(record[10])
		
		allergenStr := strings.ToLower(strings.TrimSpace(record[11]))
		allergen := allergenStr == "true"
		
		consumerSummary := strings.TrimSpace(record[12])
		eatRecommendation := strings.TrimSpace(record[13])

		tag, err := conn.Exec(ctx, insertQuery,
			name, category, insNumber, description, purpose,
			riskScore, riskLevel, fssaiStatus, fdaStatus, efsaStatus,
			allergen, consumerSummary, eatRecommendation,
		)

		if err != nil {
			log.Printf("Failed to insert/update %s: %v\n", name, err)
			continue
		}

		if tag.Insert() {
			insertedCount++
		} else {
			updatedCount++
		}
	}

	fmt.Printf("Successfully seeded database! Inserted: %d, Updated: %d\n", insertedCount, updatedCount)
}

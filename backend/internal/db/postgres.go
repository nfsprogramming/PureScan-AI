package db

import (
	"context"
	"fmt"
	"log"
	"os"
	"strings"

	"github.com/jackc/pgx/v5/pgxpool"
)

var Pool *pgxpool.Pool

func InitDB() {
	dbUrl := os.Getenv("DATABASE_URL")
	if dbUrl == "" {
		log.Fatal("DATABASE_URL environment variable is not set")
	}

	// Fix for Supabase PgBouncer (Port 6543) Prepared Statement Bug (SQLSTATE 42P05)
	if !strings.Contains(dbUrl, "statement_cache_capacity=0") {
		if strings.Contains(dbUrl, "?") {
			dbUrl += "&statement_cache_capacity=0&default_query_exec_mode=exec"
		} else {
			dbUrl += "?statement_cache_capacity=0&default_query_exec_mode=exec"
		}
	}

	ctx := context.Background()
	var err error
	Pool, err = pgxpool.New(ctx, dbUrl)
	if err != nil {
		log.Fatalf("Unable to connect to database: %v\n", err)
	}

	err = Pool.Ping(ctx)
	if err != nil {
		log.Fatalf("Unable to ping database: %v\n", err)
	}

	fmt.Println("Connected to Supabase PostgreSQL database successfully!")
}

func CloseDB() {
	if Pool != nil {
		Pool.Close()
	}
}

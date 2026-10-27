package main

import (
	"context"
	"log"
	"os"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/joho/godotenv"
)

func main() {
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found")
	}

	dbUrl := os.Getenv("DATABASE_URL")
	if dbUrl == "" {
		log.Fatal("DATABASE_URL is required")
	}

	ctx := context.Background()
	pool, err := pgxpool.New(ctx, dbUrl)
	if err != nil {
		log.Fatalf("Unable to connect to database: %v\n", err)
	}
	defer pool.Close()

	schema := `
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Products Table
CREATE TABLE IF NOT EXISTS public.products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    barcode TEXT UNIQUE,
    name TEXT,
    brand TEXT,
    trust_score INTEGER,
    rating TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ingredients Caching Table
CREATE TABLE IF NOT EXISTS public.ingredients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    raw_text TEXT UNIQUE,
    parsed_json JSONB,
    trust_score_report JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Scan History Table
CREATE TABLE IF NOT EXISTS public.scan_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
    scan_type TEXT CHECK (scan_type IN ('barcode', 'ocr')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Row Level Security (RLS)
ALTER TABLE public.scan_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own scan history" 
ON public.scan_history FOR SELECT 
TO authenticated 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own scan history" 
ON public.scan_history FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = user_id);

-- Expose to Data API
GRANT ALL ON TABLE public.products TO anon, authenticated;
GRANT ALL ON TABLE public.ingredients TO anon, authenticated;
GRANT ALL ON TABLE public.scan_history TO authenticated;
`

	_, err = pool.Exec(ctx, schema)
	if err != nil {
		log.Fatalf("Failed to execute schema: %v\n", err)
	}

	log.Println("Migration successful! Tables created.")
}

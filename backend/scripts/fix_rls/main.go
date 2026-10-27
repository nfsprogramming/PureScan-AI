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
-- Enable RLS on products table
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read products
CREATE POLICY "Anyone can view products" 
ON public.products FOR SELECT 
TO anon, authenticated 
USING (true);

-- Enable RLS on ingredients table
ALTER TABLE public.ingredients ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read cached ingredients
CREATE POLICY "Anyone can view ingredients" 
ON public.ingredients FOR SELECT 
TO anon, authenticated 
USING (true);
`

	_, err = pool.Exec(ctx, schema)
	if err != nil {
		log.Fatalf("Failed to execute RLS fix: %v\n", err)
	}

	log.Println("RLS fixes applied successfully!")
}

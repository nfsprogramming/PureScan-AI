-- Add missing columns to product_submissions for community requests
-- If they already exist, this will simply skip safely if run carefully, but PostgreSQL doesn't have ADD COLUMN IF NOT EXISTS without PL/pgSQL block, so we'll do an idempotent block.

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='product_submissions' AND column_name='brand_name') THEN
        ALTER TABLE public.product_submissions ADD COLUMN brand_name TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='product_submissions' AND column_name='ingredients_text') THEN
        ALTER TABLE public.product_submissions ADD COLUMN ingredients_text TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='product_submissions' AND column_name='report_json') THEN
        ALTER TABLE public.product_submissions ADD COLUMN report_json TEXT;
    END IF;
END $$;

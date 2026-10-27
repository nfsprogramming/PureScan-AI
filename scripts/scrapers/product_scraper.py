import os
import sys
import uuid
import json
import urllib.request
import psycopg2
from psycopg2.extras import execute_values

def get_db_url():
    env_path = os.path.join(os.path.dirname(__file__), '..', '..', 'backend', '.env')
    if os.path.exists(env_path):
        with open(env_path, 'r') as f:
            for line in f:
                if line.startswith('DATABASE_URL='):
                    return line.strip().split('=', 1)[1].strip('\'"')
    return None

def fetch_openfoodfacts_products(page=1, page_size=200):
    url = f"https://world.openfoodfacts.org/cgi/search.pl?action=process&sort_by=unique_scans_n&page={page}&page_size={page_size}&json=true"
    headers = {
        'User-Agent': 'PureScanAI - DataPipeline - Version 1.0 - Contact: admin@purescan.ai'
    }
    
    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode())
            return data.get('products', [])
    except Exception as e:
        print(f"Failed to fetch page {page}: {e}")
        return []

def main():
    print("Starting Phase 2 Product Import Service...")
    db_url = get_db_url()
    if not db_url:
        print("DATABASE_URL not found!")
        sys.exit(1)
        
    conn = psycopg2.connect(db_url)
    cur = conn.cursor()
    
    products_to_insert = []
    brands_to_insert = {} # map brand_name -> brand_id
    
    print("Fetching top products from Open Food Facts...")
    
    # Let's fetch the top 1000 scanned products (5 pages of 200)
    for page in range(1, 6):
        print(f"Fetching page {page}/5...")
        products = fetch_openfoodfacts_products(page=page, page_size=200)
        
        for p in products:
            barcode = p.get('code')
            name = p.get('product_name')
            brand_name = p.get('brands')
            if not barcode or not name:
                continue
                
            # Clean up brand name
            if brand_name:
                brand_name = brand_name.split(',')[0].strip()
            else:
                brand_name = "Unknown"
                
            if brand_name not in brands_to_insert:
                brands_to_insert[brand_name] = str(uuid.uuid4())
                
            brand_id = brands_to_insert[brand_name]
            
            # Categories
            category = "Unknown"
            if p.get('categories_tags') and len(p.get('categories_tags')) > 0:
                category = p['categories_tags'][0].replace('en:', '').replace('-', ' ').title()
                
            image_url = p.get('image_front_url')
            ingredients_text = p.get('ingredients_text')
            
            products_to_insert.append((
                str(uuid.uuid4()),
                brand_id,
                barcode,
                name,
                category,
                image_url,
                ingredients_text
            ))

    print(f"Found {len(products_to_insert)} valid products across {len(brands_to_insert)} brands.")
    
    # 1. Insert Brands
    print("Inserting Brands...")
    brand_tuples = [(b_id, b_name) for b_name, b_id in brands_to_insert.items()]
    execute_values(cur, """
        INSERT INTO brands (id, name) VALUES %s 
        ON CONFLICT (name) DO NOTHING
    """, brand_tuples)
    
    # We must refetch brand IDs because some might have existed
    cur.execute("SELECT name, id FROM brands")
    db_brands = dict(cur.fetchall())
    
    # Update product tuples with correct DB brand IDs
    final_products = []
    for p in products_to_insert:
        b_name = next(name for name, id in brands_to_insert.items() if id == p[1])
        real_brand_id = db_brands.get(b_name, p[1]) # Fallback to generated if just inserted
        
        final_products.append((
            p[0], real_brand_id, p[2], p[3], p[4], p[5], p[6]
        ))
    
    # 2. Insert Products
    print("Inserting Products...")
    execute_values(cur, """
        INSERT INTO products (id, brand_id, barcode, name, category, image_url, ingredients_text)
        VALUES %s
        ON CONFLICT (barcode) DO NOTHING
    """, final_products)
    
    conn.commit()
    cur.close()
    conn.close()
    print("Product pipeline import completed successfully!")

if __name__ == "__main__":
    main()

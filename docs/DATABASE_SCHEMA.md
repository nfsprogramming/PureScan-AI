# DATABASE_SCHEMA.md

# PureScan AI Database Schema

## Overview

Database: PostgreSQL 16+

Purpose:

- User Management
- Product Management
- Ingredient Intelligence
- Trust Score System
- Product Reviews
- Scan History
- Recommendation Engine

---

# Entity Relationship Overview

```text
Users
 ├── Scans
 ├── Reviews
 ├── User_Allergies
 └── User_Preferences

Products
 ├── Product_Ingredients
 ├── Product_Claims
 ├── Product_Nutrition
 └── Reviews

Ingredients
 ├── Ingredient_Risks
 └── Product_Ingredients
```

---

# USERS

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255),
    profile_image TEXT,

    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

Purpose:

- User Accounts
- Authentication Mapping

---

# USER_PREFERENCES

```sql
CREATE TABLE user_preferences (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),

    diet_type VARCHAR(50),
    low_sugar BOOLEAN DEFAULT FALSE,
    low_sodium BOOLEAN DEFAULT FALSE,
    high_protein BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMP DEFAULT NOW()
);
```

Examples:

```text
vegan
vegetarian
keto
paleo
```

---

# ALLERGIES

```sql
CREATE TABLE allergies (
    id UUID PRIMARY KEY,
    name VARCHAR(100) UNIQUE
);
```

Examples:

```text
Milk
Gluten
Soy
Eggs
Peanuts
Tree Nuts
```

---

# USER_ALLERGIES

```sql
CREATE TABLE user_allergies (
    user_id UUID REFERENCES users(id),
    allergy_id UUID REFERENCES allergies(id),

    PRIMARY KEY(user_id, allergy_id)
);
```

---

# BRANDS

```sql
CREATE TABLE brands (
    id UUID PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL,

    website TEXT,
    country VARCHAR(100),

    created_at TIMESTAMP DEFAULT NOW()
);
```

---

# PRODUCTS

```sql
CREATE TABLE products (
    id UUID PRIMARY KEY,

    brand_id UUID REFERENCES brands(id),

    barcode VARCHAR(50) UNIQUE,

    name VARCHAR(255) NOT NULL,

    category VARCHAR(100),

    image_url TEXT,

    trust_score INTEGER,

    health_rating VARCHAR(50),

    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

---

# PRODUCT_NUTRITION

```sql
CREATE TABLE product_nutrition (
    id UUID PRIMARY KEY,

    product_id UUID REFERENCES products(id),

    calories NUMERIC,
    protein NUMERIC,
    carbohydrates NUMERIC,
    sugar NUMERIC,
    fat NUMERIC,
    saturated_fat NUMERIC,
    sodium NUMERIC,

    serving_size VARCHAR(100)
);
```

---

# INGREDIENTS

```sql
CREATE TABLE ingredients (
    id UUID PRIMARY KEY,

    name VARCHAR(255) UNIQUE NOT NULL,

    category VARCHAR(100),

    description TEXT,

    created_at TIMESTAMP DEFAULT NOW()
);
```

Examples:

```text
Sodium Benzoate
Citric Acid
Potassium Sorbate
Carrageenan
```

---

# INGREDIENT_RISKS

```sql
CREATE TABLE ingredient_risks (
    id UUID PRIMARY KEY,

    ingredient_id UUID REFERENCES ingredients(id),

    risk_level VARCHAR(50),

    risk_score INTEGER,

    summary TEXT,

    regulatory_status VARCHAR(100),

    created_at TIMESTAMP DEFAULT NOW()
);
```

Risk Levels:

```text
Low
Moderate
High
```

---

# PRODUCT_INGREDIENTS

Many-to-Many Relationship

```sql
CREATE TABLE product_ingredients (
    product_id UUID REFERENCES products(id),
    ingredient_id UUID REFERENCES ingredients(id),

    ingredient_order INTEGER,

    PRIMARY KEY(product_id, ingredient_id)
);
```

Purpose:

- Connect products and ingredients

---

# PRODUCT_CLAIMS

```sql
CREATE TABLE product_claims (
    id UUID PRIMARY KEY,

    product_id UUID REFERENCES products(id),

    claim_name VARCHAR(100),

    verified BOOLEAN,

    verification_reason TEXT
);
```

Examples:

```text
100% Organic
Natural
No Added Sugar
Preservative Free
```

---

# SCANS

```sql
CREATE TABLE scans (
    id UUID PRIMARY KEY,

    user_id UUID REFERENCES users(id),

    product_id UUID REFERENCES products(id),

    image_url TEXT,

    trust_score INTEGER,

    created_at TIMESTAMP DEFAULT NOW()
);
```

Purpose:

- Scan History
- Analytics

---

# REVIEWS

```sql
CREATE TABLE reviews (
    id UUID PRIMARY KEY,

    user_id UUID REFERENCES users(id),

    product_id UUID REFERENCES products(id),

    rating INTEGER,

    review TEXT,

    created_at TIMESTAMP DEFAULT NOW()
);
```

Rating:

```text
1 - 5
```

---

# SAVED_PRODUCTS

```sql
CREATE TABLE saved_products (
    user_id UUID REFERENCES users(id),

    product_id UUID REFERENCES products(id),

    created_at TIMESTAMP DEFAULT NOW(),

    PRIMARY KEY(user_id, product_id)
);
```

Purpose:

- Wishlist
- Favorites

---

# PRODUCT_ALTERNATIVES

```sql
CREATE TABLE product_alternatives (
    id UUID PRIMARY KEY,

    source_product_id UUID REFERENCES products(id),

    alternative_product_id UUID REFERENCES products(id),

    similarity_score NUMERIC
);
```

Purpose:

- Healthier Recommendations

---

# TRUST_SCORE_LOGS

```sql
CREATE TABLE trust_score_logs (
    id UUID PRIMARY KEY,

    product_id UUID REFERENCES products(id),

    score INTEGER,

    explanation TEXT,

    calculated_at TIMESTAMP DEFAULT NOW()
);
```

Purpose:

- Audit Trail
- Explainability

---

# SEARCH INDEXES

```sql
CREATE INDEX idx_products_name
ON products(name);

CREATE INDEX idx_products_barcode
ON products(barcode);

CREATE INDEX idx_ingredients_name
ON ingredients(name);

CREATE INDEX idx_scans_user
ON scans(user_id);

CREATE INDEX idx_reviews_product
ON reviews(product_id);
```

---

# Redis Cache Keys

```text
product:{barcode}

product:{id}

ingredient:{id}

ingredient:{name}

trust_score:{product_id}

user_profile:{user_id}
```

---

# Initial Seed Data

## Ingredients

- Sodium Benzoate
- Potassium Sorbate
- Citric Acid
- Ascorbic Acid
- Carrageenan

## Allergies

- Milk
- Gluten
- Soy
- Nuts
- Eggs

## Claims

- Organic
- Natural
- No Added Sugar
- Preservative Free

---

# Future Tables

Phase 2

```text
communities
comments
product_discussions
```

Phase 3

```text
nutrition_goals
family_profiles
```

Phase 4

```text
enterprise_accounts
api_keys
audit_logs
```

---

# Database Statistics Targets

MVP

```text
50,000 Products
5,000 Ingredients
100,000 Scans
10,000 Users
```

Year 1

```text
500,000 Products
50,000 Ingredients
5,000,000 Scans
100,000 Users
```

---

Database Version: 1.0

Database Engine: PostgreSQL

Status: Approved
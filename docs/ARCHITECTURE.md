# ARCHITECTURE.md

# PureScan AI Architecture

## Overview

PureScan AI is an AI-powered ingredient intelligence platform that enables consumers to understand food products by scanning ingredient labels or barcodes.

The platform consists of:

- Flutter Mobile Application
- OCR & Barcode Processing Layer
- Go Backend Services
- Ingredient Intelligence Engine
- Trust Score Engine
- AI Explanation Layer
- PostgreSQL Database
- Redis Cache
- Search Infrastructure
- Analytics Infrastructure

---

# High-Level Architecture

```text
┌─────────────────────────┐
│ Flutter App & Web App   │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│   OCR & Barcode Layer   │
│ Google ML Kit           │
│ Mobile Scanner          │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│     Go API Gateway      │
│       Gin Server        │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────────────┐
│       Core Business Layer       │
├─────────────────────────────────┤
│ Trust Score Engine              │
│ Ingredient Analyzer             │
│ Product Service                 │
│ User Service                    │
│ Claim Verification Service      │
│ Recommendation Service          │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│       Infrastructure Layer      │
├─────────────────────────────────┤
│ PostgreSQL                      │
│ Redis                           │
│ Meilisearch                     │
│ Cloudflare R2                   │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────┐
│   AI Explanation Layer  │
│     AI Model API        │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│  Final Health Report    │
└─────────────────────────┘
```

---

# Mobile Architecture

## Framework

Flutter

## State Management

Riverpod

## Navigation

Go Router

## Local Storage

Hive

---

# Mobile Modules

## Authentication Module

Responsibilities:

- Login
- Registration
- Session Management
- Token Refresh

---

## Scan Module

Responsibilities:

- Camera Access
- OCR Capture
- Barcode Scanning

---

## Product Module

Responsibilities:

- Product Search
- Product Details
- Product Comparison

---

## Profile Module

Responsibilities:

- User Settings
- Dietary Preferences
- Allergy Profiles

---

## History Module

Responsibilities:

- Scan History
- Saved Products
- Reports

---

# OCR Layer

## Technology

Google ML Kit

## Workflow

```text
Camera
   ↓
Image Capture
   ↓
OCR Processing
   ↓
Extracted Text
   ↓
Ingredient Parser
```

---

# Barcode Layer

## Technology

Mobile Scanner

## Workflow

```text
Barcode
   ↓
Lookup Product
   ↓
Retrieve Ingredients
   ↓
Analyze Product
```

---

# Backend Architecture

## Language

Go

## Framework

Gin

---

# API Layer

Responsibilities:

- Request Validation
- Authentication
- Rate Limiting
- Routing
- Logging

---

# Service Layer

Contains all business logic.

---

## User Service

Responsibilities:

- User Management
- Preferences
- Allergies
- Profile Management

---

## Product Service

Responsibilities:

- Product Retrieval
- Product Search
- Product Metadata

---

## Ingredient Analyzer

Responsibilities:

- Ingredient Normalization
- Ingredient Classification
- Risk Detection

Example:

```text
Sodium Benzoate
→ Preservative
→ Risk Level: Medium
```

---

## Trust Score Engine

Core intellectual property of the platform.

Responsibilities:

- Product Evaluation
- Score Calculation
- Health Rating Generation

Inputs:

- Ingredients
- Preservatives
- Artificial Colors
- Sugar Content
- Sodium Content
- Allergens

Outputs:

```text
Trust Score: 82/100
Health Rating: Good
```

---

## Claim Verification Service

Responsibilities:

Verify claims against ingredients.

Examples:

- Organic
- Natural
- No Preservatives
- No Added Sugar

---

## Recommendation Service

Responsibilities:

- Healthier Alternatives
- Product Comparison
- Personalized Recommendations

---

# AI Layer

## Provider

Advanced AI API

---

## Responsibilities

Generate:

- Ingredient Explanations
- Consumer Summaries
- Health Recommendations

Example:

```text
This product contains two preservatives.

While approved for food use, frequent consumption
may not be ideal.
```

---

# Database Architecture

## PostgreSQL

Primary source of truth.

---

# Core Tables

```text
users
products
ingredients
ingredient_risks
product_ingredients
claims
scans
reviews
allergies
```

---

# Relationship Diagram

```text
Products
    │
    ▼
ProductIngredients
    │
    ▼
Ingredients
    │
    ▼
IngredientRisks

Users
    │
    ▼
Scans

Users
    │
    ▼
Reviews

Users
    │
    ▼
Allergies
```

---

# Cache Architecture

## Redis

Purpose:

- Product Cache
- Ingredient Cache
- AI Response Cache

---

# Search Architecture

## Meilisearch

Indexes:

```text
products
ingredients
brands
```

Capabilities:

- Full Text Search
- Autocomplete
- Fast Filtering

---

# Storage Architecture

## Cloudflare R2

Stores:

- Product Images
- User Scan Images
- Generated Reports

---

# Security Architecture

## Authentication

Supabase Auth

Methods:

- Google Login
- Email Login
- OTP Login

---

## Authorization

JWT Tokens

Protected Endpoints:

```text
/scan
/history
/profile
/reviews
```

---

# Analytics Architecture

## PostHog

Track:

- Scan Volume
- Active Users
- Feature Usage
- Retention

---

# Deployment Architecture

## MVP

```text
Flutter App

Backend:
Render

Database:
Supabase PostgreSQL

Storage:
Cloudflare R2

Analytics:
PostHog
```

---

## Production Scale

```text
Flutter App
      │
      ▼
CloudFront CDN
      │
      ▼
AWS ECS/Fargate
      │
      ▼
PostgreSQL RDS
      │
      ▼
Redis ElastiCache
      │
      ▼
Cloudflare R2
```

---

# Non-Functional Requirements

## Performance

- Scan Response < 5 seconds
- Product Search < 300ms
- API Latency < 200ms

---

## Availability

Target:

```text
99.9% uptime
```

---

## Scalability

Support:

```text
10,000+ active users
100,000+ products
1,000,000+ scans
```

---

# Future Architecture

Phase 2:

- Recommendation Engine
- Product Alternatives
- Community Scores

Phase 3:

- Multi-language Support
- Global Product Database
- Nutrition Intelligence

Phase 4:

- Public API
- Enterprise Dashboard
- Retailer Integrations

---

PureScan AI Architecture

Version: 1.0
Status: Approved

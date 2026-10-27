# PROJECT_STRUCTURE.md

# PureScan AI - Project Structure

## Repository Layout

```text
purescan-ai/
│
├── README.md
├── LICENSE
├── render.yaml
├── .gitignore
│
├── docs/
│   ├── ARCHITECTURE.md
│   ├── DATABASE_SCHEMA.md
│   ├── FEATURES.md
│   ├── PROJECT_STRUCTURE.md
│   ├── ROADMAP.md
│   ├── TECH_STACK.md
│   └── TRUST_SCORE_ENGINE.md
│
├── mobile/               (Flutter Mobile Application)
│   ├── android/
│   ├── ios/
│   ├── assets/
│   ├── lib/
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   ├── scanner/
│   │   │   ├── profile/
│   │   │   └── user/
│   │   └── main.dart
│   └── pubspec.yaml
│
├── backend/              (Go API Services)
│   ├── cmd/
│   ├── internal/
│   ├── pkg/
│   ├── db/
│   ├── go.mod
│   └── docker-compose.yml
│
├── web/                  (React & Vite Web App / Dashboard)
│   ├── src/
│   │   ├── components/
│   │   ├── assets/
│   │   ├── App.jsx
│   │   └── main.jsx
│   ├── public/
│   ├── index.html
│   └── package.json
│
├── Portfolio/            (Marketing Website)
│   ├── css/
│   ├── js/
│   ├── assests/
│   ├── index.html
│   ├── privacy.html
│   └── terms.html
│
├── scripts/              (Python Utilities)
│   └── scrapers/
│       ├── fda_scraper.py
│       └── product_scraper.py
│
└── datasets/             (Raw Data)
    └── Food Ingredient Database.csv
```

---

# Architecture Principles

## Mobile
Feature-first architecture focusing on core domains.

## Backend
Domain-driven structure designed for fast scanning and complex data retrieval.

## Web
React-based interface for managing the platform or serving web users.

## Portfolio
Highly optimized, vanilla HTML/CSS/JS marketing landing page.

---

PureScan AI
Repository Structure v2.0
# 🥗 PureScan AI

**Intelligent Food Ingredient Scanner & Health Intelligence Platform**

[![License: MIT](https://img.shields.io/badge/License-MIT-emerald.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.47.7-blue.svg)](https://flutter.dev)
[![Go](https://img.shields.io/badge/Go-1.26+-00ADD8.svg)](https://golang.org)
[![React](https://img.shields.io/badge/React-19-61DAFB.svg)](https://react.dev)
[![Vite](https://img.shields.io/badge/Vite-8.0-646CFF.svg)](https://vitejs.dev)

PureScan AI is an open-source, multi-platform food transparency system. It empowers consumers to scan ingredient labels or barcodes in real time and instantly receive clear, science-backed risk ratings, additive analyses, allergy flags, and personalized health recommendations.

---

## 📱 System Components

The repository is organized into a modular multi-service architecture:

- **Mobile App (`mobile/`)**: Cross-platform mobile client built with Flutter and Riverpod. Features on-device OCR (Google ML Kit), barcode detection (Mobile Scanner), offline caching (Hive), personalized allergy warnings, scan history, community reviews, and PDF report export.
- **Backend API (`backend/`)**: High-performance Go (Gin) service powering ingredient lookup, Meilisearch full-text search, PostgreSQL relational storage (pgx pool), NVIDIA AI LLM explanations, admin workflows, and Firebase Cloud Messaging (FCM).
- **Web Portal (`web/`)**: React 19 + Vite application providing password recovery flows, terms of service, and privacy policies.
- **Marketing Landing Page (`Portfolio/`)**: High-performance static showcase featuring canvas particle physics, frame-by-frame 3D scroll animations, interactive analysis preview, and responsive design.
- **Data Scrapers (`scripts/scrapers/`)**: Python automation scripts for aggregating food safety databases, additive registries (FDA / FSSAI), and product information.
- **Datasets (`datasets/`)**: Reference ingredient and allergen dataset (`food_ingredients_and_allergens.csv`).
- **Technical Specs (`docs/`)**: In-depth architectural designs, database schemas, roadmap, and trust score engine documentation.

---

## ✨ Implemented Features

### 🔍 Real-Time Ingredient Scanner
- **On-Device OCR**: Optical character recognition powered by Google ML Kit Text Recognition.
- **Barcode Lookup**: Instant EAN/UPC product scanning using Mobile Scanner.
- **Ingredient Detection & Tokenization**: Intelligent parsing of complex packaging ingredient lists into individual components.

### 🛡️ Proprietary Trust Score Engine
- Evaluates ingredient safety on a 0–100 scale based on:
  - Additive toxicity & risk categorization (High, Moderate, Low, Safe)
  - Preservatives and artificial coloring detection
  - Regulatory approvals (FDA, FSSAI, EFSA)
  - Nutritional composition and whole-food ratios

### 🧬 Personalized Health Profiles & Allergy Warnings
- Configurable dietary preferences (Vegan, Vegetarian, Gluten-Free, Dairy-Free, Nut-Free).
- Immediate visual alerts dialog when a scanned product conflicts with the user's active health profile.

### 👥 Community & Reviews
- Real-time product discussion threads and user reviews stored in PostgreSQL with Supabase RLS policies.
- Community-driven safety feedback and additive ratings.

### 📄 Export & Bookmarks
- Export analysis reports to print-ready PDF files via `pdf` and `printing`.
- Native system share sheets via `share_plus`.
- Offline and local bookmarking of frequently scanned items.

---

## 🛠️ Technology Stack

| Layer | Technology | Purpose |
| :--- | :--- | :--- |
| **Mobile Client** | Flutter 3.x, Dart 3.x | Cross-platform Android, iOS, Windows, macOS, Linux |
| **Mobile State** | Flutter Riverpod | Reactive, predictable state management |
| **Mobile Vision** | Google ML Kit, Mobile Scanner | Real-time on-device OCR and barcode parsing |
| **Backend Core** | Go 1.26+, Gin Web Framework | High-concurrency RESTful API service |
| **Database** | PostgreSQL, pgx/v5 Pool | Relational database with schema migrations |
| **Search Engine** | Meilisearch | Sub-millisecond instant ingredient indexing |
| **Authentication** | Supabase Auth (JWT) | Secure user authentication and session management |
| **AI Integration** | NVIDIA NIM / LLM Client | Natural language ingredient summaries and risk context |
| **Notifications** | Firebase Cloud Messaging (FCM) | Daily digests and system safety notifications |
| **Web Portal** | React 19, Vite, Lucide Icons | Password reset, account management, legal views |
| **Marketing** | Vanilla HTML5, Modern CSS, ES6 JS | Particle canvas, 3D scroll sequence, glassmorphism |

---

## 📂 Project Structure

```text
PureScan-AI/
├── backend/                  # Go REST API Services
│   ├── cmd/
│   │   ├── api/              # API server entrypoint (main.go)
│   │   ├── seed/             # Database dictionary seeder & ingredients.csv
│   │   └── ...               # Migration & utility CLIs
│   ├── db/migrations/        # SQL schema migration files
│   ├── internal/             # Core business logic, handlers, DB repos, AI engine
│   └── docker-compose.yml    # Local backend dependencies (PostgreSQL, Meilisearch)
├── mobile/                   # Flutter Application
│   ├── android/              # Native Android configuration
│   ├── ios/                  # Native iOS configuration
│   ├── assets/               # Branding, splash screen, and graphic assets
│   ├── lib/
│   │   ├── core/             # Configuration, theme provider, error formatters
│   │   ├── features/         # Scanner, Auth, Profile, Community, User domains
│   │   └── main.dart         # Mobile application entrypoint
│   └── pubspec.yaml          # Flutter dependencies & metadata
├── web/                      # React / Vite Web Client
│   ├── src/                  # App components, legal pages, Supabase client
│   ├── index.html            # Single-page application entrypoint
│   └── package.json          # Vite & React dependencies
├── Portfolio/                # Showcase & Marketing Website
│   ├── analysis.html         # Live interactive scanner simulation
│   ├── css/style.css         # Glassmorphism, animations, responsive design
│   ├── js/app.js             # Canvas particles & scroll sequence controller
│   └── index.html            # Main landing page
├── datasets/                 # Food ingredient and allergen reference data
├── docs/                     # Architecture, schema, and engine documentation
├── scripts/scrapers/         # Python scrapers for FDA and product databases
├── render.yaml               # Cloud deployment descriptor for Render
└── LICENSE                   # MIT License
```

---

## 🚀 Getting Started

### Prerequisites

Ensure the following tools are installed on your environment:
- **Go**: `1.26` or higher
- **Flutter SDK**: `3.24` or higher (compatible with Dart `3.5+`)
- **Node.js**: `20.x` or higher and `npm`
- **PostgreSQL**: `15+` (or Docker for containerized setup)

---

### 1. Backend Setup

```bash
cd backend

# Download Go module dependencies
go mod download

# Optional: Run local PostgreSQL and Meilisearch with Docker
docker compose up -d

# Copy and configure environment variables
cp .env.example .env

# Run the API server
go run cmd/api/main.go
```

The API service starts by default on `http://localhost:8080`.

---

### 2. Mobile App Setup

```bash
cd mobile

# Fetch Flutter dependencies
flutter pub get

# Run on a connected device or emulator
flutter run
```

To build a release APK for Android:
```bash
flutter build apk --release
```

---

### 3. Web Dashboard Setup

```bash
cd web

# Install npm dependencies
npm install

# Start local Vite development server
npm run dev

# Build production bundle
npm run build
```

---

### 4. Marketing Portfolio

The marketing portfolio is built with vanilla HTML5, CSS3, and JavaScript without external compilation steps:

```bash
cd Portfolio

# Run using any static HTTP server (e.g., Python)
python -m http.server 8000
```
Open `http://localhost:8000` in your web browser.

---

## 🧪 Validation & Quality Checks

Run the automated suites to verify project integrity:

```bash
# Backend Go build validation
cd backend && go build -v ./cmd/api

# Web linting and production build
cd web && npm run lint && npm run build

# Mobile static analysis
cd mobile && flutter analyze
```

---

## 📦 Releases

Download the latest pre-compiled application packages and binaries from the [GitHub Releases](https://github.com/nfsprogramming/PureScan-AI/releases) section.

---

## 🔒 Security & Privacy

- All sensitive credentials (`.env`, private keys, keystores) are excluded from version control.
- Scanned ingredient images are analyzed on-device or streamed through encrypted HTTPS endpoints without storing personally identifiable image data.

---

## 🤝 Contributing

Contributions are welcome! Please open an issue or submit a pull request:
1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
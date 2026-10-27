# PureScan AI v1.0.1

PureScan AI is an open-source, multi-platform food transparency and ingredient intelligence system.

## Highlights & Implemented Features

- **On-Device Optical Character Recognition (OCR)**: Real-time ingredient label text recognition via Google ML Kit.
- **Instant Barcode Scanner**: EAN/UPC barcode detection powered by Mobile Scanner.
- **Science-Backed Trust Score Engine**: Transparent 0–100 rating algorithm assessing additive risk, preservatives, regulatory status (FDA/FSSAI/EFSA), and nutritional value.
- **Personalized Health & Allergy Warnings**: Real-time alerts for dietary restrictions (Vegan, Gluten-Free, Dairy-Free, Nut Allergies).
- **Go REST API & Search Service**: High-concurrency backend with Meilisearch sub-millisecond query indexing and PostgreSQL storage.
- **React 19 Web Dashboard**: Password recovery, privacy policy, and terms of service portal.
- **Marketing Showcase Landing Page**: Interactive 3D particle animations, scroll pass frame sequence, and simulated mobile scanner view.

## Included Artifacts

| File | Platform / Type | Description |
| :--- | :--- | :--- |
| `PureScanAI-v1.0.1.apk` | Android 5.0+ (API 21+) | Complete release APK for Android devices |
| `purescan-backend-windows-amd64.exe` | Windows x64 | Compiled standalone Go API server binary |
| `purescan-web-v1.0.1.zip` | Web / Static Hosting | Production Vite client build assets |

## Installation & Usage

### Android APK
1. Download `PureScanAI-v1.0.1.apk`.
2. Transfer or download onto your Android device.
3. Allow installation from unknown sources if prompted, and install.

### Windows Backend Binary
1. Download `purescan-backend-windows-amd64.exe`.
2. Ensure environment variables (or `.env` file) with `DATABASE_URL` are provided.
3. Run `.\purescan-backend-windows-amd64.exe`.

### Web Dashboard
1. Extract `purescan-web-v1.0.1.zip`.
2. Deploy the files to any static web host (Vercel, Cloudflare Pages, Nginx, or AWS S3).

## SHA-256 Checksums

```text
D9AC04C9CA8F511739362C2D35569589141BF2D0B3D9AB4F99F400C1CC51F19C  purescan-backend-windows-amd64.exe
21FCBBB712E0E6D27DBD3234014666B0E6EDE1298411335E025F53D80032DC58  purescan-web-v1.0.1.zip
A92DB58DF57D32FC755D87497FC1956DDAD9CB9B733ECE81B7CCF02E4A45619F  PureScanAI-v1.0.1.apk
```

## Known Issues & Notes

- Live backend sync requires Supabase and PostgreSQL database credentials (see `backend/.env.example`).
- Camera hardware permissions are required on Android for live OCR scanning.

# Dharma CMS — Configuration Guide

> Step-by-step instructions for configuring the backend securely in **development** and **production** environments.

---

## Table of Contents

- [1. Quick Start (Local Development)](#1-quick-start-local-development)
- [2. Firebase Credentials](#2-firebase-credentials)
  - [2a. Download Service Account JSON](#2a-download-service-account-json)
  - [2b. Backend Configuration](#2b-backend-configuration)
  - [2c. Flutter Frontend Configuration](#2c-flutter-frontend-configuration)
- [3. Database Configuration](#3-database-configuration)
  - [3a. Local Development (SQLite)](#3a-local-development-sqlite)
  - [3b. Local PostgreSQL](#3b-local-postgresql)
  - [3c. Production PostgreSQL](#3c-production-postgresql)
  - [3d. Secure Password Generation](#3d-secure-password-generation)
- [4. SECRET_KEY](#4-secret_key)
- [5. CORS Origins](#5-cors-origins)
- [6. Allowed Hosts](#6-allowed-hosts)
- [7. AI Service URL](#7-ai-service-url)
- [8. Upload Size Limit](#8-upload-size-limit)
- [9. Production Checklist](#9-production-checklist)
- [10. Docker Compose Setup](#10-docker-compose-setup)
- [11. Cloud Run Deployment](#11-cloud-run-deployment)
- [12. Environment Variable Reference](#12-environment-variable-reference)

---

## 1. Quick Start (Local Development)

For the fastest local setup (no PostgreSQL, no Firebase):

```bash
cd new_backend

# Create virtual environment
python -m venv venv
source venv/bin/activate      # Linux/Mac
# venv\Scripts\activate       # Windows

# Install dependencies
pip install -r requirements.txt

# Copy and edit environment file
cp .env.example .env
# Edit .env — defaults work for local dev (SQLite, no Firebase)

# Start the server
uvicorn main:app --reload --port 8000
```

This starts the API with:
- **SQLite** database (`dev.db` auto-created)
- **No Firebase** (auth endpoints will return 503 — use for API testing only)
- **Auto-seeded** geography data (26 districts, 958 stations, 1,418 pincodes)
- **Swagger docs** at http://localhost:8000/docs

---

## 2. Firebase Credentials

Firebase is used **only** for login (phone OTP, Google Sign-In) and token verification. No Firestore, no Cloud Functions.

### 2a. Download Service Account JSON

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (e.g., `dharma-cms-5cc89`)
3. Click **⚙️ Project Settings** → **Service Accounts** tab
4. Click **"Generate new private key"** → Download the JSON file
5. **Rename** it to something clear, e.g. `firebase-credentials.json`

> ⚠️ **NEVER commit this file to git.** It's already excluded by `.gitignore` (`*.json` rule).

### 2b. Backend Configuration

Place the JSON file in the `new_backend/` directory, then set in `.env`:

```env
FIREBASE_CREDENTIALS=firebase-credentials.json
```

**Absolute paths** also work:

```env
FIREBASE_CREDENTIALS=/home/deploy/secrets/firebase-credentials.json
```

**Cloud Run / GCE:** Leave empty to use Application Default Credentials:

```env
FIREBASE_CREDENTIALS=
```

### 2c. Flutter Frontend Configuration

The citizen frontend (`new_frontend/`) needs Firebase configured separately:

```bash
cd new_frontend

# Install FlutterFire CLI (one-time)
dart pub global activate flutterfire_cli

# Configure Firebase for your project
flutterfire configure --project=dharma-cms-5cc89
```

This generates `lib/firebase_options.dart` with your project's API keys and app IDs. This file is safe to commit (public keys, not secrets).

---

## 3. Database Configuration

### 3a. Local Development (SQLite)

**Default — zero install.** No configuration needed.

```env
DATABASE_URL=sqlite+aiosqlite:///dev.db
```

A `dev.db` file is auto-created in the project root with all 27 tables. Geography data is auto-seeded on first startup.

> SQLite is single-writer. Fine for development, not for production.

### 3b. Local PostgreSQL

If you prefer PostgreSQL locally:

```bash
# Create database and user
psql -U postgres -c "CREATE USER dharma WITH PASSWORD 'your_secure_password';"
psql -U postgres -c "CREATE DATABASE dharma_cms OWNER dharma;"
psql -U postgres -d dharma_cms -c "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";"
```

Set in `.env`:

```env
DATABASE_URL=postgresql+asyncpg://dharma:your_secure_password@localhost:5432/dharma_cms
```

### 3c. Production PostgreSQL

For production, use a managed PostgreSQL service (Cloud SQL, RDS, etc.):

```env
DATABASE_URL=postgresql+asyncpg://dharma_prod:STRONG_PASSWORD_HERE@db-host:5432/dharma_cms
```

**Requirements:**
- PostgreSQL 14+
- `uuid-ossp` extension enabled
- SSL connection recommended (`?ssl=require` suffix)
- Separate read-only user for analytics (optional)

### 3d. Secure Password Generation

Generate a strong database password:

```bash
# Option 1: Python
python -c "import secrets; print(secrets.token_urlsafe(32))"

# Option 2: OpenSSL
openssl rand -base64 32

# Option 3: /dev/urandom (Linux/Mac)
head -c 32 /dev/urandom | base64
```

**Rules:**
- Minimum 24 characters
- Mix of letters, numbers, symbols
- Different password for each environment (dev, staging, prod)
- Rotate at least every 90 days in production

---

## 4. SECRET_KEY

Used internally for CSRF protection and session signing. **Must be unique per environment.**

### Generate a Secret Key

```bash
python -c "import secrets; print(secrets.token_hex(32))"
```

Example output: `a3f8b2c1d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1`

Set in `.env`:

```env
SECRET_KEY=a3f8b2c1d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1
```

> ⚠️ **DO NOT** use the default placeholder value in production. The app will work, but it's insecure.

---

## 5. CORS Origins

Controls which frontend origins can make API requests.

### Development

```env
CORS_ORIGINS=["http://localhost:5555","http://localhost:8000","http://localhost:3000"]
```

- `http://localhost:5555` — Flutter web dev server
- `http://localhost:8000` — Swagger docs
- `http://localhost:3000` — Other dev tools

### Production

```env
CORS_ORIGINS=["https://dharma-cms.example.com","https://police.dharma-cms.example.com"]
```

**Rules:**
- Never use `["*"]` in production
- Include exact origins (with `https://` and no trailing slash)
- Include both citizen and police frontend origins

---

## 6. Allowed Hosts

Prevents HTTP Host header attacks. Only enforced in production (`APP_ENV=production`).

### Development

```env
ALLOWED_HOSTS=["*"]
```

### Production

```env
ALLOWED_HOSTS=["api.dharma-cms.example.com","dharma-cms-api-abc123.run.app"]
```

Include the exact hostnames that your backend serves.

---

## 7. AI Service URL

The backend proxies AI requests to the old backend (AI microservice).

```env
AI_SERVICE_URL=https://fastapi-app-335340524683.asia-south1.run.app
```

If you're running the AI service locally:

```env
AI_SERVICE_URL=http://localhost:8001
```

All proxied requests are at `/ai/*` endpoints. The backend adds auth validation before forwarding.

---

## 8. Upload Size Limit

Controls the maximum allowed request body size (in MB).

```env
MAX_UPLOAD_SIZE_MB=10
```

This applies to:
- All HTTP request bodies (middleware-level `Content-Length` check)
- Individual files uploaded to AI endpoints (per-file validation)

Increase if your users need to upload large documents:

```env
MAX_UPLOAD_SIZE_MB=25
```

---

## 9. Production Checklist

Before going to production, verify **every item**:

### 🔐 Secrets & Credentials

- [ ] `SECRET_KEY` — Generated unique value (not the default placeholder)
- [ ] `FIREBASE_CREDENTIALS` — Valid service account JSON, not committed to git
- [ ] `DATABASE_URL` — Strong password, SSL enabled, not default `dharma:dharma`
- [ ] `.env` file — Not committed to version control

### 🌐 Network & CORS

- [ ] `APP_ENV=production` — Enables HSTS, disables Swagger docs, enables trusted hosts
- [ ] `CORS_ORIGINS` — Set to exact frontend domains (not `["*"]`)
- [ ] `ALLOWED_HOSTS` — Set to exact API hostnames (not `["*"]`)
- [ ] `AI_SERVICE_URL` — Points to production AI service (not localhost)

### 🗄️ Database

- [ ] PostgreSQL 14+ with `uuid-ossp` extension
- [ ] Strong, unique password (not `dharma`)
- [ ] SSL connection (`?ssl=require` in DATABASE_URL)
- [ ] Alembic migrations used (not `create_all`)
- [ ] Regular backups configured

### 🐳 Docker

- [ ] Non-root user (already configured in Dockerfile: `appuser`)
- [ ] Firebase credential mounted as read-only volume
- [ ] No `.env` file baked into image (use runtime env vars)
- [ ] Health check configured (already in Dockerfile)

### 📊 Monitoring

- [ ] Structured logging enabled (loguru configured)
- [ ] Health endpoint monitored (`/api/health`)
- [ ] Error tracking service connected (Sentry, etc.)

---

## 10. Docker Compose Setup

For local development with PostgreSQL:

### Step 1: Create `.env`

```bash
cp .env.example .env
# Edit .env — the docker-compose.yml overrides DATABASE_URL automatically
```

### Step 2: Place Firebase Credentials

```bash
# Rename your downloaded service account JSON to:
cp ~/Downloads/dharma-cms-5cc89-xxxxxxxx.json ./firebase-credentials.json
```

### Step 3: Start

```bash
docker-compose up --build
```

This starts:
- **PostgreSQL 16** on port 5432 (user: `dharma`, password: `dharma`, db: `dharma_cms`)
- **FastAPI backend** on port 8000

### Step 4: Verify

```bash
# Health check
curl http://localhost:8000/api/health

# Swagger docs
open http://localhost:8000/docs

# Geography seed status
curl http://localhost:8000/police-hierarchy/seed/status
```

---

## 11. Cloud Run Deployment

### Build and Push

```bash
gcloud builds submit --tag gcr.io/PROJECT_ID/dharma-cms-api
```

### Deploy

```bash
gcloud run deploy dharma-cms-api \
  --image gcr.io/PROJECT_ID/dharma-cms-api \
  --platform managed \
  --region asia-south1 \
  --set-env-vars "APP_ENV=production" \
  --set-env-vars "DATABASE_URL=postgresql+asyncpg://user:pass@/dharma_cms?host=/cloudsql/PROJECT:REGION:INSTANCE" \
  --set-env-vars "AI_SERVICE_URL=https://your-ai-service.run.app" \
  --set-env-vars "SECRET_KEY=$(python -c 'import secrets; print(secrets.token_hex(32))')" \
  --set-env-vars 'CORS_ORIGINS=["https://dharma-cms.example.com"]' \
  --set-env-vars 'ALLOWED_HOSTS=["dharma-cms-api-abc.run.app"]' \
  --add-cloudsql-instances PROJECT:REGION:INSTANCE \
  --allow-unauthenticated
```

> **Firebase credentials:** On Cloud Run, leave `FIREBASE_CREDENTIALS` empty. The service automatically uses Application Default Credentials.

### Cloud SQL Setup

```bash
# Create instance
gcloud sql instances create dharma-cms-db \
  --database-version=POSTGRES_14 \
  --region=asia-south1 \
  --tier=db-f1-micro

# Create database
gcloud sql databases create dharma_cms --instance=dharma-cms-db

# Create user
gcloud sql users create dharma_prod \
  --instance=dharma-cms-db \
  --password="$(openssl rand -base64 32)"

# Enable uuid-ossp extension (connect via Cloud SQL proxy first)
psql -c "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";"
```

---

## 12. Environment Variable Reference

| Variable | Required | Default | Description |
|----------|:--------:|---------|-------------|
| `APP_ENV` | ❌ | `development` | `development` or `production` |
| `PORT` | ❌ | `8000` | Server port |
| `SECRET_KEY` | ✅ (prod) | *(placeholder)* | HMAC secret key — must change in production |
| `CORS_ORIGINS` | ❌ | `["http://localhost:5555", ...]` | Allowed CORS origins (JSON array) |
| `ALLOWED_HOSTS` | ❌ | `["*"]` | Trusted hostnames (production only) |
| `MAX_UPLOAD_SIZE_MB` | ❌ | `10` | Max request body size in MB |
| `DATABASE_URL` | ❌ | `sqlite+aiosqlite:///dev.db` | Async database connection string |
| `FIREBASE_CREDENTIALS` | ✅ (prod) | *(empty)* | Path to Firebase service account JSON |
| `AI_SERVICE_URL` | ❌ | *(old backend URL)* | AI microservice base URL |

---

## Troubleshooting

### "Firebase Admin SDK NOT initialised"

- Check that `FIREBASE_CREDENTIALS` points to a valid JSON file
- Verify the file is readable by the app user (not just root)
- On Cloud Run: ensure the service account has Firebase Admin role

### "Table already exists" errors

- Safe to ignore on startup — `create_all` is idempotent
- For production, use Alembic migrations instead

### CORS errors in browser

- Check `CORS_ORIGINS` includes the exact origin (including port)
- No trailing slash in origins
- Ensure `http` vs `https` matches

### "Request body too large" (413)

- Increase `MAX_UPLOAD_SIZE_MB` in `.env`
- Or compress the file before uploading

### Geography data not seeded

- Check `/police-hierarchy/seed/status` endpoint
- Ensure `data/ap_police_hierarchy.json` and `data/pincodes.json` exist
- Manual seed: `POST /police-hierarchy/seed` (requires Police role auth)

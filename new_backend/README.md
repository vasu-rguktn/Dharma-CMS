# Dharma CMS — FastAPI Backend v2

> **Auth-protected REST API** for the Dharma CMS citizen-police petition management system.  
> Firebase for authentication only • PostgreSQL (prod) / SQLite (local dev) for all data • AI service proxy built in.

---

## Table of Contents

- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Database ERD](#database-erd)
- [Project Structure](#project-structure)
- [Quick Start](#quick-start)
  - [Prerequisites](#prerequisites)
  - [Local Development](#local-development)
  - [Docker Compose (recommended)](#docker-compose-recommended)
- [Environment Variables](#environment-variables)
- [Authentication & Authorization](#authentication--authorization)
- [API Reference](#api-reference)
  - [Health](#health)
  - [Accounts](#accounts)
  - [Citizen Profiles](#citizen-profiles)
  - [Police Profiles](#police-profiles)
  - [Device Tokens](#device-tokens)
  - [Petitions](#petitions)
  - [Petition Assignments](#petition-assignments)
  - [Petition Attachments](#petition-attachments)
  - [Petition Updates](#petition-updates)
  - [Petition Saves](#petition-saves)
  - [Cases](#cases)
  - [Case People](#case-people)
  - [Case Officers](#case-officers)
  - [Case Crime Details](#case-crime-details)
  - [Case Journal Entries](#case-journal-entries)
  - [Case Documents](#case-documents)
  - [Complaint Drafts](#complaint-drafts)
  - [Complaint Draft Messages](#complaint-draft-messages)
  - [Legal Query Threads](#legal-query-threads)
  - [Legal Query Messages](#legal-query-messages)
  - [Prompt Templates](#prompt-templates)
  - [Police Hierarchy](#police-hierarchy)
  - [AI Gateway](#ai-gateway)
- [Database Migrations (Alembic)](#database-migrations-alembic)
- [Deployment](#deployment)

---

## Architecture

```
┌────────────────┐        ┌────────────────────────┐        ┌─────────────────┐
│  Flutter App   │──────▶ │  new_backend (FastAPI)  │──────▶ │  AI Service     │
│  (citizen /    │  HTTP  │  • Firebase Auth verify │  HTTP  │  (old backend)  │
│   police UI)   │  +JWT  │  • DB CRUD (PG/SQLite)  │  proxy │  • Gemini / LLM │
│                │        │  • AI Gateway proxy     │        │  • OCR, PDF gen │
│                │        │  • Police Hierarchy API │        │                 │
└────────────────┘        └───────────┬────────────┘        └─────────────────┘
                                      │
                                      ▼
                            ┌──────────────────┐                            │  PostgreSQL 14+   │  (production)
                            │  or SQLite        │  (local dev)
                            │  27 tables, UUID  │
                            │  PKs, JSON(B)     │
                            └──────────────────┘
```

**Key design decisions:**
- **Firebase** is used **ONLY** for login (phone OTP, Google Sign-In) and token verification. Zero Firestore usage.
- **PostgreSQL** stores ALL application data in production. **SQLite** is the zero-install local dev fallback (auto-detected from `DATABASE_URL`).
- **Portable column types** (`GUID`, `JSON_DICT`, `StringList`) in `app/core/column_types.py` ensure the same ORM models work on both databases.
- **AI Gateway** proxies requests to the existing AI microservice, keeping AI logic decoupled.
- **Police Hierarchy** serves AP district→SDPO→circle→station + pincode data from **database tables** (auto-seeded from JSON on first startup).
- Every API request (except health checks and hierarchy lookups) requires a valid `Authorization: Bearer <firebase_id_token>` header.

---

## Tech Stack

| Component | Technology |
|-----------|------------|
| Framework | FastAPI 0.110+ |
| Runtime | Python 3.11+ |
| Database (prod) | PostgreSQL 14+ with `uuid-ossp` extension |
| Database (dev) | SQLite via aiosqlite (zero-install) |
| ORM | SQLAlchemy 2.0 (async, via `asyncpg` / `aiosqlite`) |
| Migrations | Alembic |
| Auth | Firebase Admin SDK (token verification only) |
| HTTP Client | httpx (AI gateway proxy) |
| Validation | Pydantic v2 |
| Server | Uvicorn (ASGI) |

---

## Database ERD

```
ACCOUNTS
 ├── CITIZEN_PROFILES           (1:1)
 ├── POLICE_PROFILES            (1:1)
 ├── DEVICE_TOKENS              (1:N)
 ├── PETITIONS                  (1:N, via created_by_account_id)
 │    ├── PETITION_ASSIGNMENTS  (1:N)
 │    ├── PETITION_ATTACHMENTS  (1:N)
 │    ├── PETITION_UPDATES      (1:N)
 │    │    └── PETITION_UPDATE_ATTACHMENTS  (1:N)
 │    └── PETITION_SAVES        (N:M bookmark)
 │
 ├── CASES                      (via petition_id FK)
 │    ├── CASE_PEOPLE           (1:N)
 │    ├── CASE_OFFICERS         (1:N)
 │    ├── CASE_CRIME_DETAILS    (1:1)
 │    ├── CASE_JOURNAL_ENTRIES  (1:N)
 │    │    └── CASE_JOURNAL_ATTACHMENTS  (1:N)
 │    └── CASE_DOCUMENTS        (1:N)
 │
 ├── COMPLAINT_DRAFTS           (1:N)
 │    └── COMPLAINT_DRAFT_MESSAGES  (1:N)
 │
 └── LEGAL_QUERY_THREADS        (1:N)      └── LEGAL_QUERY_MESSAGES  (1:N)

PROMPT_TEMPLATES (standalone)

DISTRICTS
 ├── SDPOS                       (1:N)
 │    └── CIRCLES                (1:N)
 │         └── POLICE_STATIONS   (1:N)
 └── PINCODES                    (1:N)
```

**27 tables total.** All use UUID primary keys and UTC timestamps (`created_at`, `updated_at`).  
JSON(B) columns in `complaint_drafts` (`answers_json`, `state_json`) for flexible AI workflow state.  
Geography tables (districts→stations, pincodes) are **auto-seeded from JSON** on first startup if empty.

Full SQL DDL: [`docs/postgresql_schema.sql`](docs/postgresql_schema.sql)

---

## Project Structure

```
new_backend/
├── main.py                          # FastAPI app, lifespan, router registration
├── requirements.txt                 # Python dependencies
├── Dockerfile                       # Production container image
├── docker-compose.yml               # PostgreSQL + API (local dev)
├── .env.example                     # Template for environment variables
├── .gitignore
├── data/
│   ├── ap_police_hierarchy.json     # AP police district→SDPO→circle→station (seed source)
│   └── pincodes.json                # AP district→pincode mappings (seed source)
├── docs/
│   └── postgresql_schema.sql        # Complete DDL (27 tables, indexes)
└── app/
    ├── __init__.py
    ├── core/
    │   ├── config.py                # Pydantic settings (DATABASE_URL, etc.)
    │   ├── database.py              # Async SQLAlchemy engine, session, Base
    │   ├── column_types.py          # Portable types: GUID, JSON_DICT, StringList
    │   ├── firebase.py              # Firebase Admin SDK init (auth only)
    │   └── auth.py                  # Token verification, CurrentUser, role guards
    ├── models/                      # SQLAlchemy ORM models (1 file per domain)
    │   ├── __init__.py              # Imports all models for table auto-creation
    │   ├── accounts.py              # Account, CitizenProfile, PoliceProfile, DeviceToken
    │   ├── petitions.py             # Petition + 5 sub-tables
    │   ├── cases.py                 # Case + 6 sub-tables
    │   ├── complaint_drafts.py      # ComplaintDraft, ComplaintDraftMessage    │   ├── legal_queries.py         # LegalQueryThread, LegalQueryMessage
    │   ├── prompt_templates.py      # PromptTemplate
    │   └── geography.py             # District, SDPO, Circle, PoliceStation, Pincode
    ├── schemas/                     # Pydantic request/response schemas
    │   ├── __init__.py
    │   ├── common.py                # TimestampMixin, IDResponse, MessageResponse
    │   ├── accounts.py
    │   ├── petitions.py
    │   ├── cases.py
    │   ├── complaint_drafts.py    │   ├── legal_queries.py
    │   ├── prompt_templates.py
    │   └── geography.py             # District/SDPO/Circle/Station/Pincode schemas
    ├── services/
    │   ├── __init__.py
    │   └── crud.py                  # Generic async CRUD helpers (works with PG + SQLite)
    └── routers/                     # FastAPI route handlers
        ├── __init__.py
        ├── accounts.py              # /accounts/**
        ├── petitions.py             # /petitions/**
        ├── cases.py                 # /cases/**
        ├── complaint_drafts.py      # /complaint-drafts/**
        ├── legal_queries.py         # /legal-threads/**
        ├── prompt_templates.py      # /prompt-templates/**        ├── police_hierarchy.py      # /police-hierarchy/** (DB-backed, full CRUD + seed)
        └── ai_gateway.py           # /ai/** (proxy to AI service)
```

---

## Quick Start

### Prerequisites

- **Python 3.11+**
- **PostgreSQL 14+** *(production only — local dev uses SQLite automatically)*
- **Firebase service account JSON** *(for token verification — optional for initial dev)*

### Local Development (SQLite — zero install)

```bash
# 1. Clone and navigate
cd new_backend

# 2. Create virtual environment
python -m venv venv
source venv/bin/activate          # Linux/Mac
# venv\Scripts\activate           # Windows

# 3. Install dependencies
pip install -r requirements.txt

# 4. Run (uses SQLite by default — no PostgreSQL needed!)
uvicorn main:app --reload --port 8000

# 5. Open Swagger docs
#    http://localhost:8000/docs
```

> **Note:** The default `DATABASE_URL` in `config.py` points to `sqlite+aiosqlite:///dev.db`.
> A `dev.db` file is auto-created on first startup with all 27 tables.
> Geography data (26 districts, 113 SDPOs, 326 circles, 958 stations, 1418 pincodes) is **auto-seeded** on first startup.
> To use PostgreSQL instead, set `DATABASE_URL` in your `.env` file.
### Local Development with PostgreSQL

If you prefer PostgreSQL locally:

```bash
# Create database and user
psql -U postgres -c "CREATE USER dharma WITH PASSWORD 'dharma';"
psql -U postgres -c "CREATE DATABASE dharma_cms OWNER dharma;"
psql -U postgres -d dharma_cms -c "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";"

# Set DATABASE_URL in .env
cp .env.example .env
# Edit .env: DATABASE_URL=postgresql+asyncpg://dharma:dharma@localhost:5432/dharma_cms

# Place Firebase service account JSON (optional for initial dev)
# Download from Firebase Console → Project Settings → Service Accounts

# Start the server
uvicorn main:app --reload --port 8000
```

Tables are **auto-created on startup** in development mode via SQLAlchemy's `Base.metadata.create_all`.

### Docker Compose (recommended for PostgreSQL)

```bash
# Starts PostgreSQL + API together
docker-compose up --build

# API: http://localhost:8000
# Swagger: http://localhost:8000/docs
# PostgreSQL: localhost:5432 (user: dharma, password: dharma, db: dharma_cms)
```

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `APP_ENV` | `development` | Environment (`development` \| `production`) |
| `PORT` | `8000` | Server port |
| `SECRET_KEY` | *(placeholder)* | HMAC secret — **change in production** (`python -c "import secrets; print(secrets.token_hex(32))"`) |
| `CORS_ORIGINS` | `["http://localhost:5555", "http://localhost:8000"]` | Allowed CORS origins (JSON list) |
| `ALLOWED_HOSTS` | `["*"]` | Trusted hostnames — restrict in production (e.g. `["api.dharma-cms.example.com"]`) |
| `MAX_UPLOAD_SIZE_MB` | `10` | Max request body size (MB) — rejects larger uploads with HTTP 413 |
| `DATABASE_URL` | `sqlite+aiosqlite:///dev.db` | Database connection string (`postgresql+asyncpg://...` for prod) |
| `FIREBASE_CREDENTIALS` | *(empty)* | Path to Firebase service account JSON — empty = Application Default Credentials |
| `AI_SERVICE_URL` | `https://fastapi-app-335340524683.asia-south1.run.app` | AI microservice base URL |

Create a `.env` file in the project root (see `.env.example`).

> **🔒 Security:** See [`CONFIGURATION_GUIDE.md`](CONFIGURATION_GUIDE.md) for detailed setup instructions, secure password generation, and production hardening steps.

---

## Authentication & Authorization

### Token verification

Every endpoint (except `GET /` and `GET /api/health`) requires:

```
Authorization: Bearer <firebase_id_token>
```

The server decodes and verifies the token using Firebase Admin SDK. No Firestore lookups are performed.

### Role-based access

| Dependency | Who can access | How to use in code |
|------------|----------------|---------------------|
| `AuthUser` | Any authenticated user | `user: AuthUser` |
| `PoliceUser` | Users with `role == "police"` in Firebase custom claims | `user: PoliceUser` |

Role is read from the Firebase token's custom claims (`role` field).

### Access control matrix

| Resource | Citizen | Police |
|----------|---------|--------|
| Own account & profiles | ✅ Full CRUD | ✅ Full CRUD |
| Other accounts | ❌ | ✅ Read |
| Own petitions | ✅ Full CRUD | ✅ Full CRUD |
| All petitions (`/petitions/all`) | ❌ | ✅ Read |
| Cases | ✅ Read own (via petition) | ✅ Full CRUD |
| Complaint drafts | ✅ Own only | ❌ |
| Legal threads | ✅ Own only | ✅ Own only |
| Prompt templates | ✅ Read | ✅ Full CRUD |
| AI Gateway | ✅ | ✅ |

---

## API Reference

Interactive Swagger docs at **`http://localhost:8000/docs`** once the server is running.

### Health

| Method | Path | Auth | Description |
|--------|------|:----:|-------------|
| `GET` | `/` | ❌ | Root — returns version info |
| `GET` | `/api/health` | ❌ | Health check — returns status + AI service URL |

### Accounts

| Method | Path | Auth | Description |
|--------|------|:----:|-------------|
| `POST` | `/accounts` | AuthUser | Create account (idempotent — returns existing if found) |
| `GET` | `/accounts/me` | AuthUser | Get own account |
| `PATCH` | `/accounts/me` | AuthUser | Update own account |
| `GET` | `/accounts/{id}` | Police | Get any account by ID |
| `GET` | `/accounts` | Police | List all accounts (paginated) |

### Citizen Profiles

| Method | Path | Auth | Description |
|--------|------|:----:|-------------|
| `POST` | `/accounts/me/citizen-profile` | AuthUser | Create citizen profile (idempotent) |
| `GET` | `/accounts/me/citizen-profile` | AuthUser | Get own citizen profile |
| `PATCH` | `/accounts/me/citizen-profile` | AuthUser | Update own citizen profile |
| `GET` | `/accounts/{id}/citizen-profile` | Police | Get any citizen's profile |

### Police Profiles

| Method | Path | Auth | Description |
|--------|------|:----:|-------------|
| `POST` | `/accounts/me/police-profile` | AuthUser | Create police profile (idempotent) |
| `GET` | `/accounts/me/police-profile` | AuthUser | Get own police profile |
| `PATCH` | `/accounts/me/police-profile` | AuthUser | Update own police profile |
| `GET` | `/accounts/{id}/police-profile` | Police | Get any police profile |
| `GET` | `/accounts/police-profiles/all` | Police | List all police profiles |

### Device Tokens

| Method | Path | Auth | Description |
|--------|------|:----:|-------------|
| `POST` | `/accounts/me/device-tokens` | AuthUser | Register FCM device token |
| `GET` | `/accounts/me/device-tokens` | AuthUser | List own device tokens |
| `DELETE` | `/accounts/me/device-tokens/{id}` | AuthUser | Delete a device token |

### Petitions

| Method | Path | Auth | Description |
|--------|------|:----:|-------------|
| `POST` | `/petitions` | AuthUser | Create a new petition |
| `GET` | `/petitions` | AuthUser | List own petitions (filterable by `status_filter`) |
| `GET` | `/petitions/all` | Police | List ALL petitions (paginated, filterable) |
| `GET` | `/petitions/stats` | AuthUser | Get petition count stats (total, submitted, in_progress, resolved) |
| `GET` | `/petitions/{id}` | Owner/Police | Get petition detail |
| `PATCH` | `/petitions/{id}` | Owner/Police | Update petition |
| `DELETE` | `/petitions/{id}` | Owner/Police | Delete petition |

### Petition Assignments

| Method | Path | Auth | Description |
|--------|------|:----:|-------------|
| `POST` | `/petitions/{id}/assignments` | Police | Assign petition to an officer/station |
| `GET` | `/petitions/{id}/assignments` | AuthUser | List assignments for a petition |
| `DELETE` | `/petitions/{id}/assignments/{aid}` | Police | Remove an assignment |

### Petition Attachments

| Method | Path | Auth | Description |
|--------|------|:----:|-------------|
| `POST` | `/petitions/{id}/attachments` | AuthUser | Add attachment metadata to petition |
| `GET` | `/petitions/{id}/attachments` | AuthUser | List attachments for a petition |
| `DELETE` | `/petitions/{id}/attachments/{aid}` | AuthUser | Remove an attachment |

### Petition Updates

| Method | Path | Auth | Description |
|--------|------|:----:|-------------|
| `POST` | `/petitions/{id}/updates` | AuthUser | Add a status update to petition |
| `GET` | `/petitions/{id}/updates` | AuthUser | List updates for a petition |
| `POST` | `/petitions/{id}/updates/{uid}/attachments` | AuthUser | Add attachment to an update |
| `GET` | `/petitions/{id}/updates/{uid}/attachments` | AuthUser | List attachments for an update |

### Petition Saves

| Method | Path | Auth | Description |
|--------|------|:----:|-------------|
| `POST` | `/petition-saves` | AuthUser | Bookmark a petition |
| `GET` | `/petition-saves` | AuthUser | List bookmarked petitions |
| `DELETE` | `/petition-saves/{id}` | AuthUser | Remove bookmark |

### Cases

| Method | Path | Auth | Description |
|--------|------|:----:|-------------|
| `POST` | `/cases` | Police | Create a new case |
| `GET` | `/cases` | Police | List all cases (paginated, filterable by `status_filter`) |
| `GET` | `/cases/{id}` | AuthUser | Get case detail |
| `PATCH` | `/cases/{id}` | Police | Update case |
| `DELETE` | `/cases/{id}` | Police | Delete case |

### Case People

| Method | Path | Auth | Description |
|--------|------|:----:|-------------|
| `POST` | `/cases/{id}/people` | Police | Add person to case |
| `GET` | `/cases/{id}/people` | AuthUser | List people in a case |
| `PATCH` | `/cases/{id}/people/{pid}` | Police | Update person details |
| `DELETE` | `/cases/{id}/people/{pid}` | Police | Remove person from case |

### Case Officers

| Method | Path | Auth | Description |
|--------|------|:----:|-------------|
| `POST` | `/cases/{id}/officers` | Police | Assign officer to case |
| `GET` | `/cases/{id}/officers` | AuthUser | List officers on a case |
| `PATCH` | `/cases/{id}/officers/{oid}` | Police | Update officer assignment |
| `DELETE` | `/cases/{id}/officers/{oid}` | Police | Remove officer from case |

### Case Crime Details

| Method | Path | Auth | Description |
|--------|------|:----:|-------------|
| `POST` | `/cases/{id}/crime-details` | Police | Add crime details (1:1 with case) |
| `GET` | `/cases/{id}/crime-details` | AuthUser | Get crime details for a case |
| `PATCH` | `/cases/{id}/crime-details/{did}` | Police | Update crime details |
| `DELETE` | `/cases/{id}/crime-details/{did}` | Police | Delete crime details |

### Case Journal Entries

| Method | Path | Auth | Description |
|--------|------|:----:|-------------|
| `POST` | `/cases/{id}/journal` | Police | Add journal entry |
| `GET` | `/cases/{id}/journal` | AuthUser | List journal entries |
| `PATCH` | `/cases/{id}/journal/{eid}` | Police | Update journal entry |
| `DELETE` | `/cases/{id}/journal/{eid}` | Police | Delete journal entry |
| `POST` | `/cases/{id}/journal/{eid}/attachments` | Police | Add attachment to journal entry |
| `GET` | `/cases/{id}/journal/{eid}/attachments` | AuthUser | List journal entry attachments |
| `DELETE` | `/cases/{id}/journal/{eid}/attachments/{aid}` | Police | Delete journal attachment |

### Case Documents

| Method | Path | Auth | Description |
|--------|------|:----:|-------------|
| `POST` | `/cases/{id}/documents` | Police | Upload case document metadata |
| `GET` | `/cases/{id}/documents` | AuthUser | List case documents |
| `PATCH` | `/cases/{id}/documents/{did}` | Police | Update document metadata |
| `DELETE` | `/cases/{id}/documents/{did}` | Police | Delete case document |

### Complaint Drafts

| Method | Path | Auth | Description |
|--------|------|:----:|-------------|
| `POST` | `/complaint-drafts` | AuthUser | Start a new AI-assisted complaint draft |
| `GET` | `/complaint-drafts` | AuthUser | List own drafts |
| `GET` | `/complaint-drafts/{id}` | Owner | Get draft detail |
| `PATCH` | `/complaint-drafts/{id}` | Owner | Update draft (status, answers, generated complaint) |
| `DELETE` | `/complaint-drafts/{id}` | Owner | Delete draft |

### Complaint Draft Messages

| Method | Path | Auth | Description |
|--------|------|:----:|-------------|
| `POST` | `/complaint-drafts/{id}/messages` | Owner | Add message to draft conversation |
| `GET` | `/complaint-drafts/{id}/messages` | Owner | List messages (chronological order) |
| `DELETE` | `/complaint-drafts/{id}/messages/{mid}` | Owner | Delete a message |

### Legal Query Threads

| Method | Path | Auth | Description |
|--------|------|:----:|-------------|
| `POST` | `/legal-threads` | AuthUser | Create a new legal research thread |
| `GET` | `/legal-threads` | AuthUser | List own threads |
| `GET` | `/legal-threads/{id}` | Owner | Get thread detail |
| `PATCH` | `/legal-threads/{id}` | Owner | Update thread (title, status) |
| `DELETE` | `/legal-threads/{id}` | Owner | Delete thread |

### Legal Query Messages

| Method | Path | Auth | Description |
|--------|------|:----:|-------------|
| `POST` | `/legal-threads/{id}/messages` | Owner | Add message to thread |
| `GET` | `/legal-threads/{id}/messages` | Owner | List messages (chronological order) |
| `DELETE` | `/legal-threads/{id}/messages/{mid}` | Owner | Delete a message |

### Prompt Templates

| Method | Path | Auth | Description |
|--------|------|:----:|-------------|
| `POST` | `/prompt-templates` | Police | Create a new prompt template |
| `GET` | `/prompt-templates` | AuthUser | List all active templates |
| `GET` | `/prompt-templates/{id}` | AuthUser | Get template detail |
| `PATCH` | `/prompt-templates/{id}` | Police | Update template |
| `DELETE` | `/prompt-templates/{id}` | Police | Delete template |

### Police Hierarchy

AP police geography data stored in **database tables** (districts, SDPOs, circles, stations, pincodes).  
Auto-seeded from JSON on first startup. Lookup endpoints are **public** (no auth). CRUD writes require **Police** role.

| Method | Path | Auth | Description |
|--------|------|:----:|-------------|
| `GET` | `/police-hierarchy/full` | ❌ | Full district→SDPO→circle→station tree |
| `GET` | `/police-hierarchy/districts` | ❌ | List all districts |
| `GET` | `/police-hierarchy/districts/names` | ❌ | Flat list of district names (for dropdowns) |
| `GET` | `/police-hierarchy/sdpos?district=...` | ❌ | SDPOs for a district |
| `GET` | `/police-hierarchy/circles?district=...&sdpo=...` | ❌ | Circles for a district+SDPO |
| `GET` | `/police-hierarchy/stations?district=...&sdpo=...&circle=...` | ❌ | Stations for a circle |
| `GET` | `/police-hierarchy/pincodes?district=...` | ❌ | Pincodes for a district |
| `GET` | `/police-hierarchy/search?q=...` | ❌ | Search across all levels |
| `GET` | `/police-hierarchy/seed/status` | ❌ | Check seed counts per table |
| `POST` | `/police-hierarchy/seed` | Police | Seed data from JSON files (idempotent) |
| `POST` | `/police-hierarchy/districts` | Police | Create a district |
| `GET` | `/police-hierarchy/districts/{id}` | ❌ | Get district with full hierarchy |
| `PATCH` | `/police-hierarchy/districts/{id}` | Police | Update a district |
| `DELETE` | `/police-hierarchy/districts/{id}` | Police | Delete district + all children |
| `POST` | `/police-hierarchy/districts/{id}/sdpos` | Police | Create SDPO under district |
| `GET` | `/police-hierarchy/districts/{id}/sdpos` | ❌ | List SDPOs by district ID |
| `PATCH` | `/police-hierarchy/sdpos/{id}` | Police | Update SDPO |
| `DELETE` | `/police-hierarchy/sdpos/{id}` | Police | Delete SDPO + children |
| `POST` | `/police-hierarchy/sdpos/{id}/circles` | Police | Create circle under SDPO |
| `GET` | `/police-hierarchy/sdpos/{id}/circles` | ❌ | List circles by SDPO ID |
| `PATCH` | `/police-hierarchy/circles/{id}` | Police | Update circle |
| `DELETE` | `/police-hierarchy/circles/{id}` | Police | Delete circle + stations |
| `POST` | `/police-hierarchy/circles/{id}/stations` | Police | Create station under circle |
| `GET` | `/police-hierarchy/circles/{id}/stations` | ❌ | List stations by circle ID |
| `PATCH` | `/police-hierarchy/stations/{id}` | Police | Update station |
| `DELETE` | `/police-hierarchy/stations/{id}` | Police | Delete station |
| `POST` | `/police-hierarchy/districts/{id}/pincodes` | Police | Add pincode to district |
| `GET` | `/police-hierarchy/districts/{id}/pincodes` | ❌ | List pincodes by district ID |
| `DELETE` | `/police-hierarchy/pincodes/{id}` | Police | Delete pincode |

### AI Gateway

All AI endpoints are proxied to the AI microservice. The backend validates the Firebase token and forwards the request.

| Method | Path | Auth | Description |
|--------|------|:----:|-------------|
| `POST` | `/ai/complaint/chat-step` | AuthUser | AI complaint chatbot — one conversation step |
| `POST` | `/ai/legal-chat` | AuthUser | AI legal research chat |
| `POST` | `/ai/legal-suggestions` | AuthUser | AI legal suggestions |
| `POST` | `/ai/ocr/extract` | AuthUser | OCR text extraction from uploaded file |
| `GET` | `/ai/ocr/health` | AuthUser | OCR service health check |
| `POST` | `/ai/generate-chatbot-summary-pdf` | AuthUser | Generate PDF summary from chatbot session |
| `POST` | `/ai/witness-preparation` | AuthUser | AI witness preparation assistance |
| `POST` | `/ai/fcm/register` | AuthUser | Register FCM token with AI service |
| `POST` | `/ai/fcm/unregister` | AuthUser | Unregister FCM token from AI service |

---

## Database Migrations (Alembic)

For **production**, use Alembic instead of auto-create:

```bash
# Initialize Alembic (one-time)
alembic init alembic

# Edit alembic.ini — set sqlalchemy.url
# Edit alembic/env.py — import your models and set target_metadata = Base.metadata

# Generate migration from current models
alembic revision --autogenerate -m "initial schema"

# Apply migration
alembic upgrade head
```

In **development**, tables are auto-created on startup via `Base.metadata.create_all` in the `lifespan` handler.

---

## Security

The backend has security hardening applied at every layer. See [`CONFIGURATION_GUIDE.md`](CONFIGURATION_GUIDE.md) for full setup instructions.

### Summary

| Layer | Protection |
|-------|------------|
| **Authentication** | Firebase token verified on every request, `check_revoked=True`, `WWW-Authenticate: Bearer` headers (RFC 6750) |
| **Authorization** | Role-based guards (citizen/police), ownership verification on all sub-resource endpoints |
| **CORS** | Restricted to configured `CORS_ORIGINS` list (not `*` in production) |
| **Security headers** | `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `X-XSS-Protection`, `Referrer-Policy`, `Permissions-Policy`, HSTS (production only) |
| **Request limits** | `MAX_UPLOAD_SIZE_MB` body size limit + per-file validation on AI upload endpoints |
| **Error masking** | AI gateway proxied errors do not expose internal exception details |
| **Swagger docs** | Disabled in production (`docs_url=None`, `redoc_url=None`, `openapi_url=None`) |
| **Health endpoint** | Does not leak internal AI service URLs |
| **Docker** | Non-root `appuser` in container, no unnecessary packages |
| **Trusted hosts** | `TrustedHostMiddleware` in production (if `ALLOWED_HOSTS ≠ ["*"]`) |

---

## Deployment

### Docker

```bash
# Build image
docker build -t dharma-cms-api .

# Run (mount Firebase credentials)
docker run -p 8000:8000 \
  -e DATABASE_URL="postgresql+asyncpg://user:pass@db-host:5432/dharma_cms" \
  -e FIREBASE_CREDENTIALS="service-account.json" \
  -e AI_SERVICE_URL="https://your-ai-service.run.app" \
  -v /path/to/service-account.json:/app/service-account.json \
  dharma-cms-api
```

### Google Cloud Run

```bash
# Build and push
gcloud builds submit --tag gcr.io/PROJECT_ID/dharma-cms-api

# Deploy
gcloud run deploy dharma-cms-api \
  --image gcr.io/PROJECT_ID/dharma-cms-api \
  --platform managed \
  --region asia-south1 \
  --set-env-vars DATABASE_URL="...",AI_SERVICE_URL="..." \
  --allow-unauthenticated
```

Ensure your Cloud SQL PostgreSQL instance is accessible from Cloud Run (via VPC connector or Cloud SQL Auth Proxy).

---

## License

Proprietary — Dharma CMS Project.

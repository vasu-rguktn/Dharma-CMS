"""
Dharma CMS — New FastAPI Backend
==================================
Every endpoint requires a valid Firebase ID token in the Authorization header.
Data stored in PostgreSQL (prod) or SQLite (local dev).
Firebase used only for auth token verification.

SECURITY:
  - CORS restricted to configured origins (not * in production)
  - Security headers on every response (HSTS, nosniff, etc.)
  - Request size limit (configurable MAX_UPLOAD_SIZE_MB)
  - Swagger docs disabled in production
  - Health endpoint does not leak internal URLs
"""

from contextlib import asynccontextmanager
import logging
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.core.config import settings
from app.core.database import engine, Base, _is_sqlite
from app.core.security import register_security_middleware

# Import ALL models so SQLAlchemy knows about them
import app.models  # noqa: F401

# Import routers
from app.routers.accounts import router as accounts_router
from app.routers.petitions import router as petitions_router
from app.routers.cases import router as cases_router
from app.routers.complaint_drafts import router as complaint_drafts_router
from app.routers.legal_queries import router as legal_queries_router
from app.routers.prompt_templates import router as prompt_templates_router
from app.routers.ai_gateway import router as ai_gateway_router
from app.routers.police_hierarchy import router as hierarchy_router

_db_label = "SQLite (local dev)" if _is_sqlite else "PostgreSQL"


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Create tables on startup (dev only). Use Alembic migrations in production."""
    if _is_sqlite:
        from sqlalchemy import event
        @event.listens_for(engine.sync_engine, "connect")
        def _set_sqlite_pragma(dbapi_conn, _):
            cursor = dbapi_conn.cursor()
            cursor.execute("PRAGMA journal_mode=WAL")
            cursor.execute("PRAGMA foreign_keys=ON")
            cursor.close()

    # Create all tables
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    print(f"✅ {_db_label} tables verified / created")

    # Auto-seed geography data if tables are empty
    await _auto_seed_geography()

    yield

    # Cleanup: close DB engine + AI gateway http client
    await engine.dispose()
    from app.routers.ai_gateway import shutdown_client
    await shutdown_client()


async def _auto_seed_geography():
    """Seed districts, SDPOs, circles, stations, and pincodes if the DB is empty."""
    from sqlalchemy import select, func
    from app.core.database import async_session_factory
    from app.models.geography import District
    from app.routers.police_hierarchy import _do_seed

    async with async_session_factory() as session:
        count = (await session.execute(select(func.count()).select_from(District))).scalar_one()
        if count > 0:
            print(f"ℹ️  Geography data already present ({count} districts) — skipping seed")
            return

        print("🌱 Seeding geography data from JSON files …")
        try:
            result = await _do_seed(session)
            await session.commit()
            print(
                f"✅ Seeded: {result.districts} districts, {result.sdpos} SDPOs, "
                f"{result.circles} circles, {result.police_stations} stations, "
                f"{result.pincodes} pincodes"
            )
        except Exception as e:
            await session.rollback()
            print(f"⚠️  Geography seed failed: {e}")


# ── Swagger docs disabled in production ──
_docs_kwargs = {}
if settings.is_production:
    _docs_kwargs = {"docs_url": None, "redoc_url": None, "openapi_url": None}

app = FastAPI(
    title="Dharma CMS API",
    description=(
        "Backend API for Dharma CMS.\n\n"
        "- **Auth:** Firebase ID token (`Authorization: Bearer <token>`)\n"
        f"- **Data:** {_db_label} (UUID primary keys, JSON for drafts)\n"
        "- **AI:** Proxied to AI micro-service via `/ai/*` endpoints\n\n"
        "## Modules\n"
        "| Module | Description |\n"
        "|--------|-------------|\n"
        "| Accounts | User identity, citizen/police profiles, device tokens |\n"
        "| Petitions | Citizen petitions, assignments, attachments, updates, saves |\n"
        "| Cases | Police case management, people, officers, crime details, journal, documents |\n"
        "| Complaint Drafts | AI-assisted complaint drafting sessions + messages |\n"
        "| Legal Queries | Legal research chat threads + messages |\n"
        "| Prompt Templates | System prompt registry for AI features |\n"
        "| Police Hierarchy | AP district → SDPO → circle → station + pincode (dynamic, DB-backed) |\n"
        "| AI Gateway | Proxy to AI service (complaint chat, legal chat, OCR, PDF, etc.) |\n\n"
        "Geography data is auto-seeded from JSON on first startup."
    ),
    version="2.0.0",
    lifespan=lifespan,
    redirect_slashes=False,
    **_docs_kwargs,
)

# ── Security middleware (headers, size limit, trusted hosts) ─────────────
register_security_middleware(app)

# ── CORS — restricted origins, NOT "*" in production ─────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type", "Accept"],
    expose_headers=["X-Request-Id"],
    max_age=600,
)

# ── Register routers ────────────────────────────────────────────────────
app.include_router(accounts_router)
app.include_router(petitions_router)
app.include_router(cases_router)
app.include_router(complaint_drafts_router)
app.include_router(legal_queries_router)
app.include_router(prompt_templates_router)
app.include_router(hierarchy_router)
app.include_router(ai_gateway_router)

# ── Global unhandled exception handler — logs + returns JSON 500 ─────────
_logger = logging.getLogger("dharma_cms")

@app.exception_handler(Exception)
async def _global_exception_handler(request: Request, exc: Exception):
    _logger.exception("Unhandled error on %s %s", request.method, request.url.path)
    return JSONResponse(
        status_code=500,
        content={"detail": f"Internal server error: {type(exc).__name__}: {exc}"},
    )


# ── Public health / root endpoints (no auth) ────────────────────────────

@app.get("/", tags=["Health"])
def root():
    return {"message": "Dharma CMS API v2 running", "database": _db_label}


@app.get("/api/health", tags=["Health"])
def health():
    """Health check — does NOT leak internal service URLs."""
    return {"status": "ok", "database": _db_label}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)

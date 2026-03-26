"""
Async SQLAlchemy engine, session factory, and base model.

Supports both PostgreSQL (asyncpg) and SQLite (aiosqlite).
The DATABASE_URL in settings determines which driver is used.

Usage:
    from app.core.database import get_session, Base

    async def my_endpoint(session: AsyncSession = Depends(get_session)):
        ...
"""

from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import DeclarativeBase

from app.core.config import settings

_is_sqlite = settings.DATABASE_URL.startswith("sqlite")

# ── Engine kwargs differ between dialects ──
_engine_kwargs: dict = {
    "echo": settings.APP_ENV == "development",
}

if _is_sqlite:
    # SQLite does not support pool_size / pool_pre_ping in the same way
    _engine_kwargs["connect_args"] = {"check_same_thread": False}
else:
    _engine_kwargs.update(
        pool_size=20,
        max_overflow=10,
        pool_pre_ping=True,
    )

engine = create_async_engine(settings.DATABASE_URL, **_engine_kwargs)

async_session_factory = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


class Base(DeclarativeBase):
    """Declarative base for all ORM models."""
    pass


async def get_session():
    """FastAPI dependency — yields one session per request, auto‑closes."""
    async with async_session_factory() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()

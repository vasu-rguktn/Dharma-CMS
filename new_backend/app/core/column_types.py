"""
Portable SQLAlchemy column types that work on both PostgreSQL and SQLite.

- GUID       → PostgreSQL UUID / SQLite CHAR(32)
- JSON_DICT  → PostgreSQL JSONB / SQLite JSON (text)
- StringList → PostgreSQL ARRAY(String) / SQLite JSON (text)

Usage in models:
    from app.core.column_types import GUID, JSON_DICT, StringList
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    data = Column(JSON_DICT, nullable=True)
    tags = Column(StringList, nullable=True)
"""

from __future__ import annotations

import json
import uuid
from typing import Any, List, Optional

from sqlalchemy import String, Text, TypeDecorator
from sqlalchemy.dialects.postgresql import UUID as PG_UUID, JSONB, ARRAY

from app.core.config import settings

_is_sqlite = settings.DATABASE_URL.startswith("sqlite")


class GUID(TypeDecorator):
    """Platform-independent UUID type.

    Uses PostgreSQL's native UUID when available,
    otherwise stores as a 32-character hex string in SQLite.
    """
    impl = String(32)
    cache_ok = True

    def load_dialect_impl(self, dialect):
        if dialect.name == "postgresql":
            return dialect.type_descriptor(PG_UUID(as_uuid=True))
        return dialect.type_descriptor(String(32))

    def process_bind_param(self, value, dialect):
        if value is None:
            return value
        if dialect.name == "postgresql":
            return value if isinstance(value, uuid.UUID) else uuid.UUID(value)
        # SQLite: store as hex string
        if isinstance(value, uuid.UUID):
            return value.hex
        return uuid.UUID(value).hex

    def process_result_value(self, value, dialect):
        if value is None:
            return value
        if isinstance(value, uuid.UUID):
            return value
        return uuid.UUID(value)


class JSONDict(TypeDecorator):
    """Platform-independent JSONB type.

    Uses PostgreSQL's JSONB for indexing/querying,
    falls back to TEXT-based JSON for SQLite.
    """
    impl = Text
    cache_ok = True

    def load_dialect_impl(self, dialect):
        if dialect.name == "postgresql":
            return dialect.type_descriptor(JSONB)
        return dialect.type_descriptor(Text)

    def process_bind_param(self, value, dialect):
        if value is None:
            return value
        if dialect.name == "postgresql":
            return value  # psycopg / asyncpg handles dict→jsonb natively
        return json.dumps(value, ensure_ascii=False)

    def process_result_value(self, value, dialect):
        if value is None:
            return value
        if isinstance(value, (dict, list)):
            return value
        return json.loads(value)


class StringArray(TypeDecorator):
    """Platform-independent ARRAY(String) type.

    Uses PostgreSQL's ARRAY(String) natively,
    falls back to JSON list stored as TEXT for SQLite.
    """
    impl = Text
    cache_ok = True

    def load_dialect_impl(self, dialect):
        if dialect.name == "postgresql":
            return dialect.type_descriptor(ARRAY(String))
        return dialect.type_descriptor(Text)

    def process_bind_param(self, value, dialect):
        if value is None:
            return value
        if dialect.name == "postgresql":
            return value  # native array
        return json.dumps(value, ensure_ascii=False)

    def process_result_value(self, value, dialect):
        if value is None:
            return value
        if isinstance(value, list):
            return value
        return json.loads(value)


# ── Convenience singletons (use like Column(JSON_DICT, ...)) ──
JSON_DICT = JSONDict()
StringList = StringArray()

"""
Generic async CRUD helpers using SQLAlchemy.

Works with both PostgreSQL (production) and SQLite (local dev).
Every function takes a SQLAlchemy model class and an async session.
"""

from __future__ import annotations

from typing import Any, Dict, List, Optional, Type, TypeVar
from uuid import UUID
from datetime import datetime, timezone

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException, status

from app.core.database import Base

T = TypeVar("T", bound=Base)


def _now() -> datetime:
    return datetime.now(timezone.utc)


async def create_row(
    session: AsyncSession,
    model: Type[T],
    data: Dict[str, Any],
) -> T:
    """Insert a new row. Returns the ORM instance."""
    row = model(**data)
    session.add(row)
    await session.flush()
    await session.refresh(row)
    return row


async def get_row(
    session: AsyncSession,
    model: Type[T],
    row_id: UUID,
) -> T:
    """Get a single row by primary key. Raises 404 if missing."""
    row = await session.get(model, row_id)
    if row is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"{model.__tablename__} row {row_id} not found.",
        )
    return row


async def get_row_by_field(
    session: AsyncSession,
    model: Type[T],
    field_name: str,
    value: Any,
) -> Optional[T]:
    """Get a single row by an arbitrary column value. Returns None if not found."""
    col = getattr(model, field_name)
    stmt = select(model).where(col == value)
    result = await session.execute(stmt)
    return result.scalar_one_or_none()


async def list_rows(
    session: AsyncSession,
    model: Type[T],
    filters: Optional[List[tuple]] = None,
    order_by: Optional[str] = "created_at",
    descending: bool = True,
    offset: int = 0,
    limit: int = 50,
) -> List[T]:
    """
    List rows with optional filters, ordering, and pagination.
    `filters` is a list of (column_name, op, value) tuples.
    Supported ops: "==", "!=", ">", "<", ">=", "<=", "in".
    """
    stmt = select(model)

    if filters:
        for col_name, op, value in filters:
            col = getattr(model, col_name)
            if op == "==":
                stmt = stmt.where(col == value)
            elif op == "!=":
                stmt = stmt.where(col != value)
            elif op == ">":
                stmt = stmt.where(col > value)
            elif op == "<":
                stmt = stmt.where(col < value)
            elif op == ">=":
                stmt = stmt.where(col >= value)
            elif op == "<=":
                stmt = stmt.where(col <= value)
            elif op == "in":
                stmt = stmt.where(col.in_(value))

    if order_by and hasattr(model, order_by):
        col = getattr(model, order_by)
        stmt = stmt.order_by(col.desc() if descending else col.asc())

    stmt = stmt.offset(offset).limit(limit)
    result = await session.execute(stmt)
    return list(result.scalars().all())


async def count_rows(
    session: AsyncSession,
    model: Type[T],
    filters: Optional[List[tuple]] = None,
) -> int:
    """Count rows with optional filters."""
    stmt = select(func.count()).select_from(model)
    if filters:
        for col_name, op, value in filters:
            col = getattr(model, col_name)
            if op == "==":
                stmt = stmt.where(col == value)
    result = await session.execute(stmt)
    return result.scalar_one()


async def update_row(
    session: AsyncSession,
    model: Type[T],
    row_id: UUID,
    data: Dict[str, Any],
) -> T:
    """Update fields on an existing row. Raises 404 if missing."""
    row = await get_row(session, model, row_id)
    # Remove None values to allow partial updates
    clean = {k: v for k, v in data.items() if v is not None}
    clean["updated_at"] = _now()
    for key, value in clean.items():
        if hasattr(row, key):
            setattr(row, key, value)
    await session.flush()
    await session.refresh(row)
    return row


async def delete_row(
    session: AsyncSession,
    model: Type[T],
    row_id: UUID,
) -> None:
    """Delete a row by primary key. Raises 404 if missing."""
    row = await get_row(session, model, row_id)
    await session.delete(row)
    await session.flush()

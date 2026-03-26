"""
Shared schema helpers.
"""

from pydantic import BaseModel
from pydantic.alias_generators import to_camel
from typing import Optional
from datetime import datetime
from uuid import UUID


def _to_camel(s: str) -> str:
    """snake_case → camelCase  (e.g. display_name → displayName)."""
    return to_camel(s)


class CamelModel(BaseModel):
    """Base for all *input* schemas.

    Accepts BOTH camelCase and snake_case keys in request JSON.
    - ``populate_by_name = True`` → snake_case field names always work.
    - ``alias_generator = _to_camel`` → camelCase aliases also work.
    Example: both ``{"display_name": "X"}`` and ``{"displayName": "X"}`` are valid.
    """
    model_config = {
        "alias_generator": _to_camel,
        "populate_by_name": True,      # accept the real field name too
    }


class TimestampMixin(BaseModel):
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    model_config = {"from_attributes": True}


class MessageResponse(BaseModel):
    message: str


class IDResponse(BaseModel):
    id: UUID
    message: str = "Created successfully"


class PaginationParams(BaseModel):
    offset: int = 0
    limit: int = 50

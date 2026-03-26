"""
Pydantic schemas: legal_query_threads, legal_query_messages.
Matches PostgreSQL ERD exactly.
All *input* schemas accept BOTH camelCase and snake_case JSON keys.
"""

from pydantic import BaseModel
from typing import Optional, Dict, Any
from uuid import UUID
from .common import TimestampMixin, CamelModel


# ══════════════════════════════════════════════════════════════════════════════
#  LEGAL QUERY THREAD
# ══════════════════════════════════════════════════════════════════════════════

class LegalQueryThreadCreate(CamelModel):
    title: Optional[str] = None
    category: Optional[str] = None
    status: str = "active"

class LegalQueryThreadUpdate(CamelModel):
    title: Optional[str] = None
    category: Optional[str] = None
    status: Optional[str] = None

class LegalQueryThreadOut(TimestampMixin):
    id: UUID
    account_id: UUID
    title: Optional[str] = None
    category: Optional[str] = None
    status: Optional[str] = None


# ══════════════════════════════════════════════════════════════════════════════
#  LEGAL QUERY MESSAGE
# ══════════════════════════════════════════════════════════════════════════════

class LegalQueryMessageCreate(CamelModel):
    role: str  # user | assistant
    content: str
    sequence: Optional[int] = None
    extra: Optional[Dict[str, Any]] = None

class LegalQueryMessageOut(TimestampMixin):
    id: UUID
    thread_id: UUID
    role: Optional[str] = None
    content: Optional[str] = None
    sequence: Optional[int] = None
    extra: Optional[Dict[str, Any]] = None

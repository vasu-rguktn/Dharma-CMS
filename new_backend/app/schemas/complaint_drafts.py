"""
Pydantic schemas: complaint_drafts, complaint_draft_messages.
Matches PostgreSQL ERD exactly.
All *input* schemas accept BOTH camelCase and snake_case JSON keys.
"""

from pydantic import BaseModel
from typing import Optional, Dict, Any
from uuid import UUID
from .common import TimestampMixin, CamelModel


# ══════════════════════════════════════════════════════════════════════════════
#  COMPLAINT DRAFT
# ══════════════════════════════════════════════════════════════════════════════

class ComplaintDraftCreate(CamelModel):
    title: Optional[str] = None
    complaint_type: Optional[str] = None
    status: str = "in_progress"  # in_progress | completed | submitted
    is_anonymous: bool = False
    summary: Optional[str] = None
    generated_complaint: Optional[str] = None
    answers_json: Optional[Dict[str, Any]] = None
    state_json: Optional[Dict[str, Any]] = None

class ComplaintDraftUpdate(CamelModel):
    title: Optional[str] = None
    complaint_type: Optional[str] = None
    status: Optional[str] = None
    is_anonymous: Optional[bool] = None
    summary: Optional[str] = None
    generated_complaint: Optional[str] = None
    answers_json: Optional[Dict[str, Any]] = None
    state_json: Optional[Dict[str, Any]] = None
    submitted_petition_id: Optional[UUID] = None

class ComplaintDraftOut(TimestampMixin):
    id: UUID
    created_by_account_id: UUID
    title: Optional[str] = None
    complaint_type: Optional[str] = None
    status: Optional[str] = None
    is_anonymous: bool = False
    summary: Optional[str] = None
    generated_complaint: Optional[str] = None
    answers_json: Optional[Dict[str, Any]] = None
    state_json: Optional[Dict[str, Any]] = None
    submitted_petition_id: Optional[UUID] = None


# ══════════════════════════════════════════════════════════════════════════════
#  COMPLAINT DRAFT MESSAGE
# ══════════════════════════════════════════════════════════════════════════════

class ComplaintDraftMessageCreate(CamelModel):
    role: str  # user | assistant
    content: str
    message_type: Optional[str] = "text"  # text | audio | image
    sequence: Optional[int] = None
    extra: Optional[Dict[str, Any]] = None

class ComplaintDraftMessageOut(TimestampMixin):
    id: UUID
    draft_id: UUID
    role: Optional[str] = None
    content: Optional[str] = None
    message_type: Optional[str] = None
    sequence: Optional[int] = None
    extra: Optional[Dict[str, Any]] = None

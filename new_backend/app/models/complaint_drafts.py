"""
ORM models: complaint_drafts, complaint_draft_messages.
"""

import uuid
from datetime import datetime, timezone
from sqlalchemy import (
    Column, String, Boolean, DateTime, ForeignKey, Text, Integer,
)
from sqlalchemy.orm import relationship

from app.core.database import Base
from app.core.column_types import GUID, JSON_DICT


def _utcnow():
    return datetime.now(timezone.utc)


class ComplaintDraft(Base):
    __tablename__ = "complaint_drafts"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    created_by_account_id = Column(GUID(), ForeignKey("accounts.id", ondelete="CASCADE"), nullable=False, index=True)
    title = Column(String(500), nullable=True)
    complaint_type = Column(String(100), nullable=True)
    status = Column(String(50), nullable=False, default="in_progress")  # in_progress | completed | submitted
    is_anonymous = Column(Boolean, default=False, nullable=False)
    summary = Column(Text, nullable=True)
    generated_complaint = Column(Text, nullable=True)
    answers_json = Column(JSON_DICT, nullable=True)
    state_json = Column(JSON_DICT, nullable=True)
    submitted_petition_id = Column(GUID(), ForeignKey("petitions.id", ondelete="SET NULL"), nullable=True)

    created_at = Column(DateTime(timezone=True), default=_utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=_utcnow, onupdate=_utcnow, nullable=False)

    account = relationship("Account", back_populates="complaint_drafts")
    messages = relationship("ComplaintDraftMessage", back_populates="draft", cascade="all, delete-orphan", order_by="ComplaintDraftMessage.created_at")


class ComplaintDraftMessage(Base):
    __tablename__ = "complaint_draft_messages"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    draft_id = Column(GUID(), ForeignKey("complaint_drafts.id", ondelete="CASCADE"), nullable=False, index=True)
    role = Column(String(20), nullable=False)  # user | assistant
    content = Column(Text, nullable=False)
    message_type = Column(String(20), nullable=True, default="text")  # text | audio | image
    sequence = Column(Integer, nullable=True)
    extra = Column(JSON_DICT, nullable=True)

    created_at = Column(DateTime(timezone=True), default=_utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=_utcnow, onupdate=_utcnow, nullable=False)

    draft = relationship("ComplaintDraft", back_populates="messages")

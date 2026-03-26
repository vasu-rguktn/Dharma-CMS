"""
ORM models: legal_query_threads, legal_query_messages.
"""

import uuid
from datetime import datetime, timezone
from sqlalchemy import (
    Column, String, DateTime, ForeignKey, Text, Integer,
)
from sqlalchemy.orm import relationship

from app.core.database import Base
from app.core.column_types import GUID, JSON_DICT


def _utcnow():
    return datetime.now(timezone.utc)


class LegalQueryThread(Base):
    __tablename__ = "legal_query_threads"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    account_id = Column(GUID(), ForeignKey("accounts.id", ondelete="CASCADE"), nullable=False, index=True)
    title = Column(String(500), nullable=True)
    category = Column(String(100), nullable=True)
    status = Column(String(50), nullable=False, default="active")  # active | closed

    created_at = Column(DateTime(timezone=True), default=_utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=_utcnow, onupdate=_utcnow, nullable=False)

    account = relationship("Account", back_populates="legal_query_threads")
    messages = relationship("LegalQueryMessage", back_populates="thread", cascade="all, delete-orphan", order_by="LegalQueryMessage.created_at")


class LegalQueryMessage(Base):
    __tablename__ = "legal_query_messages"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    thread_id = Column(GUID(), ForeignKey("legal_query_threads.id", ondelete="CASCADE"), nullable=False, index=True)
    role = Column(String(20), nullable=False)  # user | assistant
    content = Column(Text, nullable=False)
    sequence = Column(Integer, nullable=True)
    extra = Column(JSON_DICT, nullable=True)

    created_at = Column(DateTime(timezone=True), default=_utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=_utcnow, onupdate=_utcnow, nullable=False)

    thread = relationship("LegalQueryThread", back_populates="messages")

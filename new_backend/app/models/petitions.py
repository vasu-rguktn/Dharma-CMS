"""
ORM models: petitions, petition_assignments, petition_attachments,
petition_updates, petition_update_attachments, petition_saves.
"""

import uuid
from datetime import datetime, timezone
from sqlalchemy import (
    Column, String, Boolean, DateTime, Float, ForeignKey, Text, Integer,
)
from sqlalchemy.orm import relationship

from app.core.database import Base
from app.core.column_types import GUID, JSON_DICT


def _utcnow():
    return datetime.now(timezone.utc)


class Petition(Base):
    __tablename__ = "petitions"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    created_by_account_id = Column(GUID(), ForeignKey("accounts.id", ondelete="SET NULL"), nullable=True, index=True)
    submitted_by_account_id = Column(GUID(), ForeignKey("accounts.id", ondelete="SET NULL"), nullable=True)

    submission_channel = Column(String(20), nullable=False, default="online")  # online | offline
    petition_type = Column(String(100), nullable=True)
    title = Column(String(500), nullable=True)
    petitioner_name = Column(String(255), nullable=True)
    grounds = Column(Text, nullable=True)
    description = Column(Text, nullable=True)

    incident_address = Column(Text, nullable=True)
    incident_at = Column(DateTime(timezone=True), nullable=True)
    district = Column(String(100), nullable=True)
    station_name = Column(String(255), nullable=True)

    lifecycle_status = Column(String(50), nullable=False, default="submitted")
    police_status = Column(String(50), nullable=True)
    police_sub_status = Column(String(100), nullable=True)

    is_anonymous = Column(Boolean, default=False, nullable=False)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)

    legacy_firestore_id = Column(String(128), nullable=True)
    legacy_case_ref = Column(String(128), nullable=True)

    created_at = Column(DateTime(timezone=True), default=_utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=_utcnow, onupdate=_utcnow, nullable=False)

    # ── relationships ──
    created_by_account = relationship("Account", back_populates="petitions", foreign_keys=[created_by_account_id])
    assignments = relationship("PetitionAssignment", back_populates="petition", cascade="all, delete-orphan")
    attachments = relationship("PetitionAttachment", back_populates="petition", cascade="all, delete-orphan")
    updates = relationship("PetitionUpdate", back_populates="petition", cascade="all, delete-orphan")
    saves = relationship("PetitionSave", back_populates="petition", cascade="all, delete-orphan")
    case = relationship("Case", back_populates="petition", uselist=False)


class PetitionAssignment(Base):
    __tablename__ = "petition_assignments"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    petition_id = Column(GUID(), ForeignKey("petitions.id", ondelete="CASCADE"), nullable=False, index=True)
    assigned_by_account_id = Column(GUID(), ForeignKey("accounts.id", ondelete="SET NULL"), nullable=True)
    assigned_to_account_id = Column(GUID(), ForeignKey("accounts.id", ondelete="SET NULL"), nullable=True)
    scope_type = Column(String(50), nullable=True)  # district | station
    status = Column(String(50), nullable=True, default="assigned")
    scope_district = Column(String(100), nullable=True)
    scope_station_name = Column(String(255), nullable=True)
    notes = Column(Text, nullable=True)

    created_at = Column(DateTime(timezone=True), default=_utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=_utcnow, onupdate=_utcnow, nullable=False)

    petition = relationship("Petition", back_populates="assignments")


class PetitionAttachment(Base):
    __tablename__ = "petition_attachments"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    petition_id = Column(GUID(), ForeignKey("petitions.id", ondelete="CASCADE"), nullable=False, index=True)
    uploaded_by_account_id = Column(GUID(), ForeignKey("accounts.id", ondelete="SET NULL"), nullable=True)
    file_url = Column(Text, nullable=False)
    file_name = Column(String(255), nullable=True)
    file_type = Column(String(100), nullable=True)
    file_size = Column(Integer, nullable=True)
    description = Column(Text, nullable=True)

    created_at = Column(DateTime(timezone=True), default=_utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=_utcnow, onupdate=_utcnow, nullable=False)

    petition = relationship("Petition", back_populates="attachments")


class PetitionUpdate(Base):
    __tablename__ = "petition_updates"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    petition_id = Column(GUID(), ForeignKey("petitions.id", ondelete="CASCADE"), nullable=False, index=True)
    added_by_account_id = Column(GUID(), ForeignKey("accounts.id", ondelete="SET NULL"), nullable=True)
    update_text = Column(Text, nullable=True)
    ai_status = Column(String(50), nullable=True)
    ai_score = Column(Float, nullable=True)
    upload_errors = Column(Text, nullable=True)

    created_at = Column(DateTime(timezone=True), default=_utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=_utcnow, onupdate=_utcnow, nullable=False)

    petition = relationship("Petition", back_populates="updates")
    attachments = relationship("PetitionUpdateAttachment", back_populates="petition_update", cascade="all, delete-orphan")


class PetitionUpdateAttachment(Base):
    __tablename__ = "petition_update_attachments"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    petition_update_id = Column(GUID(), ForeignKey("petition_updates.id", ondelete="CASCADE"), nullable=False, index=True)
    file_url = Column(Text, nullable=False)
    file_name = Column(String(255), nullable=True)
    file_type = Column(String(100), nullable=True)
    file_size = Column(Integer, nullable=True)

    created_at = Column(DateTime(timezone=True), default=_utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=_utcnow, onupdate=_utcnow, nullable=False)

    petition_update = relationship("PetitionUpdate", back_populates="attachments")


class PetitionSave(Base):
    __tablename__ = "petition_saves"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    account_id = Column(GUID(), ForeignKey("accounts.id", ondelete="CASCADE"), nullable=False, index=True)
    petition_id = Column(GUID(), ForeignKey("petitions.id", ondelete="CASCADE"), nullable=False, index=True)
    snapshot_json = Column(JSON_DICT, nullable=True)
    note = Column(Text, nullable=True)

    created_at = Column(DateTime(timezone=True), default=_utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=_utcnow, onupdate=_utcnow, nullable=False)

    petition = relationship("Petition", back_populates="saves")

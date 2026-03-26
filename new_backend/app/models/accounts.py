"""
ORM models: accounts, citizen_profiles, police_profiles, device_tokens.
"""

import uuid
from datetime import datetime, timezone
from sqlalchemy import (
    Column, String, Boolean, DateTime, ForeignKey, Text,
)
from sqlalchemy.orm import relationship

from app.core.database import Base
from app.core.column_types import GUID


def _utcnow():
    return datetime.now(timezone.utc)


class Account(Base):
    __tablename__ = "accounts"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    firebase_uid = Column(String(128), unique=True, nullable=False, index=True)
    role = Column(String(20), nullable=False, default="citizen")  # citizen | police | admin
    display_name = Column(String(255), nullable=True)
    email = Column(String(255), nullable=True)
    phone_number = Column(String(20), nullable=True)
    photo_url = Column(Text, nullable=True)
    legacy_firestore_id = Column(String(128), nullable=True)
    legacy_source_collection = Column(String(50), nullable=True)

    created_at = Column(DateTime(timezone=True), default=_utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=_utcnow, onupdate=_utcnow, nullable=False)

    # ── relationships ──
    citizen_profile = relationship("CitizenProfile", back_populates="account", uselist=False, cascade="all, delete-orphan")
    police_profile = relationship("PoliceProfile", back_populates="account", uselist=False, cascade="all, delete-orphan")
    device_tokens = relationship("DeviceToken", back_populates="account", cascade="all, delete-orphan")
    petitions = relationship("Petition", back_populates="created_by_account", foreign_keys="Petition.created_by_account_id")
    complaint_drafts = relationship("ComplaintDraft", back_populates="account", cascade="all, delete-orphan")
    legal_query_threads = relationship("LegalQueryThread", back_populates="account", cascade="all, delete-orphan")


class CitizenProfile(Base):
    __tablename__ = "citizen_profiles"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    account_id = Column(GUID(), ForeignKey("accounts.id", ondelete="CASCADE"), unique=True, nullable=False)
    dob = Column(String(20), nullable=True)
    gender = Column(String(20), nullable=True)
    aadhaar_number = Column(String(20), nullable=True)
    house_no = Column(String(50), nullable=True)
    address_line1 = Column(Text, nullable=True)
    district = Column(String(100), nullable=True)
    state = Column(String(100), nullable=True, default="Tamil Nadu")
    country = Column(String(100), nullable=True, default="India")
    pincode = Column(String(10), nullable=True)

    created_at = Column(DateTime(timezone=True), default=_utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=_utcnow, onupdate=_utcnow, nullable=False)

    account = relationship("Account", back_populates="citizen_profile")


class PoliceProfile(Base):
    __tablename__ = "police_profiles"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    account_id = Column(GUID(), ForeignKey("accounts.id", ondelete="CASCADE"), unique=True, nullable=False)
    rank = Column(String(100), nullable=True)
    district = Column(String(100), nullable=True)
    station_name = Column(String(255), nullable=True)
    range_name = Column(String(255), nullable=True)
    circle_name = Column(String(255), nullable=True)
    sdpo_name = Column(String(255), nullable=True)
    is_approved = Column(Boolean, default=False, nullable=False)

    created_at = Column(DateTime(timezone=True), default=_utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=_utcnow, onupdate=_utcnow, nullable=False)

    account = relationship("Account", back_populates="police_profile")


class DeviceToken(Base):
    __tablename__ = "device_tokens"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    account_id = Column(GUID(), ForeignKey("accounts.id", ondelete="CASCADE"), nullable=False, index=True)
    token = Column(Text, nullable=False)
    platform = Column(String(20), nullable=True)  # android | ios | web
    device_info = Column(String(255), nullable=True)

    created_at = Column(DateTime(timezone=True), default=_utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=_utcnow, onupdate=_utcnow, nullable=False)

    account = relationship("Account", back_populates="device_tokens")

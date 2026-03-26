"""
ORM models: cases, case_people, case_officers, case_crime_details,
case_journal_entries, case_journal_attachments, case_documents.
"""

import uuid
from datetime import datetime, timezone
from sqlalchemy import (
    Column, String, Boolean, DateTime, Float, ForeignKey, Text, Integer, Date,
)
from sqlalchemy.orm import relationship

from app.core.database import Base
from app.core.column_types import GUID, JSON_DICT


def _utcnow():
    return datetime.now(timezone.utc)


class Case(Base):
    __tablename__ = "cases"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    petition_id = Column(GUID(), ForeignKey("petitions.id", ondelete="SET NULL"), nullable=True, index=True)
    case_reference = Column(String(100), unique=True, nullable=True)
    fir_number = Column(String(100), nullable=True)
    title = Column(String(500), nullable=True)
    district = Column(String(100), nullable=True)
    police_station = Column(String(255), nullable=True)
    status = Column(String(50), nullable=False, default="open")
    date_filed = Column(Date, nullable=True)
    fir_filed_at = Column(DateTime(timezone=True), nullable=True)
    complaint_statement = Column(Text, nullable=True)
    incident_details = Column(Text, nullable=True)
    acts_and_sections_text = Column(Text, nullable=True)

    legacy_firestore_id = Column(String(128), nullable=True)

    created_at = Column(DateTime(timezone=True), default=_utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=_utcnow, onupdate=_utcnow, nullable=False)

    # ── relationships ──
    petition = relationship("Petition", back_populates="case")
    people = relationship("CasePerson", back_populates="case", cascade="all, delete-orphan")
    officers = relationship("CaseOfficer", back_populates="case", cascade="all, delete-orphan")
    crime_detail = relationship("CaseCrimeDetail", back_populates="case", uselist=False, cascade="all, delete-orphan")
    journal_entries = relationship("CaseJournalEntry", back_populates="case", cascade="all, delete-orphan")
    documents = relationship("CaseDocument", back_populates="case", cascade="all, delete-orphan")


class CasePerson(Base):
    __tablename__ = "case_people"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    case_id = Column(GUID(), ForeignKey("cases.id", ondelete="CASCADE"), nullable=False, index=True)
    role = Column(String(50), nullable=False)  # complainant | victim | accused | witness | reporting_person | petitioner
    name = Column(String(255), nullable=False)
    father_name = Column(String(255), nullable=True)
    age = Column(Integer, nullable=True)
    gender = Column(String(20), nullable=True)
    address = Column(Text, nullable=True)
    phone = Column(String(20), nullable=True)
    id_type = Column(String(50), nullable=True)
    id_number = Column(String(50), nullable=True)
    description = Column(Text, nullable=True)

    created_at = Column(DateTime(timezone=True), default=_utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=_utcnow, onupdate=_utcnow, nullable=False)

    case = relationship("Case", back_populates="people")


class CaseOfficer(Base):
    __tablename__ = "case_officers"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    case_id = Column(GUID(), ForeignKey("cases.id", ondelete="CASCADE"), nullable=False, index=True)
    officer_account_id = Column(GUID(), ForeignKey("accounts.id", ondelete="SET NULL"), nullable=True)
    officer_name = Column(String(255), nullable=True)
    officer_rank = Column(String(100), nullable=True)
    role = Column(String(50), nullable=True)  # reporting_officer | dispatch_officer | investigating_officer | supervising_officer
    assigned_date = Column(Date, nullable=True)

    created_at = Column(DateTime(timezone=True), default=_utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=_utcnow, onupdate=_utcnow, nullable=False)

    case = relationship("Case", back_populates="officers")


class CaseCrimeDetail(Base):
    __tablename__ = "case_crime_details"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    case_id = Column(GUID(), ForeignKey("cases.id", ondelete="CASCADE"), unique=True, nullable=False)
    crime_type = Column(String(100), nullable=True)
    ipc_sections = Column(Text, nullable=True)  # stored as comma-separated or JSON text
    description = Column(Text, nullable=True)
    modus_operandi = Column(Text, nullable=True)
    weapon_used = Column(String(255), nullable=True)
    property_stolen = Column(Text, nullable=True)
    property_value = Column(Float, nullable=True)

    created_at = Column(DateTime(timezone=True), default=_utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=_utcnow, onupdate=_utcnow, nullable=False)

    case = relationship("Case", back_populates="crime_detail")


class CaseJournalEntry(Base):
    __tablename__ = "case_journal_entries"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    case_id = Column(GUID(), ForeignKey("cases.id", ondelete="CASCADE"), nullable=False, index=True)
    officer_account_id = Column(GUID(), ForeignKey("accounts.id", ondelete="SET NULL"), nullable=True)
    officer_name = Column(String(255), nullable=True)
    officer_rank = Column(String(100), nullable=True)
    activity_type = Column(String(100), nullable=True)
    entry_text = Column(Text, nullable=True)
    entry_at = Column(DateTime(timezone=True), nullable=True)

    created_at = Column(DateTime(timezone=True), default=_utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=_utcnow, onupdate=_utcnow, nullable=False)

    case = relationship("Case", back_populates="journal_entries")
    attachments = relationship("CaseJournalAttachment", back_populates="journal_entry", cascade="all, delete-orphan")


class CaseJournalAttachment(Base):
    __tablename__ = "case_journal_attachments"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    journal_entry_id = Column(GUID(), ForeignKey("case_journal_entries.id", ondelete="CASCADE"), nullable=False, index=True)
    file_url = Column(Text, nullable=False)
    file_name = Column(String(255), nullable=True)
    file_type = Column(String(100), nullable=True)
    file_size = Column(Integer, nullable=True)

    created_at = Column(DateTime(timezone=True), default=_utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=_utcnow, onupdate=_utcnow, nullable=False)

    journal_entry = relationship("CaseJournalEntry", back_populates="attachments")


class CaseDocument(Base):
    __tablename__ = "case_documents"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    case_id = Column(GUID(), ForeignKey("cases.id", ondelete="CASCADE"), nullable=False, index=True)
    document_type = Column(String(50), nullable=True)  # fir | investigation_report | chargesheet | evidence | other
    title = Column(String(500), nullable=True)
    file_url = Column(Text, nullable=False)
    file_name = Column(String(255), nullable=True)
    file_type = Column(String(100), nullable=True)
    file_size = Column(Integer, nullable=True)
    generated_by = Column(String(20), nullable=True)  # ai | manual
    description = Column(Text, nullable=True)

    created_at = Column(DateTime(timezone=True), default=_utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=_utcnow, onupdate=_utcnow, nullable=False)

    case = relationship("Case", back_populates="documents")

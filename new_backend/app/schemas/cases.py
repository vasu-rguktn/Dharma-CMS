"""
Pydantic schemas: cases and all sub-tables.
Matches PostgreSQL ERD exactly.
All *input* schemas accept BOTH camelCase and snake_case JSON keys.
"""

from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime, date
from uuid import UUID
from .common import TimestampMixin, CamelModel


# ══════════════════════════════════════════════════════════════════════════════
#  CASE
# ══════════════════════════════════════════════════════════════════════════════

class CaseCreate(CamelModel):
    petition_id: Optional[UUID] = None
    case_reference: Optional[str] = None
    fir_number: Optional[str] = None
    title: Optional[str] = None
    district: Optional[str] = None
    police_station: Optional[str] = None
    status: str = "open"
    date_filed: Optional[date] = None
    fir_filed_at: Optional[datetime] = None
    complaint_statement: Optional[str] = None
    incident_details: Optional[str] = None
    acts_and_sections_text: Optional[str] = None

class CaseUpdate(CamelModel):
    case_reference: Optional[str] = None
    fir_number: Optional[str] = None
    title: Optional[str] = None
    district: Optional[str] = None
    police_station: Optional[str] = None
    status: Optional[str] = None
    date_filed: Optional[date] = None
    fir_filed_at: Optional[datetime] = None
    complaint_statement: Optional[str] = None
    incident_details: Optional[str] = None
    acts_and_sections_text: Optional[str] = None

class CaseOut(TimestampMixin):
    id: UUID
    petition_id: Optional[UUID] = None
    case_reference: Optional[str] = None
    fir_number: Optional[str] = None
    title: Optional[str] = None
    district: Optional[str] = None
    police_station: Optional[str] = None
    status: Optional[str] = None
    date_filed: Optional[date] = None
    fir_filed_at: Optional[datetime] = None
    complaint_statement: Optional[str] = None
    incident_details: Optional[str] = None
    acts_and_sections_text: Optional[str] = None


# ══════════════════════════════════════════════════════════════════════════════
#  CASE PEOPLE
# ══════════════════════════════════════════════════════════════════════════════

class CasePersonCreate(CamelModel):
    role: str  # complainant | victim | accused | witness | reporting_person | petitioner
    name: str
    father_name: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None
    id_type: Optional[str] = None
    id_number: Optional[str] = None
    description: Optional[str] = None

class CasePersonUpdate(CamelModel):
    role: Optional[str] = None
    name: Optional[str] = None
    father_name: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None
    id_type: Optional[str] = None
    id_number: Optional[str] = None
    description: Optional[str] = None

class CasePersonOut(TimestampMixin):
    id: UUID
    case_id: UUID
    role: Optional[str] = None
    name: Optional[str] = None
    father_name: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None
    id_type: Optional[str] = None
    id_number: Optional[str] = None
    description: Optional[str] = None


# ══════════════════════════════════════════════════════════════════════════════
#  CASE OFFICERS
# ══════════════════════════════════════════════════════════════════════════════

class CaseOfficerCreate(CamelModel):
    officer_account_id: Optional[UUID] = None
    officer_name: Optional[str] = None
    officer_rank: Optional[str] = None
    role: Optional[str] = None  # reporting_officer | dispatch_officer | investigating_officer | supervising_officer
    assigned_date: Optional[date] = None

class CaseOfficerUpdate(CamelModel):
    officer_name: Optional[str] = None
    officer_rank: Optional[str] = None
    role: Optional[str] = None
    assigned_date: Optional[date] = None

class CaseOfficerOut(TimestampMixin):
    id: UUID
    case_id: UUID
    officer_account_id: Optional[UUID] = None
    officer_name: Optional[str] = None
    officer_rank: Optional[str] = None
    role: Optional[str] = None
    assigned_date: Optional[date] = None


# ══════════════════════════════════════════════════════════════════════════════
#  CASE CRIME DETAILS
# ══════════════════════════════════════════════════════════════════════════════

class CaseCrimeDetailCreate(CamelModel):
    crime_type: Optional[str] = None
    ipc_sections: Optional[str] = None
    description: Optional[str] = None
    modus_operandi: Optional[str] = None
    weapon_used: Optional[str] = None
    property_stolen: Optional[str] = None
    property_value: Optional[float] = None

class CaseCrimeDetailUpdate(CamelModel):
    crime_type: Optional[str] = None
    ipc_sections: Optional[str] = None
    description: Optional[str] = None
    modus_operandi: Optional[str] = None
    weapon_used: Optional[str] = None
    property_stolen: Optional[str] = None
    property_value: Optional[float] = None

class CaseCrimeDetailOut(TimestampMixin):
    id: UUID
    case_id: UUID
    crime_type: Optional[str] = None
    ipc_sections: Optional[str] = None
    description: Optional[str] = None
    modus_operandi: Optional[str] = None
    weapon_used: Optional[str] = None
    property_stolen: Optional[str] = None
    property_value: Optional[float] = None


# ══════════════════════════════════════════════════════════════════════════════
#  CASE JOURNAL ENTRIES
# ══════════════════════════════════════════════════════════════════════════════

class CaseJournalEntryCreate(CamelModel):
    officer_name: Optional[str] = None
    officer_rank: Optional[str] = None
    activity_type: Optional[str] = None
    entry_text: Optional[str] = None
    entry_at: Optional[datetime] = None

class CaseJournalEntryUpdate(CamelModel):
    officer_name: Optional[str] = None
    officer_rank: Optional[str] = None
    activity_type: Optional[str] = None
    entry_text: Optional[str] = None
    entry_at: Optional[datetime] = None

class CaseJournalEntryOut(TimestampMixin):
    id: UUID
    case_id: UUID
    officer_account_id: Optional[UUID] = None
    officer_name: Optional[str] = None
    officer_rank: Optional[str] = None
    activity_type: Optional[str] = None
    entry_text: Optional[str] = None
    entry_at: Optional[datetime] = None


# ══════════════════════════════════════════════════════════════════════════════
#  CASE JOURNAL ATTACHMENTS
# ══════════════════════════════════════════════════════════════════════════════

class CaseJournalAttachmentCreate(CamelModel):
    file_url: str
    file_name: Optional[str] = None
    file_type: Optional[str] = None
    file_size: Optional[int] = None

class CaseJournalAttachmentOut(TimestampMixin):
    id: UUID
    journal_entry_id: UUID
    file_url: str
    file_name: Optional[str] = None
    file_type: Optional[str] = None
    file_size: Optional[int] = None


# ══════════════════════════════════════════════════════════════════════════════
#  CASE DOCUMENTS
# ══════════════════════════════════════════════════════════════════════════════

class CaseDocumentCreate(CamelModel):
    document_type: Optional[str] = None  # fir | investigation_report | chargesheet | evidence | other
    title: Optional[str] = None
    file_url: str
    file_name: Optional[str] = None
    file_type: Optional[str] = None
    file_size: Optional[int] = None
    generated_by: Optional[str] = None  # ai | manual
    description: Optional[str] = None

class CaseDocumentUpdate(CamelModel):
    document_type: Optional[str] = None
    title: Optional[str] = None
    file_url: Optional[str] = None
    file_name: Optional[str] = None
    file_type: Optional[str] = None
    file_size: Optional[int] = None
    generated_by: Optional[str] = None
    description: Optional[str] = None

class CaseDocumentOut(TimestampMixin):
    id: UUID
    case_id: UUID
    document_type: Optional[str] = None
    title: Optional[str] = None
    file_url: Optional[str] = None
    file_name: Optional[str] = None
    file_type: Optional[str] = None
    file_size: Optional[int] = None
    generated_by: Optional[str] = None
    description: Optional[str] = None

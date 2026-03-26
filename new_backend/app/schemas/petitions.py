"""
Pydantic schemas: petitions and all sub-tables.
Matches PostgreSQL ERD exactly.
All *input* schemas accept BOTH camelCase and snake_case JSON keys.
"""

from pydantic import BaseModel
from typing import Optional, Dict, Any
from datetime import datetime
from uuid import UUID
from .common import TimestampMixin, CamelModel


# ══════════════════════════════════════════════════════════════════════════════
#  PETITION
# ══════════════════════════════════════════════════════════════════════════════

class PetitionCreate(CamelModel):
    submission_channel: str = "online"
    petition_type: Optional[str] = None
    title: Optional[str] = None
    petitioner_name: Optional[str] = None
    grounds: Optional[str] = None
    description: Optional[str] = None
    incident_address: Optional[str] = None
    incident_at: Optional[datetime] = None
    district: Optional[str] = None
    station_name: Optional[str] = None
    is_anonymous: bool = False
    latitude: Optional[float] = None
    longitude: Optional[float] = None

class PetitionUpdate(CamelModel):
    petition_type: Optional[str] = None
    title: Optional[str] = None
    petitioner_name: Optional[str] = None
    grounds: Optional[str] = None
    description: Optional[str] = None
    incident_address: Optional[str] = None
    incident_at: Optional[datetime] = None
    district: Optional[str] = None
    station_name: Optional[str] = None
    lifecycle_status: Optional[str] = None
    police_status: Optional[str] = None
    police_sub_status: Optional[str] = None
    is_anonymous: Optional[bool] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None

class PetitionOut(TimestampMixin):
    id: UUID
    created_by_account_id: Optional[UUID] = None
    submitted_by_account_id: Optional[UUID] = None
    submission_channel: str = "online"
    petition_type: Optional[str] = None
    title: Optional[str] = None
    petitioner_name: Optional[str] = None
    grounds: Optional[str] = None
    description: Optional[str] = None
    incident_address: Optional[str] = None
    incident_at: Optional[datetime] = None
    district: Optional[str] = None
    station_name: Optional[str] = None
    lifecycle_status: Optional[str] = None
    police_status: Optional[str] = None
    police_sub_status: Optional[str] = None
    is_anonymous: bool = False
    latitude: Optional[float] = None
    longitude: Optional[float] = None


# ══════════════════════════════════════════════════════════════════════════════
#  PETITION ASSIGNMENT
# ══════════════════════════════════════════════════════════════════════════════

class PetitionAssignmentCreate(CamelModel):
    assigned_to_account_id: Optional[UUID] = None
    scope_type: Optional[str] = None
    status: str = "assigned"
    scope_district: Optional[str] = None
    scope_station_name: Optional[str] = None
    notes: Optional[str] = None

class PetitionAssignmentOut(TimestampMixin):
    id: UUID
    petition_id: UUID
    assigned_by_account_id: Optional[UUID] = None
    assigned_to_account_id: Optional[UUID] = None
    scope_type: Optional[str] = None
    status: Optional[str] = None
    scope_district: Optional[str] = None
    scope_station_name: Optional[str] = None
    notes: Optional[str] = None


# ══════════════════════════════════════════════════════════════════════════════
#  PETITION ATTACHMENT
# ══════════════════════════════════════════════════════════════════════════════

class PetitionAttachmentCreate(CamelModel):
    file_url: str
    file_name: Optional[str] = None
    file_type: Optional[str] = None
    file_size: Optional[int] = None
    description: Optional[str] = None

class PetitionAttachmentOut(TimestampMixin):
    id: UUID
    petition_id: UUID
    uploaded_by_account_id: Optional[UUID] = None
    file_url: str
    file_name: Optional[str] = None
    file_type: Optional[str] = None
    file_size: Optional[int] = None
    description: Optional[str] = None


# ══════════════════════════════════════════════════════════════════════════════
#  PETITION UPDATE
# ══════════════════════════════════════════════════════════════════════════════

class PetitionUpdateCreate(CamelModel):
    update_text: Optional[str] = None
    ai_status: Optional[str] = None
    ai_score: Optional[float] = None

class PetitionUpdateOut(TimestampMixin):
    id: UUID
    petition_id: UUID
    added_by_account_id: Optional[UUID] = None
    update_text: Optional[str] = None
    ai_status: Optional[str] = None
    ai_score: Optional[float] = None
    upload_errors: Optional[str] = None


# ══════════════════════════════════════════════════════════════════════════════
#  PETITION UPDATE ATTACHMENT
# ══════════════════════════════════════════════════════════════════════════════

class PetitionUpdateAttachmentCreate(CamelModel):
    file_url: str
    file_name: Optional[str] = None
    file_type: Optional[str] = None
    file_size: Optional[int] = None

class PetitionUpdateAttachmentOut(TimestampMixin):
    id: UUID
    petition_update_id: UUID
    file_url: str
    file_name: Optional[str] = None
    file_type: Optional[str] = None
    file_size: Optional[int] = None


# ══════════════════════════════════════════════════════════════════════════════
#  PETITION SAVE (bookmark)
# ══════════════════════════════════════════════════════════════════════════════

class PetitionSaveCreate(CamelModel):
    petition_id: UUID
    snapshot_json: Optional[Dict[str, Any]] = None
    note: Optional[str] = None

class PetitionSaveOut(TimestampMixin):
    id: UUID
    account_id: UUID
    petition_id: UUID
    snapshot_json: Optional[Dict[str, Any]] = None
    note: Optional[str] = None

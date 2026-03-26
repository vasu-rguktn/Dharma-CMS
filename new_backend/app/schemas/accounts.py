"""
Pydantic schemas: accounts, citizen_profiles, police_profiles, device_tokens.
Matches PostgreSQL ERD exactly.
All *input* schemas accept BOTH camelCase and snake_case JSON keys.
"""

from pydantic import BaseModel
from typing import Optional
from uuid import UUID
from .common import TimestampMixin, CamelModel


# ══════════════════════════════════════════════════════════════════════════════
#  ACCOUNT
# ══════════════════════════════════════════════════════════════════════════════

class AccountCreate(CamelModel):
    display_name: Optional[str] = None
    email: Optional[str] = None
    phone_number: Optional[str] = None
    photo_url: Optional[str] = None
    role: str = "citizen"

class AccountUpdate(CamelModel):
    display_name: Optional[str] = None
    email: Optional[str] = None
    phone_number: Optional[str] = None
    photo_url: Optional[str] = None

class AccountOut(TimestampMixin):
    id: UUID
    firebase_uid: str
    role: str = "citizen"
    display_name: Optional[str] = None
    email: Optional[str] = None
    phone_number: Optional[str] = None
    photo_url: Optional[str] = None


# ══════════════════════════════════════════════════════════════════════════════
#  CITIZEN PROFILE
# ══════════════════════════════════════════════════════════════════════════════

class CitizenProfileCreate(CamelModel):
    dob: Optional[str] = None
    gender: Optional[str] = None
    aadhaar_number: Optional[str] = None
    house_no: Optional[str] = None
    address_line1: Optional[str] = None
    district: Optional[str] = None
    state: Optional[str] = "Andhra Pradesh"
    country: Optional[str] = "India"
    pincode: Optional[str] = None

class CitizenProfileUpdate(CamelModel):
    dob: Optional[str] = None
    gender: Optional[str] = None
    aadhaar_number: Optional[str] = None
    house_no: Optional[str] = None
    address_line1: Optional[str] = None
    district: Optional[str] = None
    state: Optional[str] = None
    country: Optional[str] = None
    pincode: Optional[str] = None

class CitizenProfileOut(TimestampMixin):
    id: UUID
    account_id: UUID
    dob: Optional[str] = None
    gender: Optional[str] = None
    aadhaar_number: Optional[str] = None
    house_no: Optional[str] = None
    address_line1: Optional[str] = None
    district: Optional[str] = None
    state: Optional[str] = None
    country: Optional[str] = None
    pincode: Optional[str] = None


# ══════════════════════════════════════════════════════════════════════════════
#  POLICE PROFILE
# ══════════════════════════════════════════════════════════════════════════════

class PoliceProfileCreate(CamelModel):
    rank: Optional[str] = None
    district: Optional[str] = None
    station_name: Optional[str] = None
    range_name: Optional[str] = None
    circle_name: Optional[str] = None
    sdpo_name: Optional[str] = None
    is_approved: bool = False

class PoliceProfileUpdate(CamelModel):
    rank: Optional[str] = None
    district: Optional[str] = None
    station_name: Optional[str] = None
    range_name: Optional[str] = None
    circle_name: Optional[str] = None
    sdpo_name: Optional[str] = None
    is_approved: Optional[bool] = None

class PoliceProfileOut(TimestampMixin):
    id: UUID
    account_id: UUID
    rank: Optional[str] = None
    district: Optional[str] = None
    station_name: Optional[str] = None
    range_name: Optional[str] = None
    circle_name: Optional[str] = None
    sdpo_name: Optional[str] = None
    is_approved: bool = False


# ══════════════════════════════════════════════════════════════════════════════
#  DEVICE TOKEN
# ══════════════════════════════════════════════════════════════════════════════

class DeviceTokenCreate(CamelModel):
    token: str
    platform: Optional[str] = None  # android | ios | web
    device_info: Optional[str] = None

class DeviceTokenOut(TimestampMixin):
    id: UUID
    account_id: UUID
    token: str
    platform: Optional[str] = None
    device_info: Optional[str] = None

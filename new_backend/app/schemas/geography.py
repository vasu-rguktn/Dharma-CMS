"""
Pydantic schemas for police geography: districts, SDPOs, circles, stations, pincodes.
All *input* schemas accept BOTH camelCase and snake_case JSON keys.
"""

from pydantic import BaseModel
from typing import List, Optional
from uuid import UUID

from app.schemas.common import TimestampMixin, CamelModel


# ═══════════════════════════════════════════════
#  POLICE STATION
# ═══════════════════════════════════════════════

class PoliceStationCreate(CamelModel):
    name: str
    station_code: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    is_active: bool = True
    sort_order: int = 0


class PoliceStationUpdate(CamelModel):
    name: Optional[str] = None
    station_code: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    is_active: Optional[bool] = None
    sort_order: Optional[int] = None


class PoliceStationOut(TimestampMixin):
    id: UUID
    circle_id: UUID
    name: str
    station_code: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    is_active: bool
    sort_order: int


# ═══════════════════════════════════════════════
#  CIRCLE
# ═══════════════════════════════════════════════

class CircleCreate(CamelModel):
    name: str
    is_active: bool = True
    sort_order: int = 0


class CircleUpdate(CamelModel):
    name: Optional[str] = None
    is_active: Optional[bool] = None
    sort_order: Optional[int] = None


class CircleOut(TimestampMixin):
    id: UUID
    sdpo_id: UUID
    name: str
    is_active: bool
    sort_order: int


class CircleWithStationsOut(CircleOut):
    police_stations: List[PoliceStationOut] = []


# ═══════════════════════════════════════════════
#  SDPO
# ═══════════════════════════════════════════════

class SDPOCreate(CamelModel):
    name: str
    is_active: bool = True
    sort_order: int = 0


class SDPOUpdate(CamelModel):
    name: Optional[str] = None
    is_active: Optional[bool] = None
    sort_order: Optional[int] = None


class SDPOOut(TimestampMixin):
    id: UUID
    district_id: UUID
    name: str
    is_active: bool
    sort_order: int


class SDPOWithCirclesOut(SDPOOut):
    circles: List[CircleWithStationsOut] = []


# ═══════════════════════════════════════════════
#  DISTRICT
# ═══════════════════════════════════════════════

class DistrictCreate(CamelModel):
    name: str
    state: str = "Andhra Pradesh"
    code: Optional[str] = None
    range_name: Optional[str] = None
    is_active: bool = True
    sort_order: int = 0


class DistrictUpdate(CamelModel):
    name: Optional[str] = None
    state: Optional[str] = None
    code: Optional[str] = None
    range_name: Optional[str] = None
    is_active: Optional[bool] = None
    sort_order: Optional[int] = None


class DistrictOut(TimestampMixin):
    id: UUID
    state: str
    name: str
    code: Optional[str] = None
    range_name: Optional[str] = None
    is_active: bool
    sort_order: int


class DistrictWithHierarchyOut(DistrictOut):
    sdpos: List[SDPOWithCirclesOut] = []


# ═══════════════════════════════════════════════
#  PINCODE
# ═══════════════════════════════════════════════

class PincodeCreate(CamelModel):
    pincode: str
    area_name: Optional[str] = None


class PincodeOut(BaseModel):
    id: UUID
    district_id: UUID
    pincode: str
    area_name: Optional[str] = None

    model_config = {"from_attributes": True}


# ═══════════════════════════════════════════════
#  FULL HIERARCHY (for the /full endpoint)
# ═══════════════════════════════════════════════

class FullHierarchyOut(BaseModel):
    districts: List[DistrictWithHierarchyOut]


# ═══════════════════════════════════════════════
#  SEED STATUS
# ═══════════════════════════════════════════════

class SeedStatusOut(BaseModel):
    districts: int
    sdpos: int
    circles: int
    police_stations: int
    pincodes: int
    message: str

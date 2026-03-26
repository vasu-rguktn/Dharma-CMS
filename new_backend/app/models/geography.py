"""
ORM models: police geography — districts, SDPOs, circles, police stations, pincodes.

These replace the old static JSON files and make the hierarchy fully dynamic
and admin-manageable via API.

Hierarchy:  State → District → SDPO → Circle → PoliceStation
Pincodes:   District → Pincode (flat)
"""

import uuid
from datetime import datetime, timezone
from sqlalchemy import (
    Column, String, Boolean, DateTime, ForeignKey, Text, Integer,
    UniqueConstraint,
)
from sqlalchemy.orm import relationship

from app.core.database import Base
from app.core.column_types import GUID


def _utcnow():
    return datetime.now(timezone.utc)


class District(Base):
    __tablename__ = "districts"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    state = Column(String(100), nullable=False, default="Andhra Pradesh")
    name = Column(String(200), nullable=False)
    code = Column(String(50), nullable=True)          # optional short code
    range_name = Column(String(200), nullable=True)    # e.g. "Ananthapuram Range"
    is_active = Column(Boolean, default=True, nullable=False)
    sort_order = Column(Integer, default=0, nullable=False)

    created_at = Column(DateTime(timezone=True), default=_utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=_utcnow, onupdate=_utcnow, nullable=False)

    __table_args__ = (
        UniqueConstraint("state", "name", name="uq_district_state_name"),
    )

    # relationships
    sdpos = relationship("SDPO", back_populates="district", cascade="all, delete-orphan",
                         order_by="SDPO.sort_order")
    pincodes = relationship("Pincode", back_populates="district", cascade="all, delete-orphan",
                            order_by="Pincode.pincode")


class SDPO(Base):
    __tablename__ = "sdpos"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    district_id = Column(GUID(), ForeignKey("districts.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(200), nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    sort_order = Column(Integer, default=0, nullable=False)

    created_at = Column(DateTime(timezone=True), default=_utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=_utcnow, onupdate=_utcnow, nullable=False)

    __table_args__ = (
        UniqueConstraint("district_id", "name", name="uq_sdpo_district_name"),
    )

    district = relationship("District", back_populates="sdpos")
    circles = relationship("Circle", back_populates="sdpo", cascade="all, delete-orphan",
                           order_by="Circle.sort_order")


class Circle(Base):
    __tablename__ = "circles"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    sdpo_id = Column(GUID(), ForeignKey("sdpos.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(200), nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    sort_order = Column(Integer, default=0, nullable=False)

    created_at = Column(DateTime(timezone=True), default=_utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=_utcnow, onupdate=_utcnow, nullable=False)

    __table_args__ = (
        UniqueConstraint("sdpo_id", "name", name="uq_circle_sdpo_name"),
    )

    sdpo = relationship("SDPO", back_populates="circles")
    police_stations = relationship("PoliceStation", back_populates="circle", cascade="all, delete-orphan",
                                   order_by="PoliceStation.sort_order")


class PoliceStation(Base):
    __tablename__ = "police_stations"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    circle_id = Column(GUID(), ForeignKey("circles.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(300), nullable=False)
    station_code = Column(String(50), nullable=True)
    phone = Column(String(20), nullable=True)
    address = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    sort_order = Column(Integer, default=0, nullable=False)

    created_at = Column(DateTime(timezone=True), default=_utcnow, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=_utcnow, onupdate=_utcnow, nullable=False)

    __table_args__ = (
        UniqueConstraint("circle_id", "name", name="uq_station_circle_name"),
    )

    circle = relationship("Circle", back_populates="police_stations")


class Pincode(Base):
    __tablename__ = "pincodes"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    district_id = Column(GUID(), ForeignKey("districts.id", ondelete="CASCADE"), nullable=False, index=True)
    pincode = Column(String(10), nullable=False)
    area_name = Column(String(200), nullable=True)

    created_at = Column(DateTime(timezone=True), default=_utcnow, nullable=False)

    __table_args__ = (
        UniqueConstraint("district_id", "pincode", name="uq_pincode_district"),
    )

    district = relationship("District", back_populates="pincodes")

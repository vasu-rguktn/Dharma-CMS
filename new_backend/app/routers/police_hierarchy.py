"""
Router: POLICE GEOGRAPHY (dynamic, DB-backed)

Replaces the old static JSON file. Data lives in 5 tables:
  districts → sdpos → circles → police_stations   (4-level hierarchy)
  districts → pincodes                             (flat)

Includes:
  - Full CRUD for each level (police/admin only for writes)
  - Cascading dropdown lookups (public, no auth)
  - Full hierarchy tree endpoint
  - Search across all levels
  - Seed endpoint to load initial data from JSON files
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import List, Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.auth import AuthUser, PoliceUser
from app.core.database import get_session
from app.models.geography import District, SDPO, Circle, PoliceStation, Pincode
from app.schemas.geography import (
    DistrictCreate, DistrictUpdate, DistrictOut, DistrictWithHierarchyOut,
    SDPOCreate, SDPOUpdate, SDPOOut, SDPOWithCirclesOut,
    CircleCreate, CircleUpdate, CircleOut, CircleWithStationsOut,
    PoliceStationCreate, PoliceStationUpdate, PoliceStationOut,
    PincodeCreate, PincodeOut,
    SeedStatusOut,
)
from app.schemas.common import IDResponse, MessageResponse
from app.services.crud import create_row, get_row, list_rows, update_row, delete_row

router = APIRouter(prefix="/police-hierarchy", tags=["Police Hierarchy"])

# Path to seed data files
_data_dir = Path(__file__).resolve().parents[2] / "data"


# ═══════════════════════════════════════════════════════════════════════════════
#  FULL HIERARCHY (public — no auth needed for lookups)
# ═══════════════════════════════════════════════════════════════════════════════

@router.get("/full", summary="Full hierarchy tree")
async def get_full_hierarchy(session: AsyncSession = Depends(get_session)):
    """Return the complete district → SDPO → circle → station tree from DB."""
    stmt = (
        select(District)
        .options(
            selectinload(District.sdpos)
            .selectinload(SDPO.circles)
            .selectinload(Circle.police_stations)
        )
        .where(District.is_active == True)
        .order_by(District.sort_order, District.name)
    )
    result = await session.execute(stmt)
    districts = result.scalars().unique().all()
    return {"districts": [DistrictWithHierarchyOut.model_validate(d) for d in districts]}


# ═══════════════════════════════════════════════════════════════════════════════
#  CASCADING DROPDOWN LOOKUPS (public)
# ═══════════════════════════════════════════════════════════════════════════════

@router.get("/districts", summary="List all districts", response_model=List[DistrictOut])
async def list_districts(
    session: AsyncSession = Depends(get_session),
    active_only: bool = True,
):
    """Return all districts."""
    filters = [("is_active", "==", True)] if active_only else None
    return await list_rows(session, District, filters=filters, order_by="sort_order", descending=False, limit=200)


@router.get("/districts/names", summary="List district names only", response_model=List[str])
async def list_district_names(session: AsyncSession = Depends(get_session)):
    """Flat list of active district names (for simple dropdowns)."""
    stmt = select(District.name).where(District.is_active == True).order_by(District.sort_order, District.name)
    result = await session.execute(stmt)
    return list(result.scalars().all())


@router.get("/sdpos", summary="SDPOs for a district", response_model=List[SDPOOut])
async def list_sdpos_for_district(
    district: str = Query(..., description="District name"),
    session: AsyncSession = Depends(get_session),
):
    """Return SDPOs for the given district name."""
    dist = await _get_district_by_name(session, district)
    if not dist:
        return []
    return await list_rows(session, SDPO, filters=[("district_id", "==", dist.id), ("is_active", "==", True)],
                           order_by="sort_order", descending=False, limit=200)


@router.get("/circles", summary="Circles for an SDPO", response_model=List[CircleOut])
async def list_circles_for_sdpo(
    district: str = Query(..., description="District name"),
    sdpo: str = Query(..., description="SDPO name"),
    session: AsyncSession = Depends(get_session),
):
    """Return circles for the given district + SDPO."""
    sdpo_row = await _get_sdpo_by_name(session, district, sdpo)
    if not sdpo_row:
        return []
    return await list_rows(session, Circle, filters=[("sdpo_id", "==", sdpo_row.id), ("is_active", "==", True)],
                           order_by="sort_order", descending=False, limit=200)


@router.get("/stations", summary="Police stations for a circle", response_model=List[PoliceStationOut])
async def list_stations_for_circle(
    district: str = Query(..., description="District name"),
    sdpo: str = Query(..., description="SDPO name"),
    circle: str = Query(..., description="Circle name"),
    session: AsyncSession = Depends(get_session),
):
    """Return police stations for the given district + SDPO + circle."""
    circle_row = await _get_circle_by_name(session, district, sdpo, circle)
    if not circle_row:
        return []
    return await list_rows(session, PoliceStation,
                           filters=[("circle_id", "==", circle_row.id), ("is_active", "==", True)],
                           order_by="sort_order", descending=False, limit=500)


@router.get("/pincodes", summary="Pincodes for a district", response_model=List[PincodeOut])
async def list_pincodes_for_district(
    district: str = Query(..., description="District name"),
    session: AsyncSession = Depends(get_session),
):
    """Return pincodes for the given district."""
    dist = await _get_district_by_name(session, district)
    if not dist:
        return []
    return await list_rows(session, Pincode, filters=[("district_id", "==", dist.id)],
                           order_by="pincode", descending=False, limit=500)


@router.get("/search", summary="Search across all levels")
async def search_hierarchy(
    q: str = Query(..., min_length=2, description="Search term"),
    session: AsyncSession = Depends(get_session),
):
    """Search for districts, SDPOs, circles, or stations matching the query."""
    q_like = f"%{q}%"
    results: dict = {"districts": [], "sdpos": [], "circles": [], "stations": []}

    # Districts
    stmt = select(District.name).where(District.name.ilike(q_like), District.is_active == True)
    results["districts"] = list((await session.execute(stmt)).scalars().all())

    # SDPOs
    stmt = (
        select(SDPO.name, District.name.label("district"))
        .join(District, SDPO.district_id == District.id)
        .where(SDPO.name.ilike(q_like), SDPO.is_active == True)
    )
    results["sdpos"] = [{"name": r[0], "district": r[1]} for r in (await session.execute(stmt)).all()]

    # Circles
    stmt = (
        select(Circle.name, SDPO.name.label("sdpo"), District.name.label("district"))
        .join(SDPO, Circle.sdpo_id == SDPO.id)
        .join(District, SDPO.district_id == District.id)
        .where(Circle.name.ilike(q_like), Circle.is_active == True)
    )
    results["circles"] = [{"name": r[0], "sdpo": r[1], "district": r[2]} for r in (await session.execute(stmt)).all()]

    # Stations
    stmt = (
        select(PoliceStation.name, Circle.name.label("circle"),
               SDPO.name.label("sdpo"), District.name.label("district"))
        .join(Circle, PoliceStation.circle_id == Circle.id)
        .join(SDPO, Circle.sdpo_id == SDPO.id)
        .join(District, SDPO.district_id == District.id)
        .where(PoliceStation.name.ilike(q_like), PoliceStation.is_active == True)
    )
    results["stations"] = [{"name": r[0], "circle": r[1], "sdpo": r[2], "district": r[3]}
                           for r in (await session.execute(stmt)).all()]

    return results


# ═══════════════════════════════════════════════════════════════════════════════
#  CRUD — DISTRICTS (police/admin writes, public reads above)
# ═══════════════════════════════════════════════════════════════════════════════

@router.post("/districts", response_model=IDResponse, status_code=201)
async def create_district(body: DistrictCreate, user: PoliceUser, session: AsyncSession = Depends(get_session)):
    row = await create_row(session, District, body.model_dump(exclude_none=True))
    return IDResponse(id=row.id)


@router.get("/districts/{district_id}", response_model=DistrictWithHierarchyOut)
async def get_district(district_id: UUID, session: AsyncSession = Depends(get_session)):
    stmt = (
        select(District)
        .options(selectinload(District.sdpos).selectinload(SDPO.circles).selectinload(Circle.police_stations))
        .where(District.id == district_id)
    )
    result = await session.execute(stmt)
    d = result.scalar_one_or_none()
    if not d:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "District not found")
    return d


@router.patch("/districts/{district_id}", response_model=DistrictOut)
async def update_district(district_id: UUID, body: DistrictUpdate, user: PoliceUser,
                          session: AsyncSession = Depends(get_session)):
    return await update_row(session, District, district_id, body.model_dump(exclude_none=True))


@router.delete("/districts/{district_id}", response_model=MessageResponse)
async def delete_district(district_id: UUID, user: PoliceUser, session: AsyncSession = Depends(get_session)):
    await delete_row(session, District, district_id)
    return MessageResponse(message="District and all children deleted")


# ═══════════════════════════════════════════════════════════════════════════════
#  CRUD — SDPOs
# ═══════════════════════════════════════════════════════════════════════════════

@router.post("/districts/{district_id}/sdpos", response_model=IDResponse, status_code=201)
async def create_sdpo(district_id: UUID, body: SDPOCreate, user: PoliceUser,
                      session: AsyncSession = Depends(get_session)):
    await get_row(session, District, district_id)
    data = body.model_dump(exclude_none=True)
    data["district_id"] = district_id
    row = await create_row(session, SDPO, data)
    return IDResponse(id=row.id)


@router.get("/districts/{district_id}/sdpos", response_model=List[SDPOOut])
async def list_sdpos_by_district_id(district_id: UUID, session: AsyncSession = Depends(get_session)):
    return await list_rows(session, SDPO, filters=[("district_id", "==", district_id)],
                           order_by="sort_order", descending=False, limit=200)


@router.patch("/sdpos/{sdpo_id}", response_model=SDPOOut)
async def update_sdpo(sdpo_id: UUID, body: SDPOUpdate, user: PoliceUser,
                      session: AsyncSession = Depends(get_session)):
    return await update_row(session, SDPO, sdpo_id, body.model_dump(exclude_none=True))


@router.delete("/sdpos/{sdpo_id}", response_model=MessageResponse)
async def delete_sdpo(sdpo_id: UUID, user: PoliceUser, session: AsyncSession = Depends(get_session)):
    await delete_row(session, SDPO, sdpo_id)
    return MessageResponse(message="SDPO and all children deleted")


# ═══════════════════════════════════════════════════════════════════════════════
#  CRUD — CIRCLES
# ═══════════════════════════════════════════════════════════════════════════════

@router.post("/sdpos/{sdpo_id}/circles", response_model=IDResponse, status_code=201)
async def create_circle(sdpo_id: UUID, body: CircleCreate, user: PoliceUser,
                        session: AsyncSession = Depends(get_session)):
    await get_row(session, SDPO, sdpo_id)
    data = body.model_dump(exclude_none=True)
    data["sdpo_id"] = sdpo_id
    row = await create_row(session, Circle, data)
    return IDResponse(id=row.id)


@router.get("/sdpos/{sdpo_id}/circles", response_model=List[CircleOut])
async def list_circles_by_sdpo_id(sdpo_id: UUID, session: AsyncSession = Depends(get_session)):
    return await list_rows(session, Circle, filters=[("sdpo_id", "==", sdpo_id)],
                           order_by="sort_order", descending=False, limit=200)


@router.patch("/circles/{circle_id}", response_model=CircleOut)
async def update_circle(circle_id: UUID, body: CircleUpdate, user: PoliceUser,
                        session: AsyncSession = Depends(get_session)):
    return await update_row(session, Circle, circle_id, body.model_dump(exclude_none=True))


@router.delete("/circles/{circle_id}", response_model=MessageResponse)
async def delete_circle(circle_id: UUID, user: PoliceUser, session: AsyncSession = Depends(get_session)):
    await delete_row(session, Circle, circle_id)
    return MessageResponse(message="Circle and all stations deleted")


# ═══════════════════════════════════════════════════════════════════════════════
#  CRUD — POLICE STATIONS
# ═══════════════════════════════════════════════════════════════════════════════

@router.post("/circles/{circle_id}/stations", response_model=IDResponse, status_code=201)
async def create_station(circle_id: UUID, body: PoliceStationCreate, user: PoliceUser,
                         session: AsyncSession = Depends(get_session)):
    await get_row(session, Circle, circle_id)
    data = body.model_dump(exclude_none=True)
    data["circle_id"] = circle_id
    row = await create_row(session, PoliceStation, data)
    return IDResponse(id=row.id)


@router.get("/circles/{circle_id}/stations", response_model=List[PoliceStationOut])
async def list_stations_by_circle_id(circle_id: UUID, session: AsyncSession = Depends(get_session)):
    return await list_rows(session, PoliceStation, filters=[("circle_id", "==", circle_id)],
                           order_by="sort_order", descending=False, limit=500)


@router.patch("/stations/{station_id}", response_model=PoliceStationOut)
async def update_station(station_id: UUID, body: PoliceStationUpdate, user: PoliceUser,
                         session: AsyncSession = Depends(get_session)):
    return await update_row(session, PoliceStation, station_id, body.model_dump(exclude_none=True))


@router.delete("/stations/{station_id}", response_model=MessageResponse)
async def delete_station(station_id: UUID, user: PoliceUser, session: AsyncSession = Depends(get_session)):
    await delete_row(session, PoliceStation, station_id)
    return MessageResponse(message="Police station deleted")


# ═══════════════════════════════════════════════════════════════════════════════
#  CRUD — PINCODES
# ═══════════════════════════════════════════════════════════════════════════════

@router.post("/districts/{district_id}/pincodes", response_model=IDResponse, status_code=201)
async def create_pincode(district_id: UUID, body: PincodeCreate, user: PoliceUser,
                         session: AsyncSession = Depends(get_session)):
    await get_row(session, District, district_id)
    data = body.model_dump(exclude_none=True)
    data["district_id"] = district_id
    row = await create_row(session, Pincode, data)
    return IDResponse(id=row.id)


@router.get("/districts/{district_id}/pincodes", response_model=List[PincodeOut])
async def list_pincodes_by_district_id(district_id: UUID, session: AsyncSession = Depends(get_session)):
    return await list_rows(session, Pincode, filters=[("district_id", "==", district_id)],
                           order_by="pincode", descending=False, limit=500)


@router.delete("/pincodes/{pincode_id}", response_model=MessageResponse)
async def delete_pincode(pincode_id: UUID, user: PoliceUser, session: AsyncSession = Depends(get_session)):
    await delete_row(session, Pincode, pincode_id)
    return MessageResponse(message="Pincode deleted")


# ═══════════════════════════════════════════════════════════════════════════════
#  SEED — Load initial data from JSON files into DB
# ═══════════════════════════════════════════════════════════════════════════════

@router.get("/seed/status", summary="Check if data is seeded", response_model=SeedStatusOut)
async def seed_status(session: AsyncSession = Depends(get_session)):
    """Check how many rows exist in each geography table."""
    d = (await session.execute(select(func.count()).select_from(District))).scalar_one()
    s = (await session.execute(select(func.count()).select_from(SDPO))).scalar_one()
    c = (await session.execute(select(func.count()).select_from(Circle))).scalar_one()
    ps = (await session.execute(select(func.count()).select_from(PoliceStation))).scalar_one()
    p = (await session.execute(select(func.count()).select_from(Pincode))).scalar_one()
    return SeedStatusOut(
        districts=d, sdpos=s, circles=c, police_stations=ps, pincodes=p,
        message="Data present" if d > 0 else "Empty — call POST /police-hierarchy/seed to load"
    )


@router.post("/seed", summary="Seed hierarchy + pincodes from JSON files", response_model=SeedStatusOut)
async def seed_from_json(
    user: PoliceUser,
    session: AsyncSession = Depends(get_session),
    force: bool = Query(False, description="Drop existing data and re-seed"),
):
    """
    Load district→SDPO→circle→station hierarchy and pincodes from JSON files.
    Only runs if tables are empty (or force=true).
    """
    existing = (await session.execute(select(func.count()).select_from(District))).scalar_one()
    if existing > 0 and not force:
        raise HTTPException(status.HTTP_409_CONFLICT,
                            f"Already seeded ({existing} districts). Use ?force=true to re-seed.")

    if force and existing > 0:
        await session.execute(District.__table__.delete())
        await session.execute(Pincode.__table__.delete())
        await session.flush()

    counts = await _do_seed(session)
    return counts


async def _do_seed(session: AsyncSession) -> SeedStatusOut:
    """Internal: parse JSON files and insert rows."""
    d_count = s_count = c_count = ps_count = pin_count = 0

    # ── Hierarchy ──
    hierarchy_path = _data_dir / "ap_police_hierarchy.json"
    if hierarchy_path.exists():
        data = json.loads(hierarchy_path.read_text(encoding="utf-8"))
        for d_idx, d_data in enumerate(data.get("districts", [])):
            district = District(name=d_data["name"], sort_order=d_idx)
            session.add(district)
            await session.flush()
            d_count += 1

            for s_idx, s_data in enumerate(d_data.get("sdpos", [])):
                sdpo = SDPO(district_id=district.id, name=s_data["name"], sort_order=s_idx)
                session.add(sdpo)
                await session.flush()
                s_count += 1

                for c_idx, c_data in enumerate(s_data.get("circles", [])):
                    circle = Circle(sdpo_id=sdpo.id, name=c_data["name"], sort_order=c_idx)
                    session.add(circle)
                    await session.flush()
                    c_count += 1

                    for ps_idx, ps_name in enumerate(c_data.get("police_stations", [])):
                        station = PoliceStation(circle_id=circle.id, name=ps_name, sort_order=ps_idx)
                        session.add(station)
                        ps_count += 1

            await session.flush()

    # ── Build a lookup of all seeded districts (lowercase → row) ──
    all_districts = (await session.execute(select(District))).scalars().all()
    dist_by_lower = {d.name.lower(): d for d in all_districts}

    # Alias map: pincode JSON name (lower) → hierarchy name (lower)
    # Covers known mismatches between the two JSON files
    _PINCODE_ALIASES: dict[str, str] = {
        "anantapur": "ananthapuram",
        "spsr nellore": "sri potti sriramulu nellore",
        "tirupati": "tirupathi",
        "visakhapatanam": "visakhapatnam commissionerate",
        "y.s.r.": "ysr",
    }

    def _find_district(name: str):
        """Try exact, alias, then substring match."""
        key = name.lower()
        # 1. Exact
        if key in dist_by_lower:
            return dist_by_lower[key]
        # 2. Alias
        alias = _PINCODE_ALIASES.get(key)
        if alias and alias in dist_by_lower:
            return dist_by_lower[alias]
        # 3. Substring (either direction)
        for db_key, db_row in dist_by_lower.items():
            if key in db_key or db_key in key:
                return db_row
        return None

    # ── Pincodes ──
    pincodes_path = _data_dir / "pincodes.json"
    if pincodes_path.exists():
        pin_data = json.loads(pincodes_path.read_text(encoding="utf-8"))
        unmatched = []
        for dist_name, pins in pin_data.items():
            dist_row = _find_district(dist_name)
            if dist_row:
                for pin in pins:
                    session.add(Pincode(district_id=dist_row.id, pincode=str(pin)))
                    pin_count += 1
                await session.flush()
            else:
                unmatched.append(dist_name)
        if unmatched:
            print(f"⚠️  Pincode districts not matched to hierarchy: {unmatched}")

    return SeedStatusOut(
        districts=d_count, sdpos=s_count, circles=c_count,
        police_stations=ps_count, pincodes=pin_count,
        message=f"Seeded {d_count} districts, {s_count} SDPOs, {c_count} circles, {ps_count} stations, {pin_count} pincodes"
    )


# ═══════════════════════════════════════════════════════════════════════════════
#  INTERNAL HELPERS
# ═══════════════════════════════════════════════════════════════════════════════

async def _get_district_by_name(session: AsyncSession, name: str) -> District | None:
    stmt = select(District).where(func.lower(District.name) == name.lower(), District.is_active == True)
    result = await session.execute(stmt)
    return result.scalar_one_or_none()


async def _get_sdpo_by_name(session: AsyncSession, district_name: str, sdpo_name: str) -> SDPO | None:
    dist = await _get_district_by_name(session, district_name)
    if not dist:
        return None
    stmt = select(SDPO).where(SDPO.district_id == dist.id, func.lower(SDPO.name) == sdpo_name.lower(), SDPO.is_active == True)
    result = await session.execute(stmt)
    return result.scalar_one_or_none()


async def _get_circle_by_name(session: AsyncSession, district_name: str, sdpo_name: str, circle_name: str) -> Circle | None:
    sdpo = await _get_sdpo_by_name(session, district_name, sdpo_name)
    if not sdpo:
        return None
    stmt = select(Circle).where(Circle.sdpo_id == sdpo.id, func.lower(Circle.name) == circle_name.lower(), Circle.is_active == True)
    result = await session.execute(stmt)
    return result.scalar_one_or_none()

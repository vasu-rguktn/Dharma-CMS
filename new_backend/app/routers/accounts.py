"""
Router: ACCOUNTS, CITIZEN_PROFILES, POLICE_PROFILES, DEVICE_TOKENS
All data via PostgreSQL.
"""

from fastapi import APIRouter, Depends
from typing import List
from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import AuthUser, PoliceUser
from app.core.database import get_session
from app.models.accounts import Account, CitizenProfile, PoliceProfile, DeviceToken
from app.schemas.accounts import (
    AccountCreate, AccountUpdate, AccountOut,
    CitizenProfileCreate, CitizenProfileUpdate, CitizenProfileOut,
    PoliceProfileCreate, PoliceProfileUpdate, PoliceProfileOut,
    DeviceTokenCreate, DeviceTokenOut,
)
from app.schemas.common import IDResponse, MessageResponse
from app.services.crud import (
    create_row, get_row, get_row_by_field, list_rows, update_row, delete_row,
)

router = APIRouter(prefix="/accounts", tags=["Accounts"])


# ═══════════════════════════════════════════════════════════════════════════
#  ACCOUNT
# ═══════════════════════════════════════════════════════════════════════════

@router.post("", response_model=IDResponse, status_code=201)
async def create_account(
    body: AccountCreate,
    user: AuthUser,
    session: AsyncSession = Depends(get_session),
):
    """Create or initialise the caller's account row."""
    # Check if account already exists for this firebase_uid
    existing = await get_row_by_field(session, Account, "firebase_uid", user.uid)
    if existing:
        return IDResponse(id=existing.id, message="Account already exists")

    data = body.model_dump(exclude_none=True)
    data["firebase_uid"] = user.uid
    row = await create_row(session, Account, data)
    return IDResponse(id=row.id)


@router.get("/me", response_model=AccountOut)
async def get_my_account(
    user: AuthUser,
    session: AsyncSession = Depends(get_session),
):
    row = await get_row_by_field(session, Account, "firebase_uid", user.uid)
    if not row:
        from fastapi import HTTPException, status
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Account not found. Create one first.")
    return row


@router.patch("/me", response_model=AccountOut)
async def update_my_account(
    body: AccountUpdate,
    user: AuthUser,
    session: AsyncSession = Depends(get_session),
):
    account = await get_row_by_field(session, Account, "firebase_uid", user.uid)
    if not account:
        from fastapi import HTTPException, status
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Account not found.")
    return await update_row(session, Account, account.id, body.model_dump(exclude_none=True))


@router.get("/{account_id}", response_model=AccountOut)
async def get_account(
    account_id: UUID,
    user: PoliceUser,
    session: AsyncSession = Depends(get_session),
):
    """Police can look up any account."""
    return await get_row(session, Account, account_id)


@router.get("", response_model=List[AccountOut])
async def list_accounts(
    user: PoliceUser,
    session: AsyncSession = Depends(get_session),
    limit: int = 100,
    offset: int = 0,
):
    """Police: list all accounts."""
    return await list_rows(session, Account, limit=limit, offset=offset)


# ═══════════════════════════════════════════════════════════════════════════
#  CITIZEN PROFILE
# ═══════════════════════════════════════════════════════════════════════════

async def _get_my_account_id(user: AuthUser, session: AsyncSession) -> UUID:
    account = await get_row_by_field(session, Account, "firebase_uid", user.uid)
    if not account:
        from fastapi import HTTPException, status
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Account not found. Create one first.")
    return account.id


@router.post("/me/citizen-profile", response_model=IDResponse, status_code=201)
async def create_citizen_profile(
    body: CitizenProfileCreate,
    user: AuthUser,
    session: AsyncSession = Depends(get_session),
):
    account_id = await _get_my_account_id(user, session)
    existing = await get_row_by_field(session, CitizenProfile, "account_id", account_id)
    if existing:
        return IDResponse(id=existing.id, message="Citizen profile already exists")
    data = body.model_dump(exclude_none=True)
    data["account_id"] = account_id
    row = await create_row(session, CitizenProfile, data)
    return IDResponse(id=row.id)


@router.get("/me/citizen-profile", response_model=CitizenProfileOut)
async def get_my_citizen_profile(
    user: AuthUser,
    session: AsyncSession = Depends(get_session),
):
    account_id = await _get_my_account_id(user, session)
    row = await get_row_by_field(session, CitizenProfile, "account_id", account_id)
    if not row:
        from fastapi import HTTPException, status
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Citizen profile not found.")
    return row


@router.patch("/me/citizen-profile", response_model=CitizenProfileOut)
async def update_my_citizen_profile(
    body: CitizenProfileUpdate,
    user: AuthUser,
    session: AsyncSession = Depends(get_session),
):
    account_id = await _get_my_account_id(user, session)
    row = await get_row_by_field(session, CitizenProfile, "account_id", account_id)
    if not row:
        from fastapi import HTTPException, status
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Citizen profile not found.")
    return await update_row(session, CitizenProfile, row.id, body.model_dump(exclude_none=True))


@router.get("/{account_id}/citizen-profile", response_model=CitizenProfileOut)
async def get_citizen_profile(
    account_id: UUID,
    user: PoliceUser,
    session: AsyncSession = Depends(get_session),
):
    row = await get_row_by_field(session, CitizenProfile, "account_id", account_id)
    if not row:
        from fastapi import HTTPException, status
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Citizen profile not found.")
    return row


# ═══════════════════════════════════════════════════════════════════════════
#  POLICE PROFILE
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/me/police-profile", response_model=IDResponse, status_code=201)
async def create_police_profile(
    body: PoliceProfileCreate,
    user: AuthUser,
    session: AsyncSession = Depends(get_session),
):
    account_id = await _get_my_account_id(user, session)
    existing = await get_row_by_field(session, PoliceProfile, "account_id", account_id)
    if existing:
        return IDResponse(id=existing.id, message="Police profile already exists")
    data = body.model_dump(exclude_none=True)
    data["account_id"] = account_id
    row = await create_row(session, PoliceProfile, data)
    return IDResponse(id=row.id)


@router.get("/me/police-profile", response_model=PoliceProfileOut)
async def get_my_police_profile(
    user: AuthUser,
    session: AsyncSession = Depends(get_session),
):
    account_id = await _get_my_account_id(user, session)
    row = await get_row_by_field(session, PoliceProfile, "account_id", account_id)
    if not row:
        from fastapi import HTTPException, status
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Police profile not found.")
    return row


@router.patch("/me/police-profile", response_model=PoliceProfileOut)
async def update_my_police_profile(
    body: PoliceProfileUpdate,
    user: AuthUser,
    session: AsyncSession = Depends(get_session),
):
    account_id = await _get_my_account_id(user, session)
    row = await get_row_by_field(session, PoliceProfile, "account_id", account_id)
    if not row:
        from fastapi import HTTPException, status
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Police profile not found.")
    return await update_row(session, PoliceProfile, row.id, body.model_dump(exclude_none=True))


@router.get("/{account_id}/police-profile", response_model=PoliceProfileOut)
async def get_police_profile(
    account_id: UUID,
    user: PoliceUser,
    session: AsyncSession = Depends(get_session),
):
    row = await get_row_by_field(session, PoliceProfile, "account_id", account_id)
    if not row:
        from fastapi import HTTPException, status
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Police profile not found.")
    return row


@router.get("/police-profiles/all", response_model=List[PoliceProfileOut])
async def list_police_profiles(
    user: PoliceUser,
    session: AsyncSession = Depends(get_session),
    limit: int = 100,
    offset: int = 0,
):
    return await list_rows(session, PoliceProfile, limit=limit, offset=offset)


# ═══════════════════════════════════════════════════════════════════════════
#  DEVICE TOKENS
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/me/device-tokens", response_model=IDResponse, status_code=201)
async def register_device_token(
    body: DeviceTokenCreate,
    user: AuthUser,
    session: AsyncSession = Depends(get_session),
):
    account_id = await _get_my_account_id(user, session)
    data = body.model_dump(exclude_none=True)
    data["account_id"] = account_id
    row = await create_row(session, DeviceToken, data)
    return IDResponse(id=row.id)


@router.get("/me/device-tokens", response_model=List[DeviceTokenOut])
async def list_my_device_tokens(
    user: AuthUser,
    session: AsyncSession = Depends(get_session),
):
    account_id = await _get_my_account_id(user, session)
    return await list_rows(
        session, DeviceToken,
        filters=[("account_id", "==", account_id)],
        limit=20,
    )


@router.delete("/me/device-tokens/{token_id}", response_model=MessageResponse)
async def delete_device_token(
    token_id: UUID,
    user: AuthUser,
    session: AsyncSession = Depends(get_session),
):
    account_id = await _get_my_account_id(user, session)
    row = await get_row(session, DeviceToken, token_id)
    if row.account_id != account_id:
        from fastapi import HTTPException, status
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Not your device token.")
    await delete_row(session, DeviceToken, token_id)
    return MessageResponse(message="Device token deleted")

"""
Router: PETITIONS and sub-tables
  PETITION_ASSIGNMENTS, PETITION_ATTACHMENTS,
  PETITION_UPDATES (+ PETITION_UPDATE_ATTACHMENTS),
  PETITION_SAVES.

All data via PostgreSQL — flat relational tables, no nesting.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import AuthUser, PoliceUser
from app.core.database import get_session
from app.models.accounts import Account
from app.models.petitions import (
    Petition, PetitionAssignment, PetitionAttachment,
    PetitionUpdate, PetitionUpdateAttachment, PetitionSave,
)
from app.schemas.petitions import (
    PetitionCreate, PetitionUpdate as PetitionUpdateSchema, PetitionOut,
    PetitionAssignmentCreate, PetitionAssignmentOut,
    PetitionAttachmentCreate, PetitionAttachmentOut,
    PetitionUpdateCreate, PetitionUpdateOut,
    PetitionUpdateAttachmentCreate, PetitionUpdateAttachmentOut,
    PetitionSaveCreate, PetitionSaveOut,
)
from app.schemas.common import IDResponse, MessageResponse
from app.services.crud import (
    create_row, get_row, get_row_by_field, list_rows, update_row, delete_row, count_rows,
)

router = APIRouter(tags=["Petitions"])


async def _account_id_for_uid(session: AsyncSession, firebase_uid: str) -> UUID:
    account = await get_row_by_field(session, Account, "firebase_uid", firebase_uid)
    if not account:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Account not found.")
    return account.id


# ═══════════════════════════════════════════════════════════════════════════
#  PETITIONS
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/petitions", response_model=IDResponse, status_code=201)
async def create_petition(
    body: PetitionCreate, user: AuthUser,
    session: AsyncSession = Depends(get_session),
):
    account_id = await _account_id_for_uid(session, user.uid)
    data = body.model_dump(exclude_none=True)
    data["created_by_account_id"] = account_id
    data["submitted_by_account_id"] = account_id
    row = await create_row(session, Petition, data)
    return IDResponse(id=row.id)


@router.get("/petitions", response_model=List[PetitionOut])
async def list_my_petitions(
    user: AuthUser, session: AsyncSession = Depends(get_session),
    limit: int = 50, offset: int = 0, status_filter: Optional[str] = None,
):
    account_id = await _account_id_for_uid(session, user.uid)
    filters = [("created_by_account_id", "==", account_id)]
    if status_filter:
        filters.append(("lifecycle_status", "==", status_filter))
    return await list_rows(session, Petition, filters=filters, limit=limit, offset=offset)


@router.get("/petitions/all", response_model=List[PetitionOut])
async def list_all_petitions(
    user: PoliceUser, session: AsyncSession = Depends(get_session),
    limit: int = 50, offset: int = 0, status_filter: Optional[str] = None,
):
    filters = []
    if status_filter:
        filters.append(("lifecycle_status", "==", status_filter))
    return await list_rows(session, Petition, filters=filters or None, limit=limit, offset=offset)


@router.get("/petitions/stats")
async def petition_stats(user: AuthUser, session: AsyncSession = Depends(get_session)):
    account_id = await _account_id_for_uid(session, user.uid)
    base = [("created_by_account_id", "==", account_id)]
    total = await count_rows(session, Petition, filters=base)
    submitted = await count_rows(session, Petition, filters=base + [("lifecycle_status", "==", "submitted")])
    in_progress = await count_rows(session, Petition, filters=base + [("lifecycle_status", "==", "in_progress")])
    resolved = await count_rows(session, Petition, filters=base + [("lifecycle_status", "==", "resolved")])
    return {"total": total, "submitted": submitted, "in_progress": in_progress, "resolved": resolved}


@router.get("/petitions/{petition_id}", response_model=PetitionOut)
async def get_petition(petition_id: UUID, user: AuthUser, session: AsyncSession = Depends(get_session)):
    row = await get_row(session, Petition, petition_id)
    if not user.is_police:
        account_id = await _account_id_for_uid(session, user.uid)
        if row.created_by_account_id != account_id:
            raise HTTPException(status.HTTP_403_FORBIDDEN, "Access denied.")
    return row


@router.patch("/petitions/{petition_id}", response_model=PetitionOut)
async def update_petition(
    petition_id: UUID, body: PetitionUpdateSchema, user: AuthUser,
    session: AsyncSession = Depends(get_session),
):
    row = await get_row(session, Petition, petition_id)
    if not user.is_police:
        account_id = await _account_id_for_uid(session, user.uid)
        if row.created_by_account_id != account_id:
            raise HTTPException(status.HTTP_403_FORBIDDEN, "Access denied.")
    return await update_row(session, Petition, petition_id, body.model_dump(exclude_none=True))


@router.delete("/petitions/{petition_id}", response_model=MessageResponse)
async def delete_petition(petition_id: UUID, user: AuthUser, session: AsyncSession = Depends(get_session)):
    row = await get_row(session, Petition, petition_id)
    if not user.is_police:
        account_id = await _account_id_for_uid(session, user.uid)
        if row.created_by_account_id != account_id:
            raise HTTPException(status.HTTP_403_FORBIDDEN, "Access denied.")
    await delete_row(session, Petition, petition_id)
    return MessageResponse(message="Petition deleted")


# ═══════════════════════════════════════════════════════════════════════════
#  PETITION ASSIGNMENTS
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/petitions/{petition_id}/assignments", response_model=IDResponse, status_code=201)
async def create_assignment(
    petition_id: UUID, body: PetitionAssignmentCreate, user: PoliceUser,
    session: AsyncSession = Depends(get_session),
):
    await get_row(session, Petition, petition_id)
    account_id = await _account_id_for_uid(session, user.uid)
    data = body.model_dump(exclude_none=True)
    data["petition_id"] = petition_id
    data["assigned_by_account_id"] = account_id
    row = await create_row(session, PetitionAssignment, data)
    return IDResponse(id=row.id)


@router.get("/petitions/{petition_id}/assignments", response_model=List[PetitionAssignmentOut])
async def list_assignments(petition_id: UUID, user: AuthUser, session: AsyncSession = Depends(get_session)):
    return await list_rows(session, PetitionAssignment, filters=[("petition_id", "==", petition_id)])


@router.delete("/petitions/{petition_id}/assignments/{assignment_id}", response_model=MessageResponse)
async def delete_assignment(petition_id: UUID, assignment_id: UUID, user: PoliceUser, session: AsyncSession = Depends(get_session)):
    await delete_row(session, PetitionAssignment, assignment_id)
    return MessageResponse(message="Assignment deleted")


# ═══════════════════════════════════════════════════════════════════════════
#  PETITION ATTACHMENTS
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/petitions/{petition_id}/attachments", response_model=IDResponse, status_code=201)
async def create_attachment(
    petition_id: UUID, body: PetitionAttachmentCreate, user: AuthUser,
    session: AsyncSession = Depends(get_session),
):
    await get_row(session, Petition, petition_id)
    account_id = await _account_id_for_uid(session, user.uid)
    data = body.model_dump(exclude_none=True)
    data["petition_id"] = petition_id
    data["uploaded_by_account_id"] = account_id
    row = await create_row(session, PetitionAttachment, data)
    return IDResponse(id=row.id)


@router.get("/petitions/{petition_id}/attachments", response_model=List[PetitionAttachmentOut])
async def list_attachments(petition_id: UUID, user: AuthUser, session: AsyncSession = Depends(get_session)):
    return await list_rows(session, PetitionAttachment, filters=[("petition_id", "==", petition_id)])


@router.delete("/petitions/{petition_id}/attachments/{attachment_id}", response_model=MessageResponse)
async def delete_attachment(petition_id: UUID, attachment_id: UUID, user: AuthUser, session: AsyncSession = Depends(get_session)):
    petition = await get_row(session, Petition, petition_id)
    if not user.is_police:
        account_id = await _account_id_for_uid(session, user.uid)
        if petition.created_by_account_id != account_id:
            raise HTTPException(status.HTTP_403_FORBIDDEN, "Access denied.")
    await delete_row(session, PetitionAttachment, attachment_id)
    return MessageResponse(message="Attachment deleted")


# ═══════════════════════════════════════════════════════════════════════════
#  PETITION UPDATES
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/petitions/{petition_id}/updates", response_model=IDResponse, status_code=201)
async def create_petition_update(
    petition_id: UUID, body: PetitionUpdateCreate, user: AuthUser,
    session: AsyncSession = Depends(get_session),
):
    await get_row(session, Petition, petition_id)
    account_id = await _account_id_for_uid(session, user.uid)
    data = body.model_dump(exclude_none=True)
    data["petition_id"] = petition_id
    data["added_by_account_id"] = account_id
    row = await create_row(session, PetitionUpdate, data)
    return IDResponse(id=row.id)


@router.get("/petitions/{petition_id}/updates", response_model=List[PetitionUpdateOut])
async def list_petition_updates(petition_id: UUID, user: AuthUser, session: AsyncSession = Depends(get_session)):
    return await list_rows(session, PetitionUpdate, filters=[("petition_id", "==", petition_id)])


# ── UPDATE ATTACHMENTS ───────────────────────────────────────────────────

@router.post("/petitions/{petition_id}/updates/{update_id}/attachments", response_model=IDResponse, status_code=201)
async def create_update_attachment(
    petition_id: UUID, update_id: UUID, body: PetitionUpdateAttachmentCreate,
    user: AuthUser, session: AsyncSession = Depends(get_session),
):
    data = body.model_dump(exclude_none=True)
    data["petition_update_id"] = update_id
    row = await create_row(session, PetitionUpdateAttachment, data)
    return IDResponse(id=row.id)


@router.get("/petitions/{petition_id}/updates/{update_id}/attachments", response_model=List[PetitionUpdateAttachmentOut])
async def list_update_attachments(
    petition_id: UUID, update_id: UUID, user: AuthUser,
    session: AsyncSession = Depends(get_session),
):
    return await list_rows(session, PetitionUpdateAttachment, filters=[("petition_update_id", "==", update_id)])


# ═══════════════════════════════════════════════════════════════════════════
#  PETITION SAVES (bookmarks)
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/petition-saves", response_model=IDResponse, status_code=201)
async def save_petition(body: PetitionSaveCreate, user: AuthUser, session: AsyncSession = Depends(get_session)):
    account_id = await _account_id_for_uid(session, user.uid)
    data = body.model_dump(exclude_none=True)
    data["account_id"] = account_id
    row = await create_row(session, PetitionSave, data)
    return IDResponse(id=row.id)


@router.get("/petition-saves", response_model=List[PetitionSaveOut])
async def list_saved_petitions(user: AuthUser, session: AsyncSession = Depends(get_session)):
    account_id = await _account_id_for_uid(session, user.uid)
    return await list_rows(session, PetitionSave, filters=[("account_id", "==", account_id)])


@router.delete("/petition-saves/{save_id}", response_model=MessageResponse)
async def unsave_petition(save_id: UUID, user: AuthUser, session: AsyncSession = Depends(get_session)):
    account_id = await _account_id_for_uid(session, user.uid)
    row = await get_row(session, PetitionSave, save_id)
    if row.account_id != account_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Not your bookmark.")
    await delete_row(session, PetitionSave, save_id)
    return MessageResponse(message="Petition unsaved")

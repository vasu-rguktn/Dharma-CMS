"""
Router: COMPLAINT_DRAFTS and COMPLAINT_DRAFT_MESSAGES
All data via PostgreSQL.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import AuthUser
from app.core.database import get_session
from app.models.accounts import Account
from app.models.complaint_drafts import ComplaintDraft, ComplaintDraftMessage
from app.schemas.complaint_drafts import (
    ComplaintDraftCreate, ComplaintDraftUpdate, ComplaintDraftOut,
    ComplaintDraftMessageCreate, ComplaintDraftMessageOut,
)
from app.schemas.common import IDResponse, MessageResponse
from app.services.crud import (
    create_row, get_row, get_row_by_field, list_rows, update_row, delete_row,
)

router = APIRouter(tags=["Complaint Drafts"])


async def _account_id_for_uid(session: AsyncSession, firebase_uid: str) -> UUID:
    account = await get_row_by_field(session, Account, "firebase_uid", firebase_uid)
    if not account:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Account not found.")
    return account.id


# ═══════════════════════════════════════════════════════════════════════════
#  COMPLAINT DRAFTS
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/complaint-drafts", response_model=IDResponse, status_code=201)
async def create_draft(body: ComplaintDraftCreate, user: AuthUser, session: AsyncSession = Depends(get_session)):
    account_id = await _account_id_for_uid(session, user.uid)
    data = body.model_dump(exclude_none=True)
    data["created_by_account_id"] = account_id
    row = await create_row(session, ComplaintDraft, data)
    return IDResponse(id=row.id)


@router.get("/complaint-drafts", response_model=List[ComplaintDraftOut])
async def list_drafts(user: AuthUser, session: AsyncSession = Depends(get_session)):
    account_id = await _account_id_for_uid(session, user.uid)
    return await list_rows(session, ComplaintDraft, filters=[("created_by_account_id", "==", account_id)])


@router.get("/complaint-drafts/{draft_id}", response_model=ComplaintDraftOut)
async def get_draft(draft_id: UUID, user: AuthUser, session: AsyncSession = Depends(get_session)):
    row = await get_row(session, ComplaintDraft, draft_id)
    account_id = await _account_id_for_uid(session, user.uid)
    if row.created_by_account_id != account_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Access denied.")
    return row


@router.patch("/complaint-drafts/{draft_id}", response_model=ComplaintDraftOut)
async def update_draft(draft_id: UUID, body: ComplaintDraftUpdate, user: AuthUser, session: AsyncSession = Depends(get_session)):
    row = await get_row(session, ComplaintDraft, draft_id)
    account_id = await _account_id_for_uid(session, user.uid)
    if row.created_by_account_id != account_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Access denied.")
    return await update_row(session, ComplaintDraft, draft_id, body.model_dump(exclude_none=True))


@router.delete("/complaint-drafts/{draft_id}", response_model=MessageResponse)
async def delete_draft(draft_id: UUID, user: AuthUser, session: AsyncSession = Depends(get_session)):
    row = await get_row(session, ComplaintDraft, draft_id)
    account_id = await _account_id_for_uid(session, user.uid)
    if row.created_by_account_id != account_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Access denied.")
    await delete_row(session, ComplaintDraft, draft_id)
    return MessageResponse(message="Draft deleted")


# ═══════════════════════════════════════════════════════════════════════════
#  COMPLAINT DRAFT MESSAGES
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/complaint-drafts/{draft_id}/messages", response_model=IDResponse, status_code=201)
async def add_message(draft_id: UUID, body: ComplaintDraftMessageCreate, user: AuthUser, session: AsyncSession = Depends(get_session)):
    row = await get_row(session, ComplaintDraft, draft_id)
    account_id = await _account_id_for_uid(session, user.uid)
    if row.created_by_account_id != account_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Access denied.")
    data = body.model_dump(exclude_none=True)
    data["draft_id"] = draft_id
    msg = await create_row(session, ComplaintDraftMessage, data)
    return IDResponse(id=msg.id)


@router.get("/complaint-drafts/{draft_id}/messages", response_model=List[ComplaintDraftMessageOut])
async def list_messages(draft_id: UUID, user: AuthUser, session: AsyncSession = Depends(get_session)):
    row = await get_row(session, ComplaintDraft, draft_id)
    account_id = await _account_id_for_uid(session, user.uid)
    if row.created_by_account_id != account_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Access denied.")
    return await list_rows(
        session, ComplaintDraftMessage,
        filters=[("draft_id", "==", draft_id)],
        order_by="created_at", descending=False,
    )


@router.delete("/complaint-drafts/{draft_id}/messages/{message_id}", response_model=MessageResponse)
async def delete_message(draft_id: UUID, message_id: UUID, user: AuthUser, session: AsyncSession = Depends(get_session)):
    row = await get_row(session, ComplaintDraft, draft_id)
    account_id = await _account_id_for_uid(session, user.uid)
    if row.created_by_account_id != account_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Access denied.")
    await delete_row(session, ComplaintDraftMessage, message_id)
    return MessageResponse(message="Message deleted")

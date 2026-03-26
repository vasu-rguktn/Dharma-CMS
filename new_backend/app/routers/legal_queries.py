"""
Router: LEGAL_QUERY_THREADS and LEGAL_QUERY_MESSAGES
All data via PostgreSQL.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import AuthUser
from app.core.database import get_session
from app.models.accounts import Account
from app.models.legal_queries import LegalQueryThread, LegalQueryMessage
from app.schemas.legal_queries import (
    LegalQueryThreadCreate, LegalQueryThreadUpdate, LegalQueryThreadOut,
    LegalQueryMessageCreate, LegalQueryMessageOut,
)
from app.schemas.common import IDResponse, MessageResponse
from app.services.crud import (
    create_row, get_row, get_row_by_field, list_rows, update_row, delete_row,
)

router = APIRouter(tags=["Legal Queries"])


async def _account_id_for_uid(session: AsyncSession, firebase_uid: str) -> UUID:
    account = await get_row_by_field(session, Account, "firebase_uid", firebase_uid)
    if not account:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Account not found.")
    return account.id


# ═══════════════════════════════════════════════════════════════════════════
#  LEGAL QUERY THREADS
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/legal-threads", response_model=IDResponse, status_code=201)
async def create_thread(body: LegalQueryThreadCreate, user: AuthUser, session: AsyncSession = Depends(get_session)):
    account_id = await _account_id_for_uid(session, user.uid)
    data = body.model_dump(exclude_none=True)
    data["account_id"] = account_id
    row = await create_row(session, LegalQueryThread, data)
    return IDResponse(id=row.id)


@router.get("/legal-threads", response_model=List[LegalQueryThreadOut])
async def list_threads(user: AuthUser, session: AsyncSession = Depends(get_session)):
    account_id = await _account_id_for_uid(session, user.uid)
    return await list_rows(session, LegalQueryThread, filters=[("account_id", "==", account_id)])


@router.get("/legal-threads/{thread_id}", response_model=LegalQueryThreadOut)
async def get_thread(thread_id: UUID, user: AuthUser, session: AsyncSession = Depends(get_session)):
    row = await get_row(session, LegalQueryThread, thread_id)
    account_id = await _account_id_for_uid(session, user.uid)
    if row.account_id != account_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Access denied.")
    return row


@router.patch("/legal-threads/{thread_id}", response_model=LegalQueryThreadOut)
async def update_thread(thread_id: UUID, body: LegalQueryThreadUpdate, user: AuthUser, session: AsyncSession = Depends(get_session)):
    row = await get_row(session, LegalQueryThread, thread_id)
    account_id = await _account_id_for_uid(session, user.uid)
    if row.account_id != account_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Access denied.")
    return await update_row(session, LegalQueryThread, thread_id, body.model_dump(exclude_none=True))


@router.delete("/legal-threads/{thread_id}", response_model=MessageResponse)
async def delete_thread(thread_id: UUID, user: AuthUser, session: AsyncSession = Depends(get_session)):
    row = await get_row(session, LegalQueryThread, thread_id)
    account_id = await _account_id_for_uid(session, user.uid)
    if row.account_id != account_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Access denied.")
    await delete_row(session, LegalQueryThread, thread_id)
    return MessageResponse(message="Thread deleted")


# ═══════════════════════════════════════════════════════════════════════════
#  LEGAL QUERY MESSAGES
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/legal-threads/{thread_id}/messages", response_model=IDResponse, status_code=201)
async def add_message(thread_id: UUID, body: LegalQueryMessageCreate, user: AuthUser, session: AsyncSession = Depends(get_session)):
    row = await get_row(session, LegalQueryThread, thread_id)
    account_id = await _account_id_for_uid(session, user.uid)
    if row.account_id != account_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Access denied.")
    data = body.model_dump(exclude_none=True)
    data["thread_id"] = thread_id
    msg = await create_row(session, LegalQueryMessage, data)
    return IDResponse(id=msg.id)


@router.get("/legal-threads/{thread_id}/messages", response_model=List[LegalQueryMessageOut])
async def list_messages(thread_id: UUID, user: AuthUser, session: AsyncSession = Depends(get_session)):
    row = await get_row(session, LegalQueryThread, thread_id)
    account_id = await _account_id_for_uid(session, user.uid)
    if row.account_id != account_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Access denied.")
    return await list_rows(
        session, LegalQueryMessage,
        filters=[("thread_id", "==", thread_id)],
        order_by="created_at", descending=False,
    )


@router.delete("/legal-threads/{thread_id}/messages/{message_id}", response_model=MessageResponse)
async def delete_message(thread_id: UUID, message_id: UUID, user: AuthUser, session: AsyncSession = Depends(get_session)):
    row = await get_row(session, LegalQueryThread, thread_id)
    account_id = await _account_id_for_uid(session, user.uid)
    if row.account_id != account_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Access denied.")
    await delete_row(session, LegalQueryMessage, message_id)
    return MessageResponse(message="Message deleted")

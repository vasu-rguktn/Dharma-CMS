"""
Router: CASES and sub-tables
  CASE_PEOPLE, CASE_OFFICERS, CASE_CRIME_DETAILS,
  CASE_JOURNAL_ENTRIES (+ CASE_JOURNAL_ATTACHMENTS), CASE_DOCUMENTS.

All data via PostgreSQL — flat relational tables.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import AuthUser, PoliceUser
from app.core.database import get_session
from app.models.cases import (
    Case, CasePerson, CaseOfficer, CaseCrimeDetail,
    CaseJournalEntry, CaseJournalAttachment, CaseDocument,
)
from app.models.accounts import Account
from app.schemas.cases import (
    CaseCreate, CaseUpdate, CaseOut,
    CasePersonCreate, CasePersonUpdate, CasePersonOut,
    CaseOfficerCreate, CaseOfficerUpdate, CaseOfficerOut,
    CaseCrimeDetailCreate, CaseCrimeDetailUpdate, CaseCrimeDetailOut,
    CaseJournalEntryCreate, CaseJournalEntryUpdate, CaseJournalEntryOut,
    CaseJournalAttachmentCreate, CaseJournalAttachmentOut,
    CaseDocumentCreate, CaseDocumentUpdate, CaseDocumentOut,
)
from app.schemas.common import IDResponse, MessageResponse
from app.services.crud import (
    create_row, get_row, get_row_by_field, list_rows, update_row, delete_row,
)

router = APIRouter(tags=["Cases"])


async def _account_id_for_uid(session: AsyncSession, firebase_uid: str) -> UUID:
    account = await get_row_by_field(session, Account, "firebase_uid", firebase_uid)
    if not account:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Account not found.")
    return account.id


# ═══════════════════════════════════════════════════════════════════════════
#  CASES
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/cases", response_model=IDResponse, status_code=201)
async def create_case(body: CaseCreate, user: PoliceUser, session: AsyncSession = Depends(get_session)):
    data = body.model_dump(exclude_none=True)
    row = await create_row(session, Case, data)
    return IDResponse(id=row.id)


@router.get("/cases", response_model=List[CaseOut])
async def list_cases(
    user: PoliceUser, session: AsyncSession = Depends(get_session),
    limit: int = 50, offset: int = 0, status_filter: Optional[str] = None,
):
    filters = []
    if status_filter:
        filters.append(("status", "==", status_filter))
    return await list_rows(session, Case, filters=filters or None, limit=limit, offset=offset)


@router.get("/cases/{case_id}", response_model=CaseOut)
async def get_case(case_id: UUID, user: AuthUser, session: AsyncSession = Depends(get_session)):
    return await get_row(session, Case, case_id)


@router.patch("/cases/{case_id}", response_model=CaseOut)
async def update_case(case_id: UUID, body: CaseUpdate, user: PoliceUser, session: AsyncSession = Depends(get_session)):
    return await update_row(session, Case, case_id, body.model_dump(exclude_none=True))


@router.delete("/cases/{case_id}", response_model=MessageResponse)
async def delete_case(case_id: UUID, user: PoliceUser, session: AsyncSession = Depends(get_session)):
    await delete_row(session, Case, case_id)
    return MessageResponse(message="Case deleted")


# ═══════════════════════════════════════════════════════════════════════════
#  CASE PEOPLE
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/cases/{case_id}/people", response_model=IDResponse, status_code=201)
async def add_case_person(case_id: UUID, body: CasePersonCreate, user: PoliceUser, session: AsyncSession = Depends(get_session)):
    data = body.model_dump(exclude_none=True)
    data["case_id"] = case_id
    row = await create_row(session, CasePerson, data)
    return IDResponse(id=row.id)


@router.get("/cases/{case_id}/people", response_model=List[CasePersonOut])
async def list_case_people(case_id: UUID, user: AuthUser, session: AsyncSession = Depends(get_session)):
    return await list_rows(session, CasePerson, filters=[("case_id", "==", case_id)])


@router.patch("/cases/{case_id}/people/{person_id}", response_model=CasePersonOut)
async def update_case_person(case_id: UUID, person_id: UUID, body: CasePersonUpdate, user: PoliceUser, session: AsyncSession = Depends(get_session)):
    return await update_row(session, CasePerson, person_id, body.model_dump(exclude_none=True))


@router.delete("/cases/{case_id}/people/{person_id}", response_model=MessageResponse)
async def delete_case_person(case_id: UUID, person_id: UUID, user: PoliceUser, session: AsyncSession = Depends(get_session)):
    await delete_row(session, CasePerson, person_id)
    return MessageResponse(message="Person removed from case")


# ═══════════════════════════════════════════════════════════════════════════
#  CASE OFFICERS
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/cases/{case_id}/officers", response_model=IDResponse, status_code=201)
async def add_case_officer(case_id: UUID, body: CaseOfficerCreate, user: PoliceUser, session: AsyncSession = Depends(get_session)):
    data = body.model_dump(exclude_none=True)
    data["case_id"] = case_id
    row = await create_row(session, CaseOfficer, data)
    return IDResponse(id=row.id)


@router.get("/cases/{case_id}/officers", response_model=List[CaseOfficerOut])
async def list_case_officers(case_id: UUID, user: AuthUser, session: AsyncSession = Depends(get_session)):
    return await list_rows(session, CaseOfficer, filters=[("case_id", "==", case_id)])


@router.patch("/cases/{case_id}/officers/{officer_id}", response_model=CaseOfficerOut)
async def update_case_officer(case_id: UUID, officer_id: UUID, body: CaseOfficerUpdate, user: PoliceUser, session: AsyncSession = Depends(get_session)):
    return await update_row(session, CaseOfficer, officer_id, body.model_dump(exclude_none=True))


@router.delete("/cases/{case_id}/officers/{officer_id}", response_model=MessageResponse)
async def delete_case_officer(case_id: UUID, officer_id: UUID, user: PoliceUser, session: AsyncSession = Depends(get_session)):
    await delete_row(session, CaseOfficer, officer_id)
    return MessageResponse(message="Officer removed from case")


# ═══════════════════════════════════════════════════════════════════════════
#  CASE CRIME DETAILS (1:1 with case)
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/cases/{case_id}/crime-details", response_model=IDResponse, status_code=201)
async def add_crime_detail(case_id: UUID, body: CaseCrimeDetailCreate, user: PoliceUser, session: AsyncSession = Depends(get_session)):
    data = body.model_dump(exclude_none=True)
    data["case_id"] = case_id
    row = await create_row(session, CaseCrimeDetail, data)
    return IDResponse(id=row.id)


@router.get("/cases/{case_id}/crime-details", response_model=CaseCrimeDetailOut)
async def get_crime_detail(case_id: UUID, user: AuthUser, session: AsyncSession = Depends(get_session)):
    row = await get_row_by_field(session, CaseCrimeDetail, "case_id", case_id)
    if not row:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Crime details not found.")
    return row


@router.patch("/cases/{case_id}/crime-details/{detail_id}", response_model=CaseCrimeDetailOut)
async def update_crime_detail(case_id: UUID, detail_id: UUID, body: CaseCrimeDetailUpdate, user: PoliceUser, session: AsyncSession = Depends(get_session)):
    return await update_row(session, CaseCrimeDetail, detail_id, body.model_dump(exclude_none=True))


@router.delete("/cases/{case_id}/crime-details/{detail_id}", response_model=MessageResponse)
async def delete_crime_detail(case_id: UUID, detail_id: UUID, user: PoliceUser, session: AsyncSession = Depends(get_session)):
    await delete_row(session, CaseCrimeDetail, detail_id)
    return MessageResponse(message="Crime detail deleted")


# ═══════════════════════════════════════════════════════════════════════════
#  CASE JOURNAL ENTRIES (+ ATTACHMENTS)
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/cases/{case_id}/journal", response_model=IDResponse, status_code=201)
async def add_journal_entry(case_id: UUID, body: CaseJournalEntryCreate, user: PoliceUser, session: AsyncSession = Depends(get_session)):
    account_id = await _account_id_for_uid(session, user.uid)
    data = body.model_dump(exclude_none=True)
    data["case_id"] = case_id
    data["officer_account_id"] = account_id
    row = await create_row(session, CaseJournalEntry, data)
    return IDResponse(id=row.id)


@router.get("/cases/{case_id}/journal", response_model=List[CaseJournalEntryOut])
async def list_journal_entries(case_id: UUID, user: AuthUser, session: AsyncSession = Depends(get_session)):
    return await list_rows(session, CaseJournalEntry, filters=[("case_id", "==", case_id)])


@router.patch("/cases/{case_id}/journal/{entry_id}", response_model=CaseJournalEntryOut)
async def update_journal_entry(case_id: UUID, entry_id: UUID, body: CaseJournalEntryUpdate, user: PoliceUser, session: AsyncSession = Depends(get_session)):
    return await update_row(session, CaseJournalEntry, entry_id, body.model_dump(exclude_none=True))


@router.delete("/cases/{case_id}/journal/{entry_id}", response_model=MessageResponse)
async def delete_journal_entry(case_id: UUID, entry_id: UUID, user: PoliceUser, session: AsyncSession = Depends(get_session)):
    await delete_row(session, CaseJournalEntry, entry_id)
    return MessageResponse(message="Journal entry deleted")


# ── JOURNAL ATTACHMENTS ──────────────────────────────────────────────────

@router.post("/cases/{case_id}/journal/{entry_id}/attachments", response_model=IDResponse, status_code=201)
async def add_journal_attachment(case_id: UUID, entry_id: UUID, body: CaseJournalAttachmentCreate, user: PoliceUser, session: AsyncSession = Depends(get_session)):
    data = body.model_dump(exclude_none=True)
    data["journal_entry_id"] = entry_id
    row = await create_row(session, CaseJournalAttachment, data)
    return IDResponse(id=row.id)


@router.get("/cases/{case_id}/journal/{entry_id}/attachments", response_model=List[CaseJournalAttachmentOut])
async def list_journal_attachments(case_id: UUID, entry_id: UUID, user: AuthUser, session: AsyncSession = Depends(get_session)):
    return await list_rows(session, CaseJournalAttachment, filters=[("journal_entry_id", "==", entry_id)])


@router.delete("/cases/{case_id}/journal/{entry_id}/attachments/{attachment_id}", response_model=MessageResponse)
async def delete_journal_attachment(case_id: UUID, entry_id: UUID, attachment_id: UUID, user: PoliceUser, session: AsyncSession = Depends(get_session)):
    await delete_row(session, CaseJournalAttachment, attachment_id)
    return MessageResponse(message="Journal attachment deleted")


# ═══════════════════════════════════════════════════════════════════════════
#  CASE DOCUMENTS
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/cases/{case_id}/documents", response_model=IDResponse, status_code=201)
async def add_case_document(case_id: UUID, body: CaseDocumentCreate, user: PoliceUser, session: AsyncSession = Depends(get_session)):
    data = body.model_dump(exclude_none=True)
    data["case_id"] = case_id
    row = await create_row(session, CaseDocument, data)
    return IDResponse(id=row.id)


@router.get("/cases/{case_id}/documents", response_model=List[CaseDocumentOut])
async def list_case_documents(case_id: UUID, user: AuthUser, session: AsyncSession = Depends(get_session)):
    return await list_rows(session, CaseDocument, filters=[("case_id", "==", case_id)])


@router.patch("/cases/{case_id}/documents/{doc_id}", response_model=CaseDocumentOut)
async def update_case_document(case_id: UUID, doc_id: UUID, body: CaseDocumentUpdate, user: PoliceUser, session: AsyncSession = Depends(get_session)):
    return await update_row(session, CaseDocument, doc_id, body.model_dump(exclude_none=True))


@router.delete("/cases/{case_id}/documents/{doc_id}", response_model=MessageResponse)
async def delete_case_document(case_id: UUID, doc_id: UUID, user: PoliceUser, session: AsyncSession = Depends(get_session)):
    await delete_row(session, CaseDocument, doc_id)
    return MessageResponse(message="Case document deleted")

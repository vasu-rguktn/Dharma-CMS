"""
Router: PROMPT_TEMPLATES (standalone table)
Only police/admin can manage; any authenticated user can read.
All data via PostgreSQL.
"""

from fastapi import APIRouter, Depends
from typing import List
from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import AuthUser, PoliceUser
from app.core.database import get_session
from app.models.prompt_templates import PromptTemplate
from app.schemas.prompt_templates import (
    PromptTemplateCreate, PromptTemplateUpdate, PromptTemplateOut,
)
from app.schemas.common import IDResponse, MessageResponse
from app.services.crud import (
    create_row, get_row, list_rows, update_row, delete_row,
)

router = APIRouter(prefix="/prompt-templates", tags=["Prompt Templates"])


@router.post("", response_model=IDResponse, status_code=201)
async def create_template(body: PromptTemplateCreate, user: PoliceUser, session: AsyncSession = Depends(get_session)):
    row = await create_row(session, PromptTemplate, body.model_dump(exclude_none=True))
    return IDResponse(id=row.id)


@router.get("", response_model=List[PromptTemplateOut])
async def list_templates(user: AuthUser, session: AsyncSession = Depends(get_session), limit: int = 100):
    return await list_rows(session, PromptTemplate, limit=limit)


@router.get("/{template_id}", response_model=PromptTemplateOut)
async def get_template(template_id: UUID, user: AuthUser, session: AsyncSession = Depends(get_session)):
    return await get_row(session, PromptTemplate, template_id)


@router.patch("/{template_id}", response_model=PromptTemplateOut)
async def update_template(template_id: UUID, body: PromptTemplateUpdate, user: PoliceUser, session: AsyncSession = Depends(get_session)):
    return await update_row(session, PromptTemplate, template_id, body.model_dump(exclude_none=True))


@router.delete("/{template_id}", response_model=MessageResponse)
async def delete_template(template_id: UUID, user: PoliceUser, session: AsyncSession = Depends(get_session)):
    await delete_row(session, PromptTemplate, template_id)
    return MessageResponse(message="Template deleted")

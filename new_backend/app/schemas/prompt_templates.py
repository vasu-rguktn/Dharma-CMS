"""
Pydantic schemas: prompt_templates.
Matches PostgreSQL ERD exactly.
All *input* schemas accept BOTH camelCase and snake_case JSON keys.
"""

from pydantic import BaseModel
from typing import Optional, List
from uuid import UUID
from .common import TimestampMixin, CamelModel


class PromptTemplateCreate(CamelModel):
    name: str
    category: Optional[str] = None
    template: str
    variables: Optional[List[str]] = None
    description: Optional[str] = None
    is_active: bool = True

class PromptTemplateUpdate(CamelModel):
    name: Optional[str] = None
    category: Optional[str] = None
    template: Optional[str] = None
    variables: Optional[List[str]] = None
    description: Optional[str] = None
    is_active: Optional[bool] = None

class PromptTemplateOut(TimestampMixin):
    id: UUID
    name: Optional[str] = None
    category: Optional[str] = None
    template: Optional[str] = None
    variables: Optional[List[str]] = None
    description: Optional[str] = None
    is_active: Optional[bool] = None

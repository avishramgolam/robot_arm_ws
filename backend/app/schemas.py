from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, Field


class AskRequest(BaseModel):
    """The mobile client sends only the question — no user identifier, ever."""

    question: str = Field(min_length=1, max_length=300)


class AnswerMeta(BaseModel):
    """Machine metadata parsed from the model's <<<META>>> trailer."""

    confidence_level: Literal["HIGH", "MEDIUM", "LOW"] = "LOW"
    rag_grounded: bool = False
    flag_for_review: bool = False
    flag_reason: str = "N/A"
    sources: list[str] = []


class ReviewItem(BaseModel):
    """One row of the expert review queue, as shown in the dashboard."""

    id: UUID
    created_at: datetime
    user_query: str
    retrieved_context: str
    ai_generated_response: str
    confidence_level: str | None
    flagged_for_review: bool
    flag_reason: str | None
    review_status: str
    expert_rewritten_response: str | None
    reviewed_by: str | None
    reviewed_at: datetime | None


class ReviewDecision(BaseModel):
    """Submitted by a health professional from the dashboard."""

    status: Literal["APPROVED", "REWRITTEN", "REJECTED"]
    expert_rewritten_response: str | None = None
    reviewed_by: str = Field(min_length=1, max_length=100)

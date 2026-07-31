"""Expert review endpoints + the flywheel that feeds verified_expert_qa.

Flow:
  GET  /admin/review/pending   -> queue for the dashboard (flagged/LOW first)
  POST /admin/review/{id}      -> APPROVED | REWRITTEN | REJECTED

On REWRITTEN, the (original query, expert answer) pair is upserted into the
verified_expert_qa vector index, so future similar questions are served the
human-approved answer directly (see main.py's priority path).
APPROVED does the same with the AI's own answer — it's now human-endorsed.
"""

from __future__ import annotations

from fastapi import APIRouter, Depends, Header, HTTPException

from . import db, rag
from .config import settings
from .schemas import ReviewDecision

router = APIRouter(prefix="/admin", tags=["review"])


def require_admin(authorization: str = Header(default="")) -> None:
    """Bearer-token gate for all review endpoints.

    Deliberately simple; put the service behind your org's SSO / reverse
    proxy in production. The token protects the dashboard API only — the
    public /v1 chat endpoint is unauthenticated by design (anonymous app).
    """
    if authorization != f"Bearer {settings.admin_token}":
        raise HTTPException(status_code=401, detail="Invalid admin token")


@router.get("/review/pending", dependencies=[Depends(require_admin)])
async def pending(limit: int = 50, flagged_only: bool = False):
    return await db.list_pending(limit=limit, flagged_only=flagged_only)


@router.post("/review/{item_id}", dependencies=[Depends(require_admin)])
async def decide(item_id: str, decision: ReviewDecision):
    if decision.status == "REWRITTEN" and not decision.expert_rewritten_response:
        raise HTTPException(
            status_code=422,
            detail="REWRITTEN requires expert_rewritten_response",
        )

    row = await db.apply_review(
        item_id,
        decision.status,
        decision.expert_rewritten_response,
        decision.reviewed_by,
    )
    if row is None:
        raise HTTPException(status_code=404, detail="Review item not found")

    # ---- The flywheel ---------------------------------------------------
    # Rewritten or approved answers become gold-standard data: embedded by
    # the ORIGINAL user query and pushed into the verified index, where the
    # chat endpoint checks before ever calling the LLM.
    if decision.status == "REWRITTEN":
        rag.upsert_verified_answer(
            row["user_query"], decision.expert_rewritten_response or ""
        )
    elif decision.status == "APPROVED":
        rag.upsert_verified_answer(row["user_query"], row["ai_generated_response"])
    # REJECTED: intentionally indexed nowhere.

    return {"ok": True, "id": item_id, "status": decision.status}

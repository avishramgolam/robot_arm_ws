"""Async logging to the expert review queue.

Runs AFTER the response has finished streaming to the user (fired with
asyncio.create_task), so logging latency never delays the chat.

Privacy invariants, enforced here rather than by convention:
- The log functions accept no user identifier, device ID, or IP — there is
  no parameter to pass one through.
- Queries and answers are PII-scrubbed before insert (see privacy.scrub).
- Every row gets an `expires_at`; a scheduled job (cron / pg_cron) should
  delete expired rows: DELETE FROM qa_review_queue WHERE expires_at < NOW().

Dev fallback: with no DATABASE_URL configured, rows append to
./review_queue.jsonl so the pipeline is fully runnable locally.
"""

from __future__ import annotations

import asyncio
import json
import logging
import uuid
from datetime import UTC, datetime, timedelta
from pathlib import Path
from typing import Any

from .config import settings
from .privacy import scrub

logger = logging.getLogger("healthguide.db")

try:
    import asyncpg
except ImportError:  # pragma: no cover — dev without postgres deps
    asyncpg = None  # type: ignore[assignment]

_pool: Any = None
_DEV_LOG = Path("review_queue.jsonl")


async def init() -> None:
    global _pool
    if settings.database_url and asyncpg is not None:
        _pool = await asyncpg.create_pool(settings.database_url, min_size=1, max_size=5)
        logger.info("Review-queue logging: PostgreSQL")
    else:
        logger.warning("Review-queue logging: dev JSONL fallback (%s)", _DEV_LOG)


async def close() -> None:
    if _pool is not None:
        await _pool.close()


async def log_interaction(
    *,
    user_query: str,
    retrieved_context: str,
    ai_generated_response: str,
    confidence_level: str,
    flagged_for_review: bool,
    flag_reason: str,
) -> None:
    """Fire-and-forget insert into the review queue. Never raises upward."""
    row = {
        "id": str(uuid.uuid4()),
        "created_at": datetime.now(UTC).isoformat(),
        "expires_at": (
            datetime.now(UTC) + timedelta(days=settings.log_retention_days)
        ).isoformat(),
        "user_query": scrub(user_query),
        "retrieved_context": retrieved_context,
        "ai_generated_response": scrub(ai_generated_response),
        "confidence_level": confidence_level,
        "flagged_for_review": flagged_for_review,
        "flag_reason": flag_reason,
        "review_status": "PENDING",
    }
    try:
        if _pool is not None:
            await _pool.execute(
                """
                INSERT INTO qa_review_queue
                  (id, created_at, expires_at, user_query, retrieved_context,
                   ai_generated_response, confidence_level, flagged_for_review,
                   flag_reason, review_status)
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'PENDING')
                """,
                uuid.UUID(row["id"]),
                datetime.now(UTC),
                datetime.now(UTC) + timedelta(days=settings.log_retention_days),
                row["user_query"],
                row["retrieved_context"],
                row["ai_generated_response"],
                confidence_level,
                flagged_for_review,
                flag_reason,
            )
        else:
            await asyncio.to_thread(_append_jsonl, row)
    except Exception:  # noqa: BLE001 — logging must never break chat
        logger.exception("Failed to log interaction to review queue")


def _append_jsonl(row: dict[str, Any]) -> None:
    with _DEV_LOG.open("a", encoding="utf-8") as f:
        f.write(json.dumps(row, ensure_ascii=False) + "\n")


# ---------------------------------------------------------------------------
# Review-workflow queries (used by the /admin endpoints)
# ---------------------------------------------------------------------------

async def list_pending(limit: int = 50, flagged_only: bool = False) -> list[dict[str, Any]]:
    if _pool is not None:
        where = "review_status = 'PENDING'"
        if flagged_only:
            where += " AND flagged_for_review"
        rows = await _pool.fetch(
            f"""
            SELECT * FROM qa_review_queue
            WHERE {where}
            ORDER BY flagged_for_review DESC,
                     (confidence_level = 'LOW') DESC,
                     created_at ASC
            LIMIT $1
            """,
            limit,
        )
        return [dict(r) for r in rows]

    # Dev fallback: read the JSONL, newest flagged/low-confidence first.
    if not _DEV_LOG.exists():
        return []
    items = [json.loads(line) for line in _DEV_LOG.read_text().splitlines() if line]
    items = [i for i in items if i.get("review_status") == "PENDING"]
    if flagged_only:
        items = [i for i in items if i.get("flagged_for_review")]
    items.sort(
        key=lambda i: (
            not i.get("flagged_for_review", False),
            i.get("confidence_level") != "LOW",
            i.get("created_at", ""),
        )
    )
    return items[:limit]


async def apply_review(
    item_id: str,
    status: str,
    expert_rewritten_response: str | None,
    reviewed_by: str,
) -> dict[str, Any] | None:
    """Record the expert's decision; returns the updated row (or None)."""
    if _pool is not None:
        row = await _pool.fetchrow(
            """
            UPDATE qa_review_queue
            SET review_status = $2,
                expert_rewritten_response = $3,
                reviewed_by = $4,
                reviewed_at = NOW()
            WHERE id = $1
            RETURNING *
            """,
            uuid.UUID(item_id),
            status,
            expert_rewritten_response,
            reviewed_by,
        )
        return dict(row) if row else None

    # Dev fallback: rewrite the JSONL in place.
    if not _DEV_LOG.exists():
        return None
    items = [json.loads(line) for line in _DEV_LOG.read_text().splitlines() if line]
    updated = None
    for item in items:
        if item["id"] == item_id:
            item["review_status"] = status
            item["expert_rewritten_response"] = expert_rewritten_response
            item["reviewed_by"] = reviewed_by
            item["reviewed_at"] = datetime.now(UTC).isoformat()
            updated = item
    _DEV_LOG.write_text(
        "".join(json.dumps(i, ensure_ascii=False) + "\n" for i in items)
    )
    return updated

"""HealthGuide backend — FastAPI orchestration.

Request flow for POST /v1/ask (SSE):

    [question] -> verified_expert_qa (>=0.90 match? serve expert answer, done)
               -> retrieve grounding context from health_sources
               -> stream Claude answer tokens to the client immediately
               -> after the stream ends: parse metadata trailer and
                  asyncio.create_task(log to review queue)  <- user never waits

SSE event protocol consumed by the Flutter client (rag_api_client.dart):
    data: {"type": "token",  "text": "..."}      # append to the bubble
    data: {"type": "meta",   "confidence_level": ..., "sources": [...]}
    data: {"type": "done"}
"""

from __future__ import annotations

import asyncio
import json
import logging
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, StreamingResponse

from . import db, rag
from .llm import StreamOutcome, stream_answer
from .review import router as review_router
from .schemas import AnswerMeta, AskRequest

logging.basicConfig(level=logging.INFO)


@asynccontextmanager
async def lifespan(_: FastAPI):
    rag.seed_dev_corpus()
    await db.init()
    yield
    await db.close()


app = FastAPI(title="HealthGuide backend", lifespan=lifespan)
app.include_router(review_router)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # anonymous public API; no credentials involved
    allow_methods=["*"],
    allow_headers=["*"],
)


def _sse(payload: dict) -> str:
    return f"data: {json.dumps(payload, ensure_ascii=False)}\n\n"


@app.post("/v1/ask")
async def ask(body: AskRequest) -> StreamingResponse:
    return StreamingResponse(
        _answer_events(body.question),
        media_type="text/event-stream",
        headers={"Cache-Control": "no-cache"},
    )


async def _answer_events(question: str) -> AsyncIterator[str]:
    # ---- Priority path: expert-verified answer --------------------------
    from .config import settings

    verified = rag.match_verified_answer(question, settings.verified_qa_threshold)
    if verified is not None:
        # Serve directly — no LLM call. Chunked so the client UX matches
        # the streamed path.
        for chunk in _chunks(verified.text, size=80):
            yield _sse({"type": "token", "text": chunk})
            await asyncio.sleep(0)  # let the event loop flush
        yield _sse(
            {
                "type": "meta",
                "confidence_level": "HIGH",
                "rag_grounded": True,
                "sources": [verified.source_label],
                "expert_verified": True,
            }
        )
        yield _sse({"type": "done"})
        return

    # ---- Generation path ------------------------------------------------
    context, _labels = rag.retrieve_context(question)
    outcome = StreamOutcome(answer_text="", meta=AnswerMeta())

    try:
        async for token in stream_answer(question, context, outcome):
            yield _sse({"type": "token", "text": token})
    except Exception:  # noqa: BLE001 — never leak stack traces to teens' phones
        logging.getLogger("healthguide").exception("Generation failed")
        yield _sse(
            {
                "type": "token",
                "text": (
                    "Something went wrong on our side — please try again in a "
                    "moment. If you need help right now, the **Support** tab "
                    "has free, confidential hotlines."
                ),
            }
        )
        yield _sse({"type": "done"})
        return

    meta = outcome.meta
    yield _sse(
        {
            "type": "meta",
            "confidence_level": meta.confidence_level,
            "rag_grounded": meta.rag_grounded,
            "sources": meta.sources,
            "expert_verified": False,
        }
    )
    yield _sse({"type": "done"})

    # ---- Background logging (after the user has their full answer) ------
    asyncio.create_task(
        db.log_interaction(
            user_query=question,
            retrieved_context=context,
            ai_generated_response=outcome.answer_text,
            confidence_level=meta.confidence_level,
            flagged_for_review=meta.flag_for_review or outcome.refused,
            flag_reason=meta.flag_reason,
        )
    )


def _chunks(text: str, size: int) -> list[str]:
    return [text[i : i + size] for i in range(0, len(text), size)]


# ---- Expert dashboard (static single page) --------------------------------

_DASHBOARD = Path(__file__).parent / "static" / "review_dashboard.html"


@app.get("/admin/dashboard")
async def dashboard() -> FileResponse:
    # The page itself is public; every API call it makes requires the admin
    # bearer token, entered in the page's login field.
    return FileResponse(_DASHBOARD)


@app.get("/healthz")
async def healthz() -> dict:
    return {"ok": True}

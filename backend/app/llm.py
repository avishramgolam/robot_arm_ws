"""Claude API integration: streaming generation with a metadata trailer.

Protocol (see prompts.py): the model writes the user-facing Markdown answer,
then the <<<META>>> sentinel, then one line of JSON metadata. This module
streams answer tokens out as they arrive and returns the parsed metadata at
the end — resolving the original spec's conflict between "stream instantly"
and "return structured JSON".

Also handles Claude Opus 5 specifics:
- `stop_reason == "refusal"` (safety classifiers) is mapped to a safe,
  supportive fallback message and flagged for human review.
- Server-side refusal fallbacks are enabled (`fallbacks="default"` with the
  `server-side-fallback-2026-07-01` beta), so a classifier decline is
  transparently re-served by Anthropic's recommended fallback model before
  our own fallback text is ever needed.
- The system prompt carries a `cache_control` breakpoint, so its tokens are
  cached across requests (~90% cheaper after the first call).
"""

from __future__ import annotations

import json
import logging
from collections.abc import AsyncIterator
from dataclasses import dataclass

from anthropic import AsyncAnthropic

from .config import settings
from .prompts import META_SENTINEL, SYSTEM_PROMPT
from .schemas import AnswerMeta

logger = logging.getLogger("healthguide.llm")

client = AsyncAnthropic()

REFUSAL_FALLBACK_TEXT = (
    "I want to make sure you get accurate, safe information, and I can't "
    "answer this one here. Please check the **Guides** tab for verified "
    "health information, or the **Support** tab for free, confidential "
    "people you can talk to right now."
)


@dataclass
class StreamOutcome:
    """What the endpoint needs after the stream finishes."""

    answer_text: str
    meta: AnswerMeta
    refused: bool = False


async def stream_answer(
    question: str,
    context: str,
    outcome: StreamOutcome,
) -> AsyncIterator[str]:
    """Yield user-facing answer tokens; fill `outcome` when the stream ends.

    (An async generator can't `return` a value, so the caller passes the
    outcome object in and reads it after iteration completes.)
    """
    user_message = (
        "Retrieved medical sources:\n---\n"
        f"{context}\n---\n\n"
        f"User's question (verbatim):\n{question}"
    )

    answer_parts: list[str] = []
    meta_parts: list[str] = []
    in_meta = False
    buffer = ""  # holds a tail that might be the start of the sentinel

    async with client.beta.messages.stream(
        model=settings.healthguide_model,
        max_tokens=settings.max_answer_tokens,
        # Thinking is on by default on Opus 5 (adaptive); effort tunes
        # depth/latency without a thinking budget.
        output_config={"effort": settings.healthguide_effort},
        betas=["server-side-fallback-2026-07-01"],
        fallbacks="default",
        system=[
            {
                "type": "text",
                "text": SYSTEM_PROMPT,
                # Frozen prompt + breakpoint = cached prefix on every call.
                "cache_control": {"type": "ephemeral"},
            }
        ],
        messages=[{"role": "user", "content": user_message}],
    ) as stream:
        async for token in stream.text_stream:
            if in_meta:
                meta_parts.append(token)
                continue

            buffer += token
            idx = buffer.find(META_SENTINEL)
            if idx != -1:
                # Everything before the sentinel is answer; after is metadata.
                head = buffer[:idx].rstrip()
                if head:
                    answer_parts.append(head)
                    yield head
                meta_parts.append(buffer[idx + len(META_SENTINEL):])
                in_meta = True
                buffer = ""
            else:
                # Emit all but a sentinel-length tail, in case the sentinel
                # is split across two tokens.
                safe_len = len(buffer) - len(META_SENTINEL)
                if safe_len > 0:
                    emit, buffer = buffer[:safe_len], buffer[safe_len:]
                    answer_parts.append(emit)
                    yield emit

        # Flush any tail that never turned into a sentinel.
        if not in_meta and buffer:
            answer_parts.append(buffer)
            yield buffer

        final = await stream.get_final_message()

    # ---- Post-stream: refusal handling + metadata parse -----------------
    if final.stop_reason == "refusal":
        # Classifier declined (and any server-side fallback declined too).
        # Serve the safe fallback and force human review of the log.
        outcome.refused = True
        outcome.answer_text = REFUSAL_FALLBACK_TEXT
        outcome.meta = AnswerMeta(
            confidence_level="LOW",
            rag_grounded=False,
            flag_for_review=True,
            flag_reason="Model refusal — needs human review",
            sources=[],
        )
        yield REFUSAL_FALLBACK_TEXT
        return

    outcome.answer_text = "".join(answer_parts).strip()
    outcome.meta = _parse_meta("".join(meta_parts))


def _parse_meta(raw: str) -> AnswerMeta:
    """Parse the metadata trailer defensively.

    A malformed trailer must never break the user's chat — it just means the
    interaction gets conservative defaults (LOW confidence, flagged), which
    routes it to human review. Fail-safe, not fail-open.
    """
    raw = raw.strip()
    try:
        start, end = raw.index("{"), raw.rindex("}") + 1
        return AnswerMeta.model_validate(json.loads(raw[start:end]))
    except Exception:  # noqa: BLE001
        logger.warning("Unparseable metadata trailer: %r", raw[:200])
        return AnswerMeta(
            confidence_level="LOW",
            flag_for_review=True,
            flag_reason="Metadata trailer missing or malformed",
        )

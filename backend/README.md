# HealthGuide backend — RAG chat + human-in-the-loop review

FastAPI middleware between the Flutter app and the Claude API, implementing
the HITL safety architecture:

```
[ Flutter app ] ──POST /v1/ask──▶ ┌────────────────────────────────────┐
                                  │ 1. verified_expert_qa (≥0.90 sim?) │──▶ serve expert answer, $0 generation
                                  │ 2. retrieve vetted context         │
                                  │ 3. Claude (claude-opus-5) streams  │──▶ tokens forwarded instantly (SSE)
                                  │ 4. parse <<<META>>> trailer        │
                                  │ 5. async log → qa_review_queue     │  (user never waits on this)
                                  └────────────────────────────────────┘
                                                    │
                     ┌──────────────────────────────┘
                     ▼
        /admin/dashboard  → experts approve / rewrite / reject
                     │
                     ▼
        REWRITTEN or APPROVED → upsert into verified_expert_qa  (the flywheel)
```

## Design deviations from the original spec (deliberate)

1. **Answer-first + metadata trailer instead of one JSON object.** A single
   JSON output can't be token-streamed to the user. The model streams the
   Markdown answer, then `<<<META>>>` + one JSON line
   (`confidence_level`, `rag_grounded`, `flag_for_review`, `flag_reason`,
   `sources`). `app/llm.py` splits the stream, handling the sentinel across
   token boundaries. A malformed trailer defaults to LOW-confidence +
   flagged — fail-safe routes to human review, never breaks the chat.
2. **Privacy hardening.** The log functions physically accept no user ID,
   device ID, or IP; queries/answers are PII-scrubbed (`app/privacy.py`);
   every row has `expires_at` (default 90 days) with a purge index. The
   Flutter banner was updated to disclose anonymous review honestly.
3. **Crisis handling responds, not refuses.** Abuse/self-harm signals get a
   brief supportive reply + routing to the Support tab hotlines, and the log
   is always flagged for human review.

## Claude integration notes

- Model `claude-opus-5`, streaming via the async SDK; adaptive thinking is on
  by default, with `output_config.effort` (env-tunable, default `medium`)
  as the latency/quality dial.
- **Server-side refusal fallbacks are enabled** (`fallbacks: "default"`,
  beta `server-side-fallback-2026-07-01`): if a safety classifier declines a
  request, the API transparently re-serves it on Anthropic's recommended
  fallback model. If the whole chain refuses, `stop_reason: "refusal"` is
  handled with a safe supportive message and a flagged log entry.
- The system prompt carries a `cache_control` breakpoint → cached prefix on
  every request after the first (~90% cheaper for that span).
- Embeddings: the Claude API doesn't provide embeddings. `app/rag.py` ships a
  deterministic dev stub; swap `EmbeddingProvider`/`VectorStore` for Voyage AI
  + pgvector/Qdrant in production (interfaces stay the same).

## Run

```bash
cd backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env          # set ANTHROPIC_API_KEY (or use `ant auth login`)
uvicorn app.main:app --reload
```

- No `DATABASE_URL`? Interactions log to `./review_queue.jsonl` so everything
  runs end-to-end locally. With Postgres, apply
  `migrations/001_qa_review_queue.sql` first.
- Chat: `POST /v1/ask` with `{"question": "..."}` → SSE stream of
  `{"type":"token"|"meta"|"done", ...}` events.
- Dashboard: open `http://localhost:8000/admin/dashboard`, enter the
  `ADMIN_TOKEN` from `.env`.
- The Flutter app connects when built with
  `flutter run --dart-define=RAG_API_URL=http://localhost:8000` (falls back
  to the built-in simulation otherwise).

## Retention purge

Schedule (cron / pg_cron):

```sql
DELETE FROM qa_review_queue WHERE expires_at < NOW();
```

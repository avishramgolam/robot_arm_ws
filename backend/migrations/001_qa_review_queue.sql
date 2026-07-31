-- Expert review queue for HealthGuide AI answers.
--
-- Extends the base design with privacy/ops columns:
--   expires_at        retention window; purge job deletes expired rows
--   (deliberately absent: user_id, device_id, ip_address — the app is
--    anonymous by design and the schema enforces it)

CREATE TABLE IF NOT EXISTS qa_review_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL
        DEFAULT NOW() + INTERVAL '90 days',

    -- Interaction log (PII-scrubbed before insert; see app/privacy.py)
    user_query TEXT NOT NULL,
    retrieved_context TEXT NOT NULL,
    ai_generated_response TEXT NOT NULL,

    -- Machine metadata & flags
    confidence_level VARCHAR(10)
        CHECK (confidence_level IN ('HIGH', 'MEDIUM', 'LOW')),
    flagged_for_review BOOLEAN DEFAULT FALSE,
    flag_reason TEXT,

    -- Human review & correction workflow
    review_status VARCHAR(20) NOT NULL DEFAULT 'PENDING'
        CHECK (review_status IN ('PENDING', 'APPROVED', 'REWRITTEN', 'REJECTED')),
    expert_rewritten_response TEXT,
    reviewed_by VARCHAR(100),
    reviewed_at TIMESTAMP WITH TIME ZONE
);

-- The dashboard's default view: pending items, flagged & low-confidence first.
CREATE INDEX IF NOT EXISTS idx_review_queue_pending
    ON qa_review_queue (flagged_for_review DESC, created_at ASC)
    WHERE review_status = 'PENDING';

-- Retention purge (run from cron or pg_cron):
--   DELETE FROM qa_review_queue WHERE expires_at < NOW();
CREATE INDEX IF NOT EXISTS idx_review_queue_expiry
    ON qa_review_queue (expires_at);

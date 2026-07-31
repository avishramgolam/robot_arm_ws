"""PII scrubbing for logged queries.

The whole product is anonymous by design, but users sometimes type
identifying details into a question ("my name is X", emails, phone numbers).
Everything written to the review database passes through scrub() first, so
expert reviewers see the health question, not the person.

Deliberately conservative: regex-based, favors redacting too much over too
little. No user ID, device ID, or IP address is EVER passed to the logger —
that is enforced by the log function signatures, not just by policy.
"""

import re

_PATTERNS: list[tuple[re.Pattern[str], str]] = [
    (re.compile(r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"), "[email]"),
    # Phone-like sequences: 7+ digits allowing separators.
    (re.compile(r"\+?\d[\d\s().-]{6,}\d"), "[phone]"),
    # Handles/usernames (@name) — common way teens self-identify.
    (re.compile(r"@\w{3,}"), "[handle]"),
    (re.compile(r"https?://\S+"), "[link]"),
    # "my name is X" / "I'm called X" style self-identification.
    (
        re.compile(r"(my name is|i am called|i'm called)\s+\S+", re.IGNORECASE),
        r"\1 [name]",
    ),
]


def scrub(text: str) -> str:
    for pattern, replacement in _PATTERNS:
        text = pattern.sub(replacement, text)
    return text

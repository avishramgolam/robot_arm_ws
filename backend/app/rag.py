"""Retrieval layer: vetted-source retrieval + the verified-expert-QA fast path.

Two collections, checked in priority order:

1. ``verified_expert_qa`` — (query, expert-rewritten answer) pairs produced by
   the human review flywheel. If an incoming question matches one at >= 0.90
   cosine similarity, the app serves the expert answer directly: zero
   generation cost, 100% human-approved content.

2. ``health_sources`` — chunks of vetted material (WHO, UNESCO CSE, …) used
   as grounding context for the LLM.

PRODUCTION SWAP: `EmbeddingProvider` and `VectorStore` are minimal in-memory
implementations so the whole pipeline runs with zero infrastructure. Replace
them with a real embedding model (e.g. Voyage AI — the Claude API itself does
not provide embeddings) and a real vector DB (pgvector, Qdrant, …). The
interfaces are the contract; main.py and review.py don't change.
"""

from __future__ import annotations

import hashlib
import math
from dataclasses import dataclass, field


class EmbeddingProvider:
    """Deterministic hash-based bag-of-words embedding (dev stand-in).

    Good enough to make similarity search behave sensibly in development;
    replace with a real model for production quality.
    """

    DIM = 256

    def embed(self, text: str) -> list[float]:
        vec = [0.0] * self.DIM
        for token in text.lower().split():
            digest = hashlib.sha256(token.encode()).digest()
            index = int.from_bytes(digest[:4], "big") % self.DIM
            vec[index] += 1.0
        norm = math.sqrt(sum(v * v for v in vec)) or 1.0
        return [v / norm for v in vec]


def cosine(a: list[float], b: list[float]) -> float:
    return sum(x * y for x, y in zip(a, b))


@dataclass
class Document:
    text: str
    source_label: str
    embedding: list[float] = field(default_factory=list)


class VectorStore:
    """Tiny in-memory cosine-similarity store (dev stand-in)."""

    def __init__(self, embedder: EmbeddingProvider):
        self._embedder = embedder
        self._docs: list[Document] = []

    def add(self, text: str, source_label: str) -> None:
        self._docs.append(
            Document(text, source_label, self._embedder.embed(text))
        )

    def search(self, query: str, top_k: int = 4) -> list[tuple[Document, float]]:
        query_vec = self._embedder.embed(query)
        scored = [(d, cosine(query_vec, d.embedding)) for d in self._docs]
        scored.sort(key=lambda pair: pair[1], reverse=True)
        return scored[:top_k]


_embedder = EmbeddingProvider()

#: Grounding corpus. In production, an ingestion pipeline fills this from
#: vetted documents; the seed entries below make dev answers demonstrable.
health_sources = VectorStore(_embedder)

#: The flywheel target: expert-rewritten answers indexed by original query.
verified_expert_qa = VectorStore(_embedder)


def seed_dev_corpus() -> None:
    seed = [
        (
            "Condoms are the only contraceptive method that protects against "
            "both pregnancy and most sexually transmitted infections. Used "
            "correctly at every act of sex, external (male) condoms are about "
            "98% effective at preventing pregnancy; with typical use, about "
            "87%. Check the expiry date, open carefully, pinch the tip, and "
            "roll on before any genital contact.",
            "WHO Family Planning Handbook",
        ),
        (
            "The menstrual cycle is counted from the first day of one period "
            "to the first day of the next; 21 to 45 days is common in the "
            "first years after menarche. Irregular cycles are normal in "
            "adolescence. Very heavy bleeding or pain that disrupts daily "
            "life warrants clinical review.",
            "WHO adolescent health guidance",
        ),
        (
            "Pregnancy can occur any time sperm enters the vagina, including "
            "at first intercourse and during menstruation, because sperm can "
            "survive up to five days. Emergency contraceptive pills are most "
            "effective within 72 hours of unprotected sex.",
            "WHO Family Planning Handbook",
        ),
        (
            "Consent must be freely given, informed, and can be withdrawn at "
            "any time. Comprehensive sexuality education emphasises that "
            "silence, pressure, intoxication, or a prior 'yes' do not "
            "constitute consent.",
            "UNESCO International technical guidance on sexuality education (2018)",
        ),
        (
            "Most sexually transmitted infections have no visible symptoms "
            "for long periods; testing is the only reliable way to know. "
            "Masturbation is a normal, harmless part of human sexuality with "
            "no proven negative health effects.",
            "WHO sexual health fact sheets",
        ),
    ]
    for text, label in seed:
        health_sources.add(text, label)


def retrieve_context(question: str) -> tuple[str, list[str]]:
    """Return (formatted context block, source labels) for the LLM prompt."""
    hits = health_sources.search(question)
    parts: list[str] = []
    labels: list[str] = []
    for i, (doc, _score) in enumerate(hits, start=1):
        parts.append(f"[Source {i}: {doc.source_label}]\n{doc.text}")
        if doc.source_label not in labels:
            labels.append(doc.source_label)
    return "\n\n".join(parts), labels


def match_verified_answer(question: str, threshold: float) -> Document | None:
    """Priority path: an expert-approved answer for a near-identical question."""
    hits = verified_expert_qa.search(question, top_k=1)
    if hits and hits[0][1] >= threshold:
        return hits[0][0]
    return None


def upsert_verified_answer(question: str, expert_answer: str) -> None:
    """Close the loop: index (query -> expert answer) for future priority hits.

    The document text is the expert answer; the *query* drives the embedding
    so future similar questions match it.
    """
    doc = Document(
        text=expert_answer,
        source_label="Reviewed by a health professional",
        embedding=_embedder.embed(question),
    )
    verified_expert_qa._docs.append(doc)  # noqa: SLF001 — dev store only

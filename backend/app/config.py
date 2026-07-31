from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """All runtime configuration, loaded from environment / .env."""

    healthguide_model: str = "claude-opus-5"
    healthguide_effort: str = "medium"  # low | medium | high | xhigh | max
    max_answer_tokens: int = 2000

    database_url: str | None = None
    admin_token: str = "change-me"
    log_retention_days: int = 90

    # Serve the expert-verified answer directly (skipping generation) when a
    # cached expert Q&A matches the query at or above this cosine similarity.
    verified_qa_threshold: float = 0.90

    max_question_chars: int = 300  # mirrors the mobile client's input limit

    class Config:
        env_file = ".env"


settings = Settings()

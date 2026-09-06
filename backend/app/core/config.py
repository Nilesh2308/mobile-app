from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import List

class Settings(BaseSettings):
    # Groq Settings
    GROQ_API_KEY: str = ""
    GROQ_LLM_MODEL: str = "openai/gpt-oss-20b"
    GROQ_FAST_MODEL: str = "openai/gpt-oss-20b"

    # AI Models Settings
    EMBEDDING_MODEL_NAME: str = "BAAI/bge-small-en-v1.5"
    WHISPER_MODEL_SIZE: str = "small"
    KOKORO_VOICE: str = "af_heart" # Default voice

    # Qdrant Settings
    QDRANT_URL: str = "http://localhost:6333"
    QDRANT_API_KEY: str = ""
    QDRANT_COLLECTION_NAME: str = "voiceai_collection"

    # App Settings
    ALLOWED_ORIGINS: str = "http://localhost:3000"
    RELEVANCE_SCORE_THRESHOLD: float = 0.55

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

settings = Settings()

def get_allowed_origins() -> List[str]:
    return [origin.strip() for origin in settings.ALLOWED_ORIGINS.split(",") if origin.strip()]

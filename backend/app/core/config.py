from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import List

class Settings(BaseSettings):
    # Qwen Settings
    QWEN_API_KEY: str = "sk-34d333c1a2d74d7abd13a38bf8b8abe1"
    QWEN_LLM_MODEL: str = "qwen3-14b"
    QWEN_API_URL: str = "https://chat.theonetechnologies.co.in/api/chat/completions"

    # Groq Settings (Cloud STT & LLM)
    GROQ_API_KEY: str = ""
    GROQ_API_KEY_BACKUP: str = ""
    STT_ENGINE: str = "groq" # "groq" (cloud ~0.2s, 0MB RAM) or "faster-whisper" (local)
    GROQ_WHISPER_MODEL: str = "whisper-large-v3-turbo"

    # AI Models Settings
    EMBEDDING_MODEL_NAME: str = "BAAI/bge-small-en-v1.5"
    WHISPER_MODEL_SIZE: str = "small"
    WHISPER_BEAM_SIZE: int = 1
    TTS_ENGINE: str = "edge" # "edge" (fast ~1s) or "kokoro"
    EDGE_TTS_VOICE: str = "en-US-AvaNeural"
    KOKORO_VOICE: str = "af_heart" # Default kokoro voice

    # Qdrant Settings
    QDRANT_URL: str = "http://localhost:6333"
    QDRANT_API_KEY: str = ""
    QDRANT_COLLECTION_NAME: str = "voiceai_collection"

    # App Settings
    ALLOWED_ORIGINS: str = "http://localhost:3000"
    RELEVANCE_SCORE_THRESHOLD: float = 0.30

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

settings = Settings()

def get_allowed_origins() -> List[str]:
    return [origin.strip() for origin in settings.ALLOWED_ORIGINS.split(",") if origin.strip()]

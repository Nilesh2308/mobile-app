from fastapi import APIRouter, HTTPException
from app.core.qdrant_client import qdrant_db
from app.core.embeddings import embedding_service
from app.core.stt import stt_service
from app.core.tts import tts_service
from app.core.groq_client import groq_service

router = APIRouter()

@router.get("/health")
async def health_check():
    health_status = {
        "status": "ok",
        "components": {
            "qdrant": False,
            "embeddings": False,
            "whisper": False,
            "kokoro": False,
            "groq": False
        }
    }

    # Check Qdrant
    try:
        if qdrant_db.client is not None:
            # simple ping
            collections = qdrant_db.client.get_collections()
            health_status["components"]["qdrant"] = True
    except Exception as e:
        health_status["status"] = "degraded"

    # Check Embeddings
    if embedding_service.model is not None:
        health_status["components"]["embeddings"] = True
    else:
        health_status["status"] = "degraded"

    # Check Whisper
    if stt_service.model is not None:
        health_status["components"]["whisper"] = True
    else:
        health_status["status"] = "degraded"

    # Check Kokoro
    if tts_service.pipeline is not None:
        health_status["components"]["kokoro"] = True
    else:
        health_status["status"] = "degraded"
        
    # Check Groq
    if groq_service.client is not None:
        health_status["components"]["groq"] = True
    else:
        health_status["status"] = "degraded"

    if health_status["status"] == "degraded":
        # We can still return 200, or 503 depending on requirements.
        # Returning 200 with degraded status is common for partial outages.
        pass

    return health_status

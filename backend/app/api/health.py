from fastapi import APIRouter, HTTPException
from app.core.qdrant_client import qdrant_db
from app.core.embeddings import embedding_service
from app.core.stt import stt_service
from app.core.tts import tts_service
from app.core.qwen_client import qwen_service

router = APIRouter()

@router.get("/health")
async def health_check():
    health_status = {
        "status": "ok",
        "components": {
            "qdrant": False,
            "embeddings": False,
            "stt": False,
            "tts": False,
            "qwen": False
        },
        "engines": {
            "stt": "groq-cloud-whisper",
            "tts": "microsoft-edge-tts",
            "db": "qdrant-cloud",
            "llm": "qwen3-14b"
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

    # Check STT (Groq Cloud Whisper or local Whisper)
    try:
        if getattr(stt_service, "groq_client", None) is not None or getattr(stt_service, "local_model", None) is not None or getattr(stt_service, "model", None) is not None:
            health_status["components"]["stt"] = True
        else:
            health_status["status"] = "degraded"
    except Exception:
        health_status["status"] = "degraded"

    # Check TTS (Edge-TTS or Kokoro)
    from app.core.tts import EDGE_TTS_AVAILABLE
    if (tts_service.engine == "edge" and EDGE_TTS_AVAILABLE) or tts_service.pipeline is not None:
        health_status["components"]["tts"] = True
    else:
        health_status["status"] = "degraded"
        
    # Check Qwen
    if qwen_service.api_key is not None:
        health_status["components"]["qwen"] = True
    else:
        health_status["status"] = "degraded"

    return health_status
 

@router.get("/test-tts")
async def test_tts_endpoint():
    try:
        from app.core.tts import tts_service
        import edge_tts
        clean = "Hello, testing voice audio."
        comm = edge_tts.Communicate(clean, tts_service.edge_voice)
        chunks = []
        audio = bytearray()
        async for chunk in comm.stream():
            chunks.append(chunk["type"])
            if chunk["type"] == "audio":
                audio.extend(chunk["data"])
        return {
            "status": "ok" if len(audio) > 0 else "empty",
            "audio_bytes": len(audio),
            "chunk_types": chunks[:10],
            "voice": tts_service.edge_voice
        }
    except Exception as e:
        import traceback
        return {"status": "error", "message": str(e), "traceback": traceback.format_exc()}



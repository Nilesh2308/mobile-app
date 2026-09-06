import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import get_allowed_origins
from app.core.qdrant_client import qdrant_db
from app.core.groq_client import groq_service
from app.core.embeddings import embedding_service
from app.core.stt import stt_service
from app.core.tts import tts_service
from app.api.health import router as health_router
from app.api.kb import router as kb_router
from app.api.chat import router as chat_router
from app.api.voice import router as voice_router

# Configure structured logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup actions
    logger.info("Initializing AI models and clients...")
    
    # 1. Connect to Qdrant
    qdrant_db.connect()
    
    # 2. Connect to Groq
    groq_service.connect()
    
    # 3. Load Embedding Model
    embedding_service.load_model()
    
    # 4. Load Whisper STT Model
    stt_service.load_model()
    
    # 5. Load Kokoro TTS Model
    tts_service.load_model()
    
    logger.info("Startup complete. All models and clients loaded.")
    
    # Start background cleanup task for sessions
    import asyncio
    from app.core.memory_store import session_memory
    
    async def cleanup_loop():
        while True:
            await asyncio.sleep(600)  # run every 10 minutes
            evicted = await asyncio.to_thread(session_memory.evict_stale_sessions, 1800) # 30 mins max age
            if evicted > 0:
                logger.info(f"Evicted {evicted} stale sessions.")
                
    cleanup_task = asyncio.create_task(cleanup_loop())
    
    yield
    
    # Shutdown actions
    cleanup_task.cancel()
    logger.info("Shutting down... Cleaning up resources.")

from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from fastapi import Request
from fastapi.responses import JSONResponse
from app.core.rate_limit import limiter

app = FastAPI(title="Voice AI Backend", lifespan=lifespan)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"Global exception: {exc}")
    return JSONResponse(
        status_code=500,
        content={"error": True, "message": "Internal server error", "detail": str(exc)}
    )

# Setup CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=get_allowed_origins(),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(health_router, prefix="/api", tags=["health"])
app.include_router(kb_router, prefix="/api/kb", tags=["kb"])
app.include_router(chat_router, prefix="/api/chat", tags=["chat"])
app.include_router(voice_router, prefix="/api/voice", tags=["voice"])

from app.core.analytics import analytics_store

@app.get("/api/stats")
async def get_stats():
    return analytics_store.get_stats()

@app.get("/")
async def root():
    return {"message": "Welcome to the Voice AI Backend. See /docs for API documentation."}

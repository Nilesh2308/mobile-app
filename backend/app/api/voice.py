import base64
from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from fastapi.concurrency import run_in_threadpool
from typing import List

from app.core.stt import stt_service
from app.core.tts import tts_service
from app.services.rag_service import rag_service
from app.core.rate_limit import limiter
from fastapi import Request

router = APIRouter()

MAX_AUDIO_SIZE = 5 * 1024 * 1024  # 5 MB

@router.post("/transcribe")
@limiter.limit("5/minute")
async def transcribe_audio(request: Request, file: UploadFile = File(...)):
    """
    Accepts an audio file and returns the transcribed text.
    """
    audio_bytes = await file.read()
    if not audio_bytes:
        raise HTTPException(status_code=400, detail="Empty audio file")
    if len(audio_bytes) > MAX_AUDIO_SIZE:
        raise HTTPException(status_code=413, detail="Audio file too large. Max 5MB.")
        
    try:
        # Run STT in threadpool to avoid blocking event loop
        text = await run_in_threadpool(stt_service.transcribe, audio_bytes)
        return {"transcription": text}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/chat")
@limiter.limit("5/minute")
async def voice_chat(
    request: Request,
    session_id: str = Form(..., max_length=100),
    file: UploadFile = File(...)
):
    """
    End-to-end voice chat:
    1. Transcribe audio to text
    2. Run RAG logic to get answer
    3. Synthesize answer back to speech
    4. Return JSON with base64 audio and metadata
    """
    # 1. Read Audio
    audio_bytes = await file.read()
    if not audio_bytes:
        raise HTTPException(status_code=400, detail="Empty audio file")
    if len(audio_bytes) > MAX_AUDIO_SIZE:
        raise HTTPException(status_code=413, detail="Audio file too large. Max 5MB.")
        
    try:
        # 2. Transcribe (STT)
        query = await run_in_threadpool(stt_service.transcribe, audio_bytes)
        if not query or not query.strip():
            raise HTTPException(status_code=400, detail="Could not understand audio")
            
        # 3. Get Answer (RAG)
        result = await run_in_threadpool(rag_service.get_answer, query, session_id)
        answer_text = result["answer"]
        
        # 4. Synthesize (TTS)
        tts_bytes = await run_in_threadpool(tts_service.synthesize, answer_text)
        
        # 5. Encode to Base64
        audio_base64 = base64.b64encode(tts_bytes).decode("utf-8")
        
        return {
            "query": query,
            "answer": answer_text,
            "source": result["source"],
            "citations": result["citations"],
            "audio_base64": audio_base64
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Voice chat failed: {str(e)}")

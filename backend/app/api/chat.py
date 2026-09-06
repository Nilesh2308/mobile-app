from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel, Field
from typing import List, Dict, Any

from app.services.rag_service import rag_service

router = APIRouter()

class ChatRequest(BaseModel):
    query: str = Field(..., max_length=1000, description="The user's query text, max 1000 characters")
    session_id: str = Field(..., max_length=100)

class Citation(BaseModel):
    filename: str
    chunk_text: str
    score: float

from app.core.rate_limit import limiter

class ChatResponse(BaseModel):
    answer: str
    source: str
    citations: List[Citation]

from app.core.memory_store import session_memory

@router.post("/", response_model=ChatResponse)
@limiter.limit("5/minute")
async def chat(request: Request, body: ChatRequest):
    result = rag_service.get_answer(query=body.query, session_id=body.session_id)
    return result

@router.delete("/session/{session_id}")
async def delete_session(session_id: str):
    success = session_memory.delete_session(session_id)
    if not success:
        return {"status": "ok", "message": "Session not found or already deleted"}
    return {"status": "ok", "message": "Session hard deleted"}

@router.get("/session/{session_id}")
async def get_session(session_id: str):
    history = session_memory.get_history(session_id)
    return {"messages": history}

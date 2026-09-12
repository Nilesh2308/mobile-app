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
@limiter.limit("30/minute")
async def chat(request: Request, body: ChatRequest):
    result = rag_service.get_answer(query=body.query, session_id=body.session_id)
    return result

@router.delete("/session/{session_id}")
async def delete_session(session_id: str):
    session_memory.delete_session(session_id)
    from app.services.kb_service import kb_service
    kb_service.clean_orphaned_points()
    return {"status": "ok", "message": "Session hard deleted"}

@router.delete("/clear")
async def clear_all_chats():
    session_memory.clear_all()
    from app.services.kb_service import kb_service
    kb_service.clean_orphaned_points()
    return {"status": "ok", "message": "All chat history permanently deleted"}

@router.get("/session/{session_id}")
async def get_session(session_id: str):
    history = session_memory.get_history(session_id)
    return {"messages": history}

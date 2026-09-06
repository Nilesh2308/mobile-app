from fastapi import APIRouter, UploadFile, File, HTTPException
from typing import List
from app.services.kb_service import kb_service
from pydantic import BaseModel

router = APIRouter()

class DocumentResponse(BaseModel):
    doc_id: str
    filename: str
    upload_timestamp: int
    chunk_count: int

MAX_FILES = 10

@router.post("/upload")
async def upload_documents(files: List[UploadFile] = File(...)):
    if not files:
        raise HTTPException(status_code=400, detail="No files provided")
    if len(files) > MAX_FILES:
        raise HTTPException(status_code=400, detail=f"Too many files. Max {MAX_FILES} allowed.")
        
    result = await kb_service.process_uploads(files)
    
    return result

@router.get("/documents", response_model=List[DocumentResponse])
async def list_documents():
    return kb_service.list_documents()

@router.delete("/documents/{doc_id}")
async def delete_document(doc_id: str):
    success = kb_service.delete_document(doc_id)
    if not success:
        raise HTTPException(status_code=500, detail="Failed to delete document")
    return {"status": "success", "message": f"Document {doc_id} deleted."}

@router.get("/summary")
async def get_domain_summary():
    summary = kb_service.get_domain_summary()
    return {"summary": summary}

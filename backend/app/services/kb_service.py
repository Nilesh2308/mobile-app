import uuid
import time
import json
import os
import logging
from typing import List, Dict, Any
from fastapi import UploadFile

from app.core.qdrant_client import qdrant_db
from app.core.config import settings
from app.core.embeddings import embedding_service
from app.core.groq_client import groq_service
from app.services.document_parser import DocumentParser
from app.services.chunker import RecursiveCharacterTextSplitter
from qdrant_client.models import PointStruct, Filter, FieldCondition, MatchValue

logger = logging.getLogger(__name__)

class KBService:
    def __init__(self):
        self.chunker = RecursiveCharacterTextSplitter(chunk_size=800, chunk_overlap=100)
        self.data_dir = os.path.join(os.path.dirname(__file__), "../../data")
        os.makedirs(self.data_dir, exist_ok=True)
        self.summary_file = os.path.join(self.data_dir, "domain_summary.json")

    async def process_uploads(self, files: List[UploadFile]) -> Dict[str, Any]:
        total_chunks_created = 0
        processed_files = []
        errors = []
        
        all_chunks = []
        all_metadata = []
        
        # Parse and chunk
        for file in files:
            try:
                content = await file.read()
                if not content:
                    errors.append(f"{file.filename}: Empty file")
                    continue
                    
                text = DocumentParser.parse(content, file.filename)
                chunks = self.chunker.split_text(text)
                
                if not chunks:
                    errors.append(f"{file.filename}: No text extracted")
                    continue
                    
                doc_id = str(uuid.uuid4())
                upload_time = int(time.time())
                
                for i, chunk in enumerate(chunks):
                    all_chunks.append(chunk)
                    all_metadata.append({
                        "doc_id": doc_id,
                        "filename": file.filename,
                        "chunk_index": i,
                        "upload_timestamp": upload_time,
                        "text": chunk # store text for retrieval
                    })
                    
                total_chunks_created += len(chunks)
                processed_files.append({
                    "filename": file.filename,
                    "doc_id": doc_id,
                    "chunks": len(chunks)
                })
            except Exception as e:
                logger.error(f"Error processing file {file.filename}: {e}")
                errors.append(f"{file.filename}: {str(e)}")

        if all_chunks:
            # Embed all chunks in batches
            batch_size = 32
            embeddings = []
            for i in range(0, len(all_chunks), batch_size):
                batch_texts = all_chunks[i:i+batch_size]
                batch_emb = embedding_service.embed_documents(batch_texts)
                embeddings.extend(batch_emb)
                
            # Store in Qdrant
            points = []
            for i, emb in enumerate(embeddings):
                points.append(
                    PointStruct(
                        id=str(uuid.uuid4()),
                        vector=emb,
                        payload=all_metadata[i]
                    )
                )
            
            client = qdrant_db.get_client()
            client.upsert(
                collection_name=qdrant_db.collection_name,
                points=points
            )
            
            # Generate domain summary based on a sample
            self._update_domain_summary(all_chunks, [f["filename"] for f in processed_files])
            
        return {
            "processed_files": processed_files,
            "total_chunks": total_chunks_created,
            "errors": errors
        }

    def _update_domain_summary(self, recent_chunks: List[str], filenames: List[str]):
        try:
            # Take a sample of chunks (max 5)
            sample_chunks = recent_chunks[:5]
            prompt = (
                f"I just uploaded some documents to my knowledge base. The files are: {', '.join(filenames)}.\n"
                f"Here are some excerpts from the text:\n"
                f"{' '.join(sample_chunks)}\n\n"
                "Based on this, write a short, 2-3 line domain summary describing what this knowledge base is about."
            )
            
            summary = groq_service.generate_text(
                messages=[
                    {"role": "system", "content": "You are an assistant that summarizes knowledge base domains."},
                    {"role": "user", "content": prompt}
                ],
                model=settings.GROQ_FAST_MODEL
            )
            
            # Save to JSON
            with open(self.summary_file, "w", encoding="utf-8") as f:
                json.dump({"summary": summary.strip()}, f)
                
            logger.info("Updated domain summary successfully.")
        except Exception as e:
            logger.error(f"Failed to update domain summary: {e}")

    def list_documents(self) -> List[Dict[str, Any]]:
        client = qdrant_db.get_client()
        # Scroll through all points to aggregate documents
        # For a large KB, this would need a separate DB or proper aggregations, 
        # but for simple setup, scroll and group is fine.
        records, _ = client.scroll(
            collection_name=qdrant_db.collection_name,
            limit=10000,
            with_payload=True,
            with_vectors=False
        )
        
        docs_map = {}
        for r in records:
            payload = r.payload
            doc_id = payload.get("doc_id")
            if doc_id and doc_id not in docs_map:
                docs_map[doc_id] = {
                    "doc_id": doc_id,
                    "filename": payload.get("filename"),
                    "upload_timestamp": payload.get("upload_timestamp"),
                    "chunk_count": 1
                }
            elif doc_id:
                docs_map[doc_id]["chunk_count"] += 1
                
        return list(docs_map.values())

    def delete_document(self, doc_id: str) -> bool:
        client = qdrant_db.get_client()
        result = client.delete(
            collection_name=qdrant_db.collection_name,
            points_selector=Filter(
                must=[
                    FieldCondition(
                        key="doc_id",
                        match=MatchValue(value=doc_id)
                    )
                ]
            )
        )
        return result.status == "completed"

    def get_domain_summary(self) -> str:
        try:
            if os.path.exists(self.summary_file):
                with open(self.summary_file, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    return data.get("summary", "")
        except Exception as e:
            logger.error(f"Failed to read domain summary: {e}")
        return ""

kb_service = KBService()

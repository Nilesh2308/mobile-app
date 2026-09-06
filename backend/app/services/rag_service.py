import os
import json
import logging
from typing import Dict, Any

from app.core.config import settings
from app.core.qdrant_client import qdrant_db
from app.core.embeddings import embedding_service
from app.core.groq_client import groq_service
from app.core.memory_store import session_memory
from app.core.analytics import analytics_store

logger = logging.getLogger(__name__)

class RAGService:
    def __init__(self):
        self.threshold = settings.RELEVANCE_SCORE_THRESHOLD
        self.summary_file = os.path.join(os.path.dirname(__file__), "../../data/domain_summary.json")

    def _get_domain_summary(self) -> str:
        if os.path.exists(self.summary_file):
            try:
                with open(self.summary_file, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    return data.get("summary", "Unknown Domain")
            except Exception as e:
                logger.error(f"Failed to read domain summary: {e}")
        return "Unknown Domain"

    def _fallback_to_general_or_refuse(self, query: str, formatted_history: list):
        domain_summary = self._get_domain_summary()
        
        check_prompt = (
            f"Here is a summary of a knowledge base's domain:\n{domain_summary}\n\n"
            f"Is the following user question topically related to this domain?\n"
            f"Answer strictly YES or NO.\n"
            f"Question: {query}"
        )
        
        check_messages = [
            {"role": "system", "content": "You are a classification assistant."},
            {"role": "user", "content": check_prompt}
        ]
        
        relevance_check = groq_service.generate_text(
            messages=check_messages, 
            model=settings.GROQ_FAST_MODEL
        ).strip().upper()
        
        if "YES" in relevance_check:
            system_prompt = (
                "You are a helpful, conversational AI assistant. Answer the user's question to the best of your ability "
                "based on your general knowledge. Provide a well-balanced, informative answer (around 2-4 sentences) that is "
                "neither too brief nor overly verbose. Do not list sources."
            )
            messages = [{"role": "system", "content": system_prompt}] + formatted_history + [
                {"role": "user", "content": query}
            ]
            
            raw_answer = groq_service.generate_text(messages=messages, model=settings.GROQ_LLM_MODEL)
            prefix = "This isn't in your uploaded documents, but here's what I know generally:\n\n"
            return prefix + raw_answer, "llm_general", []
        else:
            domain_name = domain_summary.split('.')[0] if domain_summary != "Unknown Domain" else "this topic"
            return f"Sorry, I can only answer questions related to {domain_name}. Please ask something related to that.", "refused", []

    def get_answer(self, query: str, session_id: str) -> Dict[str, Any]:
        # Step 1: Embed query and search
        query_embedding = embedding_service.embed_query(query)
        
        client = qdrant_db.get_client()
        search_results = client.query_points(
            collection_name=qdrant_db.collection_name,
            query=query_embedding,
            limit=5,
            with_payload=True
        ).points

        with open("debug_scores.txt", "w") as f:
            for res in search_results:
                f.write(f"{res.score} - {res.payload.get('text', '')[:50]}\n")

        # Filter by threshold
        good_matches = [res for res in search_results if res.score >= self.threshold]

        history = session_memory.get_history(session_id)
        
        # Format history for Groq
        formatted_history = []
        for msg in history:
            formatted_history.append({"role": msg["role"], "content": msg["content"]})

        if good_matches:
            # Path 1: Answer strictly from retrieved chunks
            context_texts = []
            citations = []
            for match in good_matches:
                payload = match.payload
                text = payload.get("text", "")
                filename = payload.get("filename", "unknown")
                context_texts.append(f"Source: {filename}\n{text}")
                citations.append({
                    "filename": filename,
                    "chunk_text": text[:200] + "..." if len(text) > 200 else text,
                    "score": match.score
                })
                
            combined_context = "\n\n---\n\n".join(context_texts)
            
            system_prompt = (
                "You are a helpful, conversational AI assistant. Answer the user's question directly and informatively "
                "using ONLY the provided context. Provide a well-balanced answer (around 2-4 sentences) that is neither "
                "too brief nor overly verbose. Do NOT explain your reasoning, do NOT list sources, and do NOT use phrases "
                "like 'According to the context'. Keep the tone natural and conversational. If the context does not contain "
                "the answer, say you don't know."
            )
            
            messages = [{"role": "system", "content": system_prompt}] + formatted_history + [
                {"role": "user", "content": f"Context:\n{combined_context}\n\nQuestion: {query}"}
            ]
            
            answer = groq_service.generate_text(messages=messages, model=settings.GROQ_LLM_MODEL)
            
            lower_ans = answer.lower()
            if "i don't know" in lower_ans or "i do not know" in lower_ans or "context does not contain" in lower_ans:
                answer, source, citations = self._fallback_to_general_or_refuse(query, formatted_history)
            else:
                source = "knowledge_base"
            
        else:
            answer, source, citations = self._fallback_to_general_or_refuse(query, formatted_history)

        # Update session memory
        session_memory.add_turn(session_id, query, answer)
        
        # Track analytics
        analytics_store.increment_query(source)
        
        return {
            "answer": answer,
            "source": source,
            "citations": citations
        }

rag_service = RAGService()

import os
import re
import json
import logging
from typing import Dict, Any, List, Optional

from app.core.config import settings
from app.core.qdrant_client import qdrant_db
from app.core.embeddings import embedding_service
from app.core.qwen_client import qwen_service
from app.core.memory_store import session_memory
from app.core.analytics import analytics_store
from app.services.kb_service import kb_service
from qdrant_client.models import Filter, FieldCondition, MatchValue

logger = logging.getLogger(__name__)

class RAGService:
    def __init__(self):
        self.threshold = settings.RELEVANCE_SCORE_THRESHOLD

    def _classify_conversational(self, query: str) -> Optional[str]:
        q = query.strip().lower()
        q_clean = re.sub(r"[^\w\s]", "", q).strip()

        # 1. Gratitude / Thankful messages
        gratitude_phrases = {
            "thank you", "thanks", "thank u", "thx", "tysm", 
            "thank you so much", "thanks a lot", "many thanks", 
            "appreciate it", "much appreciated", "thanks buddy", 
            "thanks bro", "thank you very much"
        }
        if q_clean in gratitude_phrases or any(q_clean.startswith(p) for p in ["thank you", "thanks"]):
            return "gratitude"

        # 2. Acknowledgements / Agreement / Affirmations
        ack_phrases = {
            "ok", "okay", "k", "alright", "all right", "got it", 
            "understood", "noted", "cool", "great", "nice", "awesome", 
            "perfect", "sounds good", "sure", "fine", "yep", "yeah", 
            "yes", "no problem", "all good", "done", "super", 
            "ok got it", "okay got it", "clear", "makes sense"
        }
        if q_clean in ack_phrases:
            return "acknowledgement"

        # 3. Farewells / Closures
        farewell_phrases = {
            "bye", "goodbye", "see you", "cya", "take care", 
            "have a good day", "have a great day", "bye bye", "good night"
        }
        if q_clean in farewell_phrases or any(q_clean.startswith(p) for p in ["bye", "goodbye", "see you"]):
            return "farewell"

        # 4. Greetings / Pleasantries
        greeting_phrases = {
            "hi", "hello", "hey", "hii", "hiii", "heyy", "hola",
            "good morning", "good afternoon", "good evening", "good day",
            "how are you", "how are you doing", "how r u", "whats up", "what's up",
            "who are you", "what can you do", "help", "namaste"
        }
        if q_clean in greeting_phrases or any(q_clean.startswith(p) for p in ["hi ", "hello ", "hey ", "good morning", "good evening", "how are you"]):
            return "greeting"

        return None

    def _handle_conversational(self, query: str, intent: str, formatted_history: List[dict], num_docs: int, doc_names: List[str], is_voice: bool = False) -> str:
        kb_context_note = (
            f"The user has {num_docs} document(s) uploaded in their Knowledge Base: {', '.join(doc_names)}."
            if num_docs > 0
            else "The user currently has no documents uploaded in their Knowledge Base."
        )

        voice_note = "VOICE CONVERSATION: Keep your response short, natural, and speakable in 1-2 friendly sentences. Never use emojis, emoticons, or smileys as the text will be spoken aloud.\n" if is_voice else ""

        system_prompt = (
            "You are a friendly, highly intelligent, and professional enterprise SaaS conversational AI assistant.\n"
            f"System State: {kb_context_note}\n"
            f"{voice_note}\n"
            "Guidelines:\n"
            "1. Respond warmly, naturally, and concisely (1-2 sentences) tailored to their message.\n"
            "2. If they express gratitude ('thank you', 'thanks'): graciously welcome them and offer further assistance with their documents.\n"
            "3. If they acknowledge ('okay', 'got it', 'alright'): affirm pleasantly (e.g. 'Great! Let me know if you have any more questions about your documents.').\n"
            "4. If they greet ('hi', 'hello'): greet them warmly and invite questions about their uploaded documents.\n"
            "5. If they say farewell ('bye'): wish them a wonderful day.\n"
            "6. Never invent fake information or repeat entire previous document passages unless requested."
        )

        messages = [{"role": "system", "content": system_prompt}] + formatted_history[-2:] + [
            {"role": "user", "content": query}
        ]
        return qwen_service.generate_text(messages=messages, model=None)

    def _is_document_overview_query(self, query: str) -> bool:
        q = query.lower().strip()
        q_norm = re.sub(r"[^\w\s]", " ", q)
        q_norm = " ".join(q_norm.split())

        overview_patterns = [
            r"what is (this|the|my|it) (document|file|pdf|kb|data|paper) about",
            r"what are (these|the|my|all) (documents|files|pdfs) about",
            r"tell me about (the|this|my|these|all) (document|documents|file|files|kb)",
            r"(summarize|summary|overview|brief) (of|the|this|all|my) (document|documents|files|kb)",
            r"summarize (this|the|my|all) (document|documents|file|files)",
            r"what (did|have) i (uploaded|upload|added|add)",
            r"what is (in|inside) (my|the) (kb|knowledge base|documents|files)",
            r"what (documents|files) (do i have|are in|are uploaded|did i upload)",
            r"explain (this|the|my) (document|file|upload)",
            r"what is this about",
            r"what is it about",
            r"what are they about",
            r"what is (the|this) (document|file) (all )?about",
            r"uploaded a document.*what is this about",
            r"uploaded.*tell me.*about",
            r"tell me.*all about that document",
            r"all about that document",
            r"all about (the|my|these) documents",
            r"what kind of document",
            r"how many documents",
            r"list (the|my|all) documents",
            r"can you tell me what is this about",
        ]

        for pattern in overview_patterns:
            if re.search(pattern, q_norm):
                return True

        has_upload = any(w in q_norm for w in ["uploaded", "upload", "added"])
        has_doc = any(w in q_norm for w in ["document", "documents", "file", "files", "pdf", "kb"])
        has_about = any(w in q_norm for w in ["what is this", "what is it", "about", "describe", "explain", "detail", "overview", "summary", "short"])

        if has_upload and (has_doc or has_about) and any(w in q_norm for w in ["what", "tell me", "explain", "describe", "about"]):
            return True

        if ("what is this" in q_norm or "what's this" in q_norm or "what is it" in q_norm) and (has_doc or has_upload):
            return True

        return False

    def _handle_document_overview(self, query: str, existing_docs: List[Dict[str, Any]], session_id: str, formatted_history: List[dict], is_voice: bool = False) -> Dict[str, Any]:
        client = qdrant_db.get_client()
        num_docs = len(existing_docs)
        
        doc_overviews = []
        citations = []
        
        for doc in existing_docs:
            doc_id = doc["doc_id"]
            filename = doc["filename"]
            
            # Retrieve the first 3 chunks of this document to understand its contents
            try:
                records, _ = client.scroll(
                    collection_name=qdrant_db.collection_name,
                    scroll_filter=Filter(
                        must=[
                            FieldCondition(
                                key="doc_id",
                                match=MatchValue(value=doc_id)
                            )
                        ]
                    ),
                    limit=3,
                    with_payload=True,
                    with_vectors=False
                )
                records = sorted(records, key=lambda r: r.payload.get("chunk_index", 0) if r.payload else 0)
                chunk_texts = [r.payload.get("text", "") for r in records if r.payload]
                sample_content = "\n".join(chunk_texts)[:1800]
            except Exception as e:
                logger.error(f"Error scrolling doc {doc_id}: {e}")
                sample_content = f"Uploaded document: {filename}"

            doc_overviews.append(f"--- Document Name: {filename} ---\n{sample_content}")
            citations.append({
                "filename": filename,
                "chunk_text": sample_content[:200] + "..." if len(sample_content) > 200 else sample_content,
                "score": 1.0
            })
            
        combined_docs_text = "\n\n".join(doc_overviews)
        filenames_list = [d["filename"] for d in existing_docs]
        
        if is_voice:
            system_prompt = (
                "You are an expert AI document assistant speaking directly to the user via voice audio.\n"
                f"The user has {num_docs} document(s) uploaded in their Knowledge Base: {', '.join(filenames_list)}.\n\n"
                "Voice Instructions:\n"
                "1. Keep your answer crisp, clear, and speakable in 2 to 3 sentences.\n"
                "2. State the document name(s) and a clear summary of what they cover (e.g. policy coverage, bills, certificates).\n"
                "3. Do not use complex markdown tables or bullet points; speak naturally like a human assistant.\n"
                "4. Never include emojis or emoticons in your response.\n"
                "5. Invite the user to ask any specific questions about the document."
            )
        else:
            system_prompt = (
                "You are an expert AI document analyst for an enterprise SaaS Knowledge Base platform.\n"
                "You speak like an intelligent, articulate, business-savvy AI assistant.\n"
                f"The user has {num_docs} document(s) uploaded in their Knowledge Base: {', '.join(filenames_list)}.\n\n"
                "Instructions:\n"
                "1. If 1 document is uploaded:\n"
                "   - State the document name clearly (e.g. 'You have 1 document uploaded: **filename**').\n"
                "   - Provide a clear, insightful executive summary of what this document is about.\n"
                "   - Highlight key metadata and core elements found in the text (such as document type, issuer/organization, dates, policy/invoice numbers, amounts, or main subject).\n"
                "   - Conclude by offering to answer any specific questions or extract details from it.\n"
                "2. If multiple documents (e.g. 2, 3, 4, etc.) are uploaded:\n"
                "   - Explicitly mention the total count: 'You have {num_docs} documents uploaded in your Knowledge Base:'\n"
                "   - Provide a structured, concise 1-2 sentence overview for EACH document explaining what it covers.\n"
                "   - Conclude by asking which document they would like to explore or compare.\n"
                "3. Format cleanly with markdown bolding and bullet points.\n"
                "4. Be confident, professional, and helpful like a high-end enterprise AI product."
            )
        
        messages = [
            {"role": "system", "content": system_prompt}
        ] + formatted_history[-2:] + [
            {"role": "user", "content": f"Document excerpts from Knowledge Base:\n{combined_docs_text}\n\nUser Question: {query}"}
        ]
        
        answer = qwen_service.generate_text(messages=messages, model=None)
        source = "knowledge_base"
        
        session_memory.add_turn(session_id, query, answer)
        analytics_store.increment_query(source)
        
        return {
            "answer": answer,
            "source": source,
            "citations": citations
        }

    def get_answer(self, query: str, session_id: str, is_voice: bool = False) -> Dict[str, Any]:
        history = session_memory.get_history(session_id)
        formatted_history = [{"role": msg["role"], "content": msg["content"]} for msg in history]

        # 1. Check if Knowledge Base contains any documents
        existing_docs = kb_service.list_documents()
        has_documents = len(existing_docs) > 0
        doc_names = [d["filename"] for d in existing_docs]

        # If KB is completely empty: instruct user to upload documents first
        if not has_documents:
            # Handle pure greetings even if empty, but remind to upload
            intent = self._classify_conversational(query)
            if intent in ["greeting", "gratitude", "farewell", "acknowledgement"]:
                answer = self._handle_conversational(query, intent, formatted_history, 0, [], is_voice=is_voice)
            else:
                answer = (
                    "You currently do not have any documents uploaded to your Knowledge Base. "
                    "I am designed to answer questions strictly based on your uploaded documents. "
                    "Please upload your documents (such as insurance policies, bills, certificates, or statements) "
                    "first, and then ask questions related to them."
                )
            source = "refused"
            citations = []
            session_memory.add_turn(session_id, query, answer)
            analytics_store.increment_query(source)
            return {
                "answer": answer,
                "source": source,
                "citations": citations
            }

        # 2. Handle Conversational Messages (Greetings, Gratitude, Acknowledgement, Farewells)
        intent = self._classify_conversational(query)
        if intent is not None:
            answer = self._handle_conversational(query, intent, formatted_history, len(existing_docs), doc_names, is_voice=is_voice)
            source = "llm_greeting"
            citations = []
            session_memory.add_turn(session_id, query, answer)
            analytics_store.increment_query(source)
            return {
                "answer": answer,
                "source": source,
                "citations": citations
            }

        # 3. Handle Document Overview / Summary / Meta Queries
        if self._is_document_overview_query(query):
            return self._handle_document_overview(query, existing_docs, session_id, formatted_history, is_voice=is_voice)

        # 4. KB has documents -> Vector Semantic Search in KB
        query_embedding = embedding_service.embed_query(query)
        client = qdrant_db.get_client()
        
        search_results = client.query_points(
            collection_name=qdrant_db.collection_name,
            query=query_embedding,
            limit=10,
            with_payload=True
        ).points

        valid_doc_ids = {doc["doc_id"] for doc in existing_docs}

        # Filter by active documents only
        active_matches = [
            res for res in search_results 
            if res.payload and res.payload.get("doc_id") in valid_doc_ids
        ]

        # Check if we have strong matches or need fallback inspection
        good_matches = [res for res in active_matches if res.score >= self.threshold]

        # If vector score is lower but active matches exist (e.g. tabular OCR, messy numbers, bills),
        # take top matches for LLM reasoning rather than prematurely refusing!
        selected_matches = good_matches if good_matches else active_matches[:4]

        if selected_matches:
            # Build context
            context_texts = []
            citations = []
            for match in selected_matches:
                payload = match.payload
                text = payload.get("text", "")
                filename = payload.get("filename", "unknown")
                context_texts.append(f"Source Document: {filename}\n{text}")
                citations.append({
                    "filename": filename,
                    "chunk_text": text[:200] + "..." if len(text) > 200 else text,
                    "score": match.score
                })

            combined_context = "\n\n---\n\n".join(context_texts)

            voice_rule = (
                "5. VOICE CONVERSATION RULE: The user is asking via voice audio. Keep your spoken answer concise, direct, and conversational (2 to 4 sentences). State key numbers or answers clearly without markdown tables or bullet lists. Never include emojis or emoticons in your response.\n"
                if is_voice else ""
            )

            # High-capability document extraction & comprehension prompt
            system_prompt = (
                "You are an expert AI assistant with powerful document reasoning and information extraction capabilities.\n"
                f"The user has {len(existing_docs)} document(s) uploaded in their Knowledge Base: {', '.join(doc_names)}.\n"
                "You are provided with excerpts from these uploaded documents "
                "(which may include invoices, mobile bills, vehicle insurance certificates, policy documents, medical records, financial statements, or unstructured text).\n\n"
                "Instructions:\n"
                "1. FIRST PRIORITY: Thoroughly analyze the provided context to answer the user's question accurately.\n"
                "2. Even if the text is messy, tabular, or unstructured, carefully locate and extract exact details requested "
                "(such as vehicle numbers, policy numbers, bill amounts, due dates, breakdown of charges, coverage limits, names, addresses, or dates).\n"
                "3. Provide a clear, natural, and accurate answer based strictly on the provided context. Do NOT use phrases like 'According to the context' or 'The document states'. Speak directly.\n"
                "4. STRICT SCOPE RULE: If the user's question is completely unrelated to their uploaded documents (e.g. outside world general trivia like 'who is prime minister of india', recipes, or external facts), "
                "you MUST politely respond with:\n"
                f"'This question is not related to your uploaded Knowledge Base document(s) ({', '.join(doc_names)}). "
                "I can only answer questions based on your uploaded documents. Please ask a question related to your uploaded files.'\n"
                "Do NOT answer with outside general knowledge.\n"
                f"{voice_rule}"
            )

            messages = [{"role": "system", "content": system_prompt}] + formatted_history[-6:] + [
                {"role": "user", "content": f"Context excerpts:\n{combined_context}\n\nQuestion: {query}"}
            ]

            answer = qwen_service.generate_text(messages=messages, model=None)

            # Determine whether answer was from KB or out-of-scope refusal
            lower_ans = answer.lower()
            if (
                "not related to your uploaded" in lower_ans
                or "not covered in your uploaded" in lower_ans
                or "only answer questions based on your uploaded" in lower_ans
                or "only answer questions related to your uploaded" in lower_ans
                or "outside the scope" in lower_ans
            ):
                source = "refused"
                citations = []
            else:
                source = "knowledge_base"

        else:
            # Zero matches found in database
            answer = (
                f"This question is not related to your uploaded Knowledge Base document(s) ({', '.join(doc_names)}). "
                "I can only answer questions based on the documents you have uploaded. "
                "Please ask a question related to your uploaded documents."
            )
            source = "refused"
            citations = []

        # Update session memory and analytics
        session_memory.add_turn(session_id, query, answer)
        analytics_store.increment_query(source)

        return {
            "answer": answer,
            "source": source,
            "citations": citations
        }

rag_service = RAGService()

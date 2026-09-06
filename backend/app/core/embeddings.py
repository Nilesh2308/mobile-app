import logging
from typing import List
from sentence_transformers import SentenceTransformer
from app.core.config import settings

logger = logging.getLogger(__name__)

class EmbeddingWrapper:
    def __init__(self):
        self.model = None
        self.model_name = settings.EMBEDDING_MODEL_NAME
        self.query_instruction = "Represent this sentence for searching relevant passages: "

    def load_model(self):
        try:
            logger.info(f"Loading embedding model: {self.model_name}")
            self.model = SentenceTransformer(self.model_name, local_files_only=True)
            logger.info("Embedding model loaded successfully.")
        except Exception as e:
            logger.error(f"Failed to load embedding model: {e}")
            raise

    def embed_texts(self, texts: List[str]) -> List[List[float]]:
        if not self.model:
            raise RuntimeError("Embedding model is not loaded.")
        embeddings = self.model.encode(texts, normalize_embeddings=True)
        return embeddings.tolist()

    def embed_query(self, query: str) -> List[float]:
        if not self.model:
            raise RuntimeError("Embedding model is not loaded.")
        # Prepend query instruction for bge models
        instruct_query = f"{self.query_instruction}{query}"
        embedding = self.model.encode([instruct_query], normalize_embeddings=True)[0]
        return embedding.tolist()

    def embed_documents(self, documents: List[str]) -> List[List[float]]:
        # Documents do not get the instruction prefix
        return self.embed_texts(documents)

embedding_service = EmbeddingWrapper()

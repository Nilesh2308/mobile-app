import logging
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams
from app.core.config import settings

logger = logging.getLogger(__name__)

class QdrantWrapper:
    def __init__(self):
        self.client = None
        self.collection_name = settings.QDRANT_COLLECTION_NAME

    def connect(self):
        try:
            # Use local file-based Qdrant instead of a running server
            self.client = QdrantClient(path="local_qdrant_data")
            self._ensure_collection_exists()
            logger.info("Qdrant client initialized and collection verified.")
        except Exception as e:
            logger.error(f"Failed to initialize Qdrant client: {e}")
            raise

    def _ensure_collection_exists(self):
        if not self.client.collection_exists(collection_name=self.collection_name):
            logger.info(f"Collection {self.collection_name} does not exist. Creating...")
            self.client.create_collection(
                collection_name=self.collection_name,
                vectors_config=VectorParams(size=384, distance=Distance.COSINE),
            )
            logger.info(f"Collection {self.collection_name} created successfully.")

    def get_client(self) -> QdrantClient:
        if not self.client:
            self.connect()
        return self.client

qdrant_db = QdrantWrapper()

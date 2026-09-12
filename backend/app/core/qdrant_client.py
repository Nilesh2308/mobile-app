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
            # Check if Qdrant Cloud or remote server is configured
            is_remote = (
                settings.QDRANT_URL
                and not settings.QDRANT_URL.startswith("http://localhost")
                and not settings.QDRANT_URL.startswith("http://127.0.0.1")
            )
            if is_remote:
                logger.info(f"Connecting to Qdrant Cloud at {settings.QDRANT_URL}...")
                self.client = QdrantClient(
                    url=settings.QDRANT_URL,
                    api_key=settings.QDRANT_API_KEY if settings.QDRANT_API_KEY else None,
                    timeout=30.0
                )
            else:
                logger.info("Using local embedded Qdrant storage ('local_qdrant_data').")
                self.client = QdrantClient(path="local_qdrant_data")

            self._ensure_collection_exists()
            logger.info("Qdrant client initialized and collection verified.")
        except Exception as e:
            logger.error(f"Failed to initialize Qdrant client: {e}")
            raise

    def _ensure_collection_exists(self):
        from qdrant_client.models import PayloadSchemaType
        if not self.client.collection_exists(collection_name=self.collection_name):
            logger.info(f"Collection {self.collection_name} does not exist. Creating...")
            self.client.create_collection(
                collection_name=self.collection_name,
                vectors_config=VectorParams(size=384, distance=Distance.COSINE),
            )
            logger.info(f"Collection {self.collection_name} created successfully.")
        
        # Ensure payload indexes exist for efficient filtering
        try:
            self.client.create_payload_index(
                collection_name=self.collection_name,
                field_name="doc_id",
                field_schema=PayloadSchemaType.KEYWORD
            )
            self.client.create_payload_index(
                collection_name=self.collection_name,
                field_name="filename",
                field_schema=PayloadSchemaType.KEYWORD
            )
        except Exception:
            pass

    def get_client(self) -> QdrantClient:
        if not self.client:
            self.connect()
        return self.client

qdrant_db = QdrantWrapper()

import logging
from groq import Groq
from app.core.config import settings

logger = logging.getLogger(__name__)

class GroqWrapper:
    def __init__(self):
        self.client = None

    def connect(self):
        try:
            if not settings.GROQ_API_KEY:
                logger.warning("GROQ_API_KEY is not set. Groq client will fail on usage.")
            self.client = Groq(api_key=settings.GROQ_API_KEY)
            logger.info("Groq client initialized.")
        except Exception as e:
            logger.error(f"Failed to initialize Groq client: {e}")
            raise

    def get_client(self) -> Groq:
        if not self.client:
            self.connect()
        return self.client
    
    def generate_text(self, messages: list[dict], model: str = settings.GROQ_LLM_MODEL, temperature: float = 0.7) -> str:
        client = self.get_client()
        response = client.chat.completions.create(
            messages=messages,
            model=model,
            temperature=temperature
        )
        return response.choices[0].message.content

groq_service = GroqWrapper()

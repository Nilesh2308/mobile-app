import logging
import requests
from app.core.config import settings

logger = logging.getLogger(__name__)

class QwenWrapper:
    def __init__(self):
        self.api_url = settings.QWEN_API_URL
        self.api_key = settings.QWEN_API_KEY
        self.default_model = settings.QWEN_LLM_MODEL

    def generate_text(self, messages: list[dict], model: str = None, temperature: float = 0.7) -> str:
        if not self.api_key:
            logger.warning("QWEN_API_KEY is not set. API calls may fail.")
        
        target_model = model if model else self.default_model
        
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        
        payload = {
            "model": target_model,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": 512,
            "stream": False,
            "features": {
                "web_search": False
            }
        }
        
        try:
            response = requests.post(self.api_url, headers=headers, json=payload, timeout=60)
            response.raise_for_status()
            data = response.json()
            content = data["choices"][0]["message"]["content"]
            import re
            # Strip reasoning tokens <think>...</think> produced by Qwen3 models
            cleaned_content = re.sub(r"<think>.*?</think>", "", content, flags=re.DOTALL).strip()
            return cleaned_content if cleaned_content else content
        except Exception as e:
            logger.error(f"Error calling Qwen API: {e}")
            if hasattr(e, "response") and e.response is not None:
                logger.error(f"Response data: {e.response.text}")
            raise

qwen_service = QwenWrapper()

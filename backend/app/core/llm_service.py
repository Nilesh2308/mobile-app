import logging
import re
from typing import List, Dict, Optional
from app.core.config import settings
from app.core.qwen_client import qwen_service

logger = logging.getLogger(__name__)

try:
    from groq import Groq
    GROQ_AVAILABLE = True
except ImportError:
    GROQ_AVAILABLE = False


class LLMService:
    def __init__(self):
        self.groq_client: Optional[Groq] = None
        self._init_groq()

    def _init_groq(self):
        groq_key = getattr(settings, "GROQ_API_KEY", "")
        if GROQ_AVAILABLE and groq_key:
            try:
                self.groq_client = Groq(api_key=groq_key)
                model_name = getattr(settings, "GROQ_LLM_MODEL", "openai/gpt-oss-20b")
                logger.info(f"Groq Cloud LPU LLM initialized (Model: {model_name})")
            except Exception as e:
                logger.warning(f"Could not initialize Groq LLM client: {e}")

    def generate_text(
        self,
        messages: List[Dict[str, str]],
        model: Optional[str] = None,
        temperature: float = 0.3,
        max_tokens: int = 512,
        is_voice: bool = False
    ) -> str:
        """
        Ultra-low latency LLM generation.
        Primary: Groq Cloud LPU (~0.4s - 0.7s response time, 800 tokens/sec).
        Fallback: Qwen remote endpoint.
        """
        # Ensure client is ready
        if not self.groq_client:
            self._init_groq()

        # For voice queries, constrain tokens to 180 for snappy spoken audio turnaround
        effective_max_tokens = 180 if is_voice else max_tokens

        # 1. Primary: Groq LPU
        if getattr(settings, "USE_GROQ_LLM", True) and self.groq_client:
            target_model = model or getattr(settings, "GROQ_LLM_MODEL", "openai/gpt-oss-20b")
            try:
                response = self.groq_client.chat.completions.create(
                    model=target_model,
                    messages=messages,
                    temperature=temperature,
                    max_tokens=effective_max_tokens,
                )
                content = response.choices[0].message.content or ""
                # Strip thinking tokens if produced by any reasoning model
                content = re.sub(r"<think>.*?</think>", "", content, flags=re.DOTALL).strip()
                if content:
                    return content
            except Exception as e:
                logger.warning(f"Groq LLM failed ({e}), falling back to Qwen...")

        # 2. Fallback: Qwen Service
        try:
            return qwen_service.generate_text(messages=messages, model=None, temperature=temperature)
        except Exception as qe:
            logger.error(f"Fallback Qwen API also failed: {qe}")
            raise


llm_service = LLMService()

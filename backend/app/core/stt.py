import logging
import io
import torch
from faster_whisper import WhisperModel
from app.core.config import settings

logger = logging.getLogger(__name__)

class STTWrapper:
    def __init__(self):
        self.model = None
        self.model_size = settings.WHISPER_MODEL_SIZE
        
    def load_model(self):
        try:
            device = "cuda" if torch.cuda.is_available() else "cpu"
            compute_type = "float16" if device == "cuda" else "int8"
            
            logger.info(f"Loading Whisper model ({self.model_size}) on {device} with {compute_type}")
            self.model = WhisperModel(self.model_size, device=device, compute_type=compute_type, local_files_only=True)
            logger.info("Whisper model loaded successfully.")
        except Exception as e:
            logger.error(f"Failed to load Whisper model: {e}")
            raise

    def transcribe(self, audio_bytes: bytes) -> str:
        if not self.model:
            raise RuntimeError("Whisper model is not loaded.")
        
        # faster-whisper accepts binary streams
        audio_stream = io.BytesIO(audio_bytes)
        
        segments, info = self.model.transcribe(audio_stream, beam_size=5)
        
        text = " ".join([segment.text for segment in segments])
        return text.strip()

stt_service = STTWrapper()

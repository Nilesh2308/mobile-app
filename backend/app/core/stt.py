import logging
import io
from app.core.config import settings

logger = logging.getLogger(__name__)

# Check for faster_whisper availability without crashing if absent
try:
    import torch
    from faster_whisper import WhisperModel
    FASTER_WHISPER_AVAILABLE = True
except ImportError:
    FASTER_WHISPER_AVAILABLE = False

try:
    from groq import Groq
    GROQ_AVAILABLE = True
except ImportError:
    GROQ_AVAILABLE = False


class STTWrapper:
    def __init__(self):
        self.local_model = None
        self.model_size = settings.WHISPER_MODEL_SIZE
        self.groq_client = None
        self.groq_backup_client = None
        self.engine = getattr(settings, "STT_ENGINE", "groq")
        self.groq_model = getattr(settings, "GROQ_WHISPER_MODEL", "whisper-large-v3-turbo")

    @property
    def model(self):
        return self.groq_client or self.local_model


    def load_model(self):
        # 1. Initialize Groq Cloud Whisper client
        groq_key = getattr(settings, "GROQ_API_KEY", "")
        if GROQ_AVAILABLE and groq_key:
            try:
                self.groq_client = Groq(api_key=groq_key)
                logger.info(f"Groq Cloud Whisper STT initialized (Model: {self.groq_model})")
            except Exception as e:
                logger.warning(f"Could not initialize primary Groq client: {e}")

        if GROQ_AVAILABLE and getattr(settings, "GROQ_API_KEY_BACKUP", None):
            try:
                self.groq_backup_client = Groq(api_key=settings.GROQ_API_KEY_BACKUP)
                logger.info("Groq Cloud Whisper backup client initialized")
            except Exception as e:
                logger.warning(f"Could not initialize backup Groq client: {e}")

        # 2. Only load local heavier faster-whisper if explicitly configured or Groq is not available
        if self.engine == "faster-whisper" or not self.groq_client:
            self._load_local_model()

    def _load_local_model(self):
        if not FASTER_WHISPER_AVAILABLE:
            logger.warning("faster-whisper library is not installed in this environment.")
            return

        try:
            device = "cuda" if torch.cuda.is_available() else "cpu"
            compute_type = "float16" if device == "cuda" else "int8"
            
            logger.info(f"Loading local Whisper model ({self.model_size}) on {device} with {compute_type}")
            self.local_model = WhisperModel(self.model_size, device=device, compute_type=compute_type)
            logger.info("Local Whisper model loaded successfully.")
        except Exception as e:
            logger.error(f"Failed to load local Whisper model: {e}")
            if self.engine == "faster-whisper":
                raise

    def transcribe(self, audio_bytes: bytes, filename: str = "audio.m4a") -> str:
        # Ensure Groq is ready
        if not self.groq_client and GROQ_AVAILABLE:
            self.load_model()

        # 1. Attempt Groq Cloud Whisper first (0.2s - 0.5s ultra-fast, 0 MB server RAM)
        if self.groq_client:
            try:
                return self._transcribe_groq(self.groq_client, audio_bytes, filename)
            except Exception as e:
                logger.warning(f"Primary Groq STT failed: {e}. Checking backup...")
                if self.groq_backup_client:
                    try:
                        return self._transcribe_groq(self.groq_backup_client, audio_bytes, filename)
                    except Exception as be:
                        logger.warning(f"Backup Groq STT failed: {be}")

        # 2. Fallback to local model if available
        if self.local_model:
            logger.info("Falling back to local faster-whisper model...")
            return self._transcribe_local(audio_bytes)

        # 3. If local model was not preloaded but library is available, try on-demand
        if FASTER_WHISPER_AVAILABLE and not self.local_model:
            try:
                self._load_local_model()
                if self.local_model:
                    return self._transcribe_local(audio_bytes)
            except Exception as e:
                logger.error(f"On-demand local model load failed: {e}")

        raise RuntimeError("STT transcription failed: No available STT engine (Groq or local).")

    def _transcribe_groq(self, client, audio_bytes: bytes, filename: str = "audio.m4a") -> str:
        ext = filename.split(".")[-1].lower() if "." in filename else "m4a"
        if ext not in ["m4a", "wav", "mp3", "ogg", "flac", "webm"]:
            ext = "m4a"
        upload_name = f"audio.{ext}"

        transcription = client.audio.transcriptions.create(
            file=(upload_name, audio_bytes),
            model=self.groq_model,
            temperature=0.0
        )
        return transcription.text.strip()

    def _transcribe_local(self, audio_bytes: bytes) -> str:
        audio_stream = io.BytesIO(audio_bytes)
        beam_size = getattr(settings, "WHISPER_BEAM_SIZE", 1)
        segments, info = self.local_model.transcribe(audio_stream, beam_size=beam_size, temperature=0.0)
        text = " ".join([segment.text for segment in segments])
        return text.strip()


stt_service = STTWrapper()


import logging
import io
import soundfile as sf
from app.core.config import settings

# Attempt to import kokoro components - this assumes misaki/kokoro is installed locally
try:
    from kokoro import KPipeline
    KOKORO_AVAILABLE = True
except ImportError:
    KOKORO_AVAILABLE = False
    
logger = logging.getLogger(__name__)

class TTSWrapper:
    def __init__(self):
        self.pipeline = None
        self.voice = settings.KOKORO_VOICE
        self.sample_rate = 24000

    def load_model(self):
        if not KOKORO_AVAILABLE:
            logger.warning("Kokoro library is not available. TTS will fail.")
            return

        try:
            logger.info("Loading Kokoro TTS model (American English)...")
            # Initialize pipeline for American English ('a'). Adjust if British ('b') is needed.
            self.pipeline = KPipeline(lang_code='a') 
            logger.info("Kokoro model loaded successfully.")
        except Exception as e:
            logger.error(f"Failed to load Kokoro model: {e}")
            raise

    def synthesize(self, text: str) -> bytes:
        if not self.pipeline:
            raise RuntimeError("Kokoro model is not loaded or not available.")
            
        generator = self.pipeline(
            text, voice=self.voice, # <= change voice here
            speed=1, split_pattern=r'\n+'
        )
        
        # Accumulate audio data
        audio_data = []
        for i, (gs, ps, audio) in enumerate(generator):
            audio_data.extend(audio)
            
        if not audio_data:
            return b""
            
        # Convert to WAV bytes
        import numpy as np
        audio_np = np.array(audio_data)
        
        buffer = io.BytesIO()
        sf.write(buffer, audio_np, self.sample_rate, format='WAV', subtype='PCM_16')
        
        return buffer.getvalue()

tts_service = TTSWrapper()

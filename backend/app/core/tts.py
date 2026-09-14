import logging
import io
import re
import asyncio
from typing import Optional
import soundfile as sf
from app.core.config import settings

# Attempt to import edge_tts
try:
    import edge_tts
    EDGE_TTS_AVAILABLE = True
except ImportError:
    EDGE_TTS_AVAILABLE = False

# Attempt to import kokoro components
try:
    from kokoro import KPipeline
    KOKORO_AVAILABLE = True
except ImportError:
    KOKORO_AVAILABLE = False

# Attempt to import gTTS (Google Cloud TTS fallback)
try:
    from gtts import gTTS
    GTTS_AVAILABLE = True
except ImportError:
    GTTS_AVAILABLE = False


logger = logging.getLogger(__name__)

# Comprehensive emoji pattern matching all Unicode emoji blocks, pictographs, and symbols
_EMOJI_PATTERN = re.compile(
    '['
    '\U00010000-\U0010FFFF'  # All supplemental/astral plane emojis, pictographs, flags
    '\U00002600-\U000027BF'  # Miscellaneous symbols & dingbats
    '\U00002300-\U000023FF'  # Miscellaneous technical
    '\U00002B50-\U00002B55'  # Stars and shapes
    '\U0000FE00-\U0000FE0F'  # Variation selectors
    '\U0000200D'             # Zero-width joiners
    ']+',
    flags=re.UNICODE
)

def clean_tts_text(text: str) -> str:
    """
    Strip emojis, smilies, markdown markers, thinking tags, and symbols
    so natural speech synthesis only pronounces real spoken words without
    reading emoji descriptions (e.g. 'smiling face', 'thumbs up').
    """
    if not text:
        return ""
    # Strip reasoning tags
    t = re.sub(r'<think>.*?</think>', '', text, flags=re.DOTALL)
    # Strip all Unicode emojis and pictographs
    t = _EMOJI_PATTERN.sub('', t)
    # Strip common ASCII text emoticons (e.g., :), :-), :D, ;), <3)
    t = re.sub(r'(?:[:;=8][\-\^]?[)D(\[\]{}@|/\\pP])', '', t)
    t = re.sub(r'<3', '', t)
    # Remove markdown links, keep label
    t = re.sub(r'\[([^\]]+)\]\([^\)]+\)', r'\1', t)
    # Remove bold, italics, code backticks, headers, tildes
    t = re.sub(r'[*_#`~]', '', t)
    # Remove bullet markers
    t = re.sub(r'^\s*[-*•]\s+', '', t, flags=re.MULTILINE)
    # Collapse multiple newlines into a sentence pause
    t = re.sub(r'\n+', '. ', t)
    # Clean redundant spaces and space before punctuation
    t = re.sub(r'\s+', ' ', t)
    t = re.sub(r'\s+([.,!?;:])', r'\1', t).strip()
    return t

class TTSWrapper:
    def __init__(self):
        self.pipeline = None
        self.engine = settings.TTS_ENGINE
        self.edge_voice = settings.EDGE_TTS_VOICE
        self.kokoro_voice = settings.KOKORO_VOICE
        self.sample_rate = 24000

    def load_model(self):
        logger.info(f"Initializing TTS Service (Engine: {self.engine}, Edge-TTS Available: {EDGE_TTS_AVAILABLE})")
        if self.engine == "kokoro" or not EDGE_TTS_AVAILABLE:
            if not KOKORO_AVAILABLE:
                logger.warning("Neither Edge-TTS nor Kokoro library is available.")
                return
            try:
                logger.info("Loading Kokoro TTS model (American English)...")
                self.pipeline = KPipeline(lang_code='a')
                logger.info("Kokoro model loaded successfully.")
            except Exception as e:
                logger.error(f"Failed to load Kokoro model: {e}")
                if self.engine == "kokoro":
                    raise

    async def _synthesize_edge(self, text: str) -> bytes:
        """Synthesize using high-speed, realistic Microsoft Edge neural voice (~1s)."""
        clean_text = clean_tts_text(text)
        if not clean_text:
            return b""
        rate = getattr(settings, "TTS_RATE", "+15%")
        communicate = edge_tts.Communicate(clean_text, self.edge_voice, rate=rate)
        audio_data = bytearray()

        async def _stream_chunks():
            async for chunk in communicate.stream():
                if chunk["type"] == "audio":
                    audio_data.extend(chunk["data"])

        # Timeout after 4 seconds to avoid Render cloud stalls
        await asyncio.wait_for(_stream_chunks(), timeout=4.0)
        return bytes(audio_data)

    def _synthesize_kokoro(self, text: str) -> bytes:
        """Fallback local synthesis using Kokoro-82M."""
        if not self.pipeline:
            if KOKORO_AVAILABLE:
                self.pipeline = KPipeline(lang_code='a')
            else:
                raise RuntimeError("Kokoro model is not loaded or not available.")

        clean_text = clean_tts_text(text)
        generator = self.pipeline(
            clean_text, voice=self.kokoro_voice,
            speed=1, split_pattern=r'\n+'
        )
        audio_data = []
        for i, (gs, ps, audio) in enumerate(generator):
            audio_data.extend(audio)

        if not audio_data:
            return b""

        import numpy as np
        audio_np = np.array(audio_data)
        buffer = io.BytesIO()
        sf.write(buffer, audio_np, self.sample_rate, format='WAV', subtype='PCM_16')
        return buffer.getvalue()

    def _synthesize_gtts(self, text: str) -> bytes:
        """Reliable Google TTS fallback that works 100% in cloud datacenters."""
        clean_text = clean_tts_text(text)
        if not clean_text:
            return b""
        try:
            from gtts import gTTS
            fp = io.BytesIO()
            tts = gTTS(text=clean_text, lang='en', tld='com')
            tts.write_to_fp(fp)
            return fp.getvalue()
        except Exception as e:
            logger.error(f"gTTS fallback failed: {e}")
            return b""

    def synthesize(self, text: str) -> bytes:
        """
        Synchronous wrapper: prioritize Edge-TTS, fallback to gTTS (guaranteed in cloud),
        then local Kokoro.
        """
        # 1. Try Edge-TTS
        if self.engine == "edge" and EDGE_TTS_AVAILABLE:
            try:
                try:
                    loop = asyncio.get_event_loop()
                    if loop.is_running():
                        import nest_asyncio
                        nest_asyncio.apply()
                        audio = loop.run_until_complete(self._synthesize_edge(text))
                    else:
                        audio = loop.run_until_complete(self._synthesize_edge(text))
                except RuntimeError:
                    audio = asyncio.run(self._synthesize_edge(text))
                if audio and len(audio) > 0:
                    return audio
            except Exception as e:
                logger.warning(f"Edge-TTS failed ({e}), falling back to gTTS...")

        # 2. Try gTTS (Google Cloud TTS)
        if GTTS_AVAILABLE:
            try:
                audio = self._synthesize_gtts(text)
                if audio and len(audio) > 0:
                    return audio
            except Exception as ge:
                logger.warning(f"gTTS failed: {ge}")

        # 3. Try Kokoro
        if KOKORO_AVAILABLE and self.pipeline is not None:
            return self._synthesize_kokoro(text)

        return b""

    async def synthesize_async(self, text: str) -> bytes:
        """Asynchronous synthesis for direct async FastAPI routes."""
        # 1. Try Edge-TTS
        if self.engine == "edge" and EDGE_TTS_AVAILABLE:
            try:
                audio = await self._synthesize_edge(text)
                if audio and len(audio) > 0:
                    return audio
            except Exception as e:
                logger.warning(f"Edge-TTS async failed ({e}), falling back to gTTS...")

        # 2. Try gTTS (Google Cloud TTS)
        if GTTS_AVAILABLE:
            try:
                from fastapi.concurrency import run_in_threadpool
                audio = await run_in_threadpool(self._synthesize_gtts, text)
                if audio and len(audio) > 0:
                    return audio
            except Exception as ge:
                logger.warning(f"gTTS async failed: {ge}")

        # 3. Try Kokoro
        if KOKORO_AVAILABLE and self.pipeline is not None:
            from fastapi.concurrency import run_in_threadpool
            return await run_in_threadpool(self._synthesize_kokoro, text)

        return b""

tts_service = TTSWrapper()


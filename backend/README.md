# Voice AI + RAG Backend

A FastAPI backend for a Retrieval-Augmented Generation (RAG) chatbot featuring local Voice AI capabilities.

## Architecture

This system blends **Local Edge AI** models for audio processing with **Cloud API** models for text intelligence:

### Local Components (CPU/GPU-bound)
1. **Qdrant**: Vector database running locally via Docker.
2. **Embeddings**: `BAAI/bge-small-en-v1.5` loaded locally via `sentence-transformers`.
3. **Speech-to-Text (STT)**: `faster-whisper` (medium) loaded locally.
4. **Text-to-Speech (TTS)**: Kokoro model loaded locally.

### Cloud API Components (Network-bound)
1. **LLM Generation**: Groq API using `llama-3.3-70b-versatile`.
2. **Fast Domain Classification**: Groq API using `llama-3.1-8b-instant`.

## System Requirements
- **RAM**: Minimum 16GB (recommended 32GB) to comfortably load Whisper, Kokoro, and the BGE embeddings models simultaneously.
- **GPU (Optional)**: A CUDA-enabled NVIDIA GPU with at least 8GB VRAM will significantly speed up STT and TTS generation.
- **Docker**: Required to run the local Qdrant instance.

## Setup Instructions

1. **Start the Vector DB**:
   ```bash
   docker-compose up -d
   ```

2. **Install Dependencies**:
   It is highly recommended to use a virtual environment (`venv`).
   ```bash
   pip install -r requirements.txt
   ```
   *Note: Ensure your local Kokoro dependencies are properly installed as per their documentation.*

3. **Configure Environment Variables**:
   Copy the example environment file:
   ```bash
   cp .env.example .env
   ```
   Add your `GROQ_API_KEY` to the `.env` file.

4. **Run the Server**:
   ```bash
   uvicorn app.main:app --reload
   ```

## API Endpoints

- `GET /api/health`: Health status of all connected AI models.
- `GET /api/stats`: In-memory analytics counter.
- `POST /api/kb/upload`: Upload documents (`.txt`, `.pdf`, `.docx`) for ingestion.
- `POST /api/chat`: Send a text query for the RAG pipeline.
- `POST /api/voice/chat`: Send an audio file query and receive a spoken `base64` audio response.

## Known Limitations
Currently, this system does not employ a relational database. As a result:
- The **Domain Summary** is stored ephemerally in a local `data/domain_summary.json` file.
- **Session Histories** are stored in-memory and will be lost on server restart. A background task cleans up sessions after 30 minutes of inactivity.
- **Analytics Metrics** (`/api/stats`) are stored in-memory and reset on server restart.

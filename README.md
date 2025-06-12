# Embedding Server

This is an optimized Flask server that provides text embeddings using the `sentence-transformers` library with the `all-mpnet-base-v2` model (768-dimensional embeddings for high quality).

---

## Files

- `app.py` — Flask server code with embedding endpoint
- `requirements.txt` — Python dependencies
- `run_server.py` — Script to install dependencies and run the server (legacy)
- `Dockerfile` — Multi-stage Docker build for minimal image size
- `docker-compose.yml` — Docker Compose configuration
- `.dockerignore` — Docker ignore file
- `build.sh` — Build script for Docker image

---

## Prerequisites

- Python 3.6 or higher installed
- `pip` installed for Python 3

If `pip` is not installed, on Ubuntu/Debian run:

```bash
sudo apt update
sudo apt install python3-pip
```

---

## Setup and Run

### Option 1: Docker Compose (Recommended)

```bash
# Build and run the embedding server
docker-compose up --build -d

# Check if it's running (may take 1-2 minutes for model to load)
curl http://localhost:5001/health
```

This will build and start the embedding server on localhost:5001. The first startup takes 1-2 minutes to download and load the model.

### Option 2: Manual Docker Commands

```bash
# Build the image
./build.sh

# Run the container
docker run -p 5001:5001 embedding-server:latest
```

### Option 3: Direct Python (Legacy)

1. Clone or copy the repository folder to your system.

2. Open terminal and navigate to the folder containing these files.

3. Run the server with:

```bash
python3 run_server.py
```

This will:

- Install all necessary dependencies (`flask`, `sentence-transformers`, `torch`)
- Start the Flask embedding server on `http://0.0.0.0:5001`

---

## Usage

### API Endpoints

**Health Check:**
```bash
curl http://localhost:5001/health
```

**Response:**
```json
{
  "status": "healthy",
  "model_loaded": true,
  "model_name": "all-mpnet-base-v2"
}
```

**Get Embedding:**
```bash
curl -X POST http://localhost:5001/embed \
  -H "Content-Type: application/json" \
  -d '{"text": "Your text here"}'
```

**Response:**
```json
{
  "embedding": [ /* 768-dimensional embedding vector */ ]
}
```

### Integration with Your App

**Environment Variables:**
```bash
# For your main app
EMBEDDING_SERVICE_URL=http://localhost:5001
# Or for Docker networks:
EMBEDDING_SERVICE_URL=http://embedding-server:5001
```

**Example Integration (Python):**
```python
import requests

def get_embedding(text):
    response = requests.post(
        'http://localhost:5001/embed',
        json={'text': text}
    )
    return response.json()['embedding']

# Usage
embedding = get_embedding("Hello world")
print(f"Embedding dimensions: {len(embedding)}")  # 768
```

---

## Features

This Docker setup includes several optimizations and features:

- **High-Quality Model**: Uses `all-mpnet-base-v2` (~420MB) for 768-dimensional embeddings
- **CPU-Only PyTorch**: Uses CPU-optimized PyTorch to prevent CUDA bloat (keeps image ~2.2GB vs 11GB)
- **Multi-stage Build**: Separates build and runtime dependencies for smaller final image
- **Eager Loading**: Model loads at startup for maximum response speed
- **Memory Optimized**: 3GB memory limit with garbage collection after model loading
- **Non-root User**: Runs as non-privileged user for security
- **Health Checks**: Built-in health monitoring with model status
- **Error Handling**: Graceful error handling for model loading and embedding generation

## Model Information

| Model | Size | Dimensions | Quality | Docker Image Size |
|-------|------|------------|---------|-------------------|
| all-mpnet-base-v2 | ~420MB | 768 | Excellent | ~2.2GB |

## Performance

- **First startup**: 1-2 minutes (model download and loading)
- **Subsequent startups**: ~30 seconds (model cached)
- **Embedding generation**: ~100-500ms per request
- **Memory usage**: ~1.5-2GB RAM during operation

## Troubleshooting

### Common Issues

**Container keeps restarting:**
- Check if you have enough memory (need at least 2GB available)
- Wait 1-2 minutes for model to load on first startup

**"Model not loaded" error:**
- Check container logs: `docker-compose logs`
- Ensure sufficient memory and wait for model loading to complete

**Slow first startup:**
- Normal behavior - model needs to download (~420MB) and load
- Subsequent startups are much faster

**Check container status:**
```bash
# View logs
docker-compose logs -f

# Check health
curl http://localhost:5001/health

# Test embedding
curl -X POST http://localhost:5001/embed \
  -H "Content-Type: application/json" \
  -d '{"text": "test"}'
```

## Notes

- Docker container uses ~1.5-2GB RAM (3GB limit for safety)
- Model loads at startup - first request may be slower
- For better isolation, Docker is recommended over direct Python installation
- Health check endpoint available at `/health` with model status
- Uses Flask directly for better memory control during model loading



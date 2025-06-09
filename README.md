# Embedding Server

This is an optimized Flask server that provides text embeddings using the `sentence-transformers` library with the `all-MiniLM-L6-v2` model (optimized for memory efficiency and speed).

---

## Files

- `app.py` — Optimized Flask server code for embedding endpoint
- `requirements.txt` — Python dependencies (CPU-only PyTorch for smaller size)
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

### Option 1: Quick Start for Local Development

```bash
# One-command setup - builds, starts, and tests the service
./start-embedding-service.sh
```

This will:
- Build the Docker image
- Start the service on localhost:5001
- Test the connection
- Show integration info

### Option 2: Integration with Existing Project

If you have an app running on localhost:3000, add the embedding service:

```bash
# Start embedding service alongside your app
docker-compose -f docker-compose.integration.yml up -d
```

### Option 3: Manual Docker Commands

```bash
# Build the image
./build.sh

# Run the container
docker run -p 5001:5001 embedding-server:latest
```

Or use Docker Compose:

```bash
docker-compose up
```

### Option 2: Direct Python (Legacy)

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

**Get Embedding:**
```bash
curl -X POST http://localhost:5001/embed \
  -H "Content-Type: application/json" \
  -d '{"text": "Your text here"}'
```

**Response:**
```json
{
  "embedding": [ /* 384-dimensional embedding vector */ ],
  "dimensions": 384,
  "model": "all-MiniLM-L6-v2"
}
```

### Integration with Your App

**JavaScript/Node.js:**
```javascript
const EmbeddingClient = require('./client/embedding-client');
const client = new EmbeddingClient();

// Get embedding
const result = await client.getEmbedding("Hello world");
console.log(result.embedding);

// Find similar texts
const similar = await client.findMostSimilar("cat", ["dog", "kitten", "car"]);
console.log(similar.bestMatch); // "kitten"
```

**Environment Variables:**
```bash
# For your main app
EMBEDDING_SERVICE_URL=http://localhost:5001
# Or for Docker networks:
EMBEDDING_SERVICE_URL=http://embedding-server:5001
```

See `examples/integration-examples.md` for detailed code examples in multiple languages.

---

## Optimizations

This Docker setup includes several optimizations for minimal memory usage:

- **Smaller Model**: Uses `all-MiniLM-L6-v2` (~90MB) instead of `all-mpnet-base-v2` (~420MB)
- **CPU-only PyTorch**: Reduces image size significantly
- **Multi-stage Build**: Separates build and runtime dependencies
- **Lazy Loading**: Model loads only when first needed
- **Memory Limits**: Docker Compose includes memory constraints
- **Non-root User**: Runs as non-privileged user for security

## Performance Comparison

| Model | Size | Dimensions | Speed | Quality |
|-------|------|------------|-------|---------|
| all-mpnet-base-v2 | ~420MB | 768 | 1x | Excellent |
| all-MiniLM-L6-v2 | ~90MB | 384 | ~2x | Very Good |

## Notes

- Docker container uses ~512MB-1GB RAM (vs ~300MB+ for the larger model)
- For better isolation, Docker is recommended over direct Python installation
- Health check endpoint available at `/health`
- Uses Gunicorn for production-ready serving



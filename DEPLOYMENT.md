# Embedding Server - Production Deployment Guide

This guide covers deploying the Embedding Server Flask application to production using the `all-mpnet-base-v2` model.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Deployment Options](#deployment-options)
- [Option 1: Docker Compose Deployment](#option-1-docker-compose-deployment)
- [Option 2: Docker Standalone](#option-2-docker-standalone)
- [Environment Variables](#environment-variables)
- [Post-Deployment Steps](#post-deployment-steps)
- [Troubleshooting](#troubleshooting)

## Prerequisites

- Docker and Docker Compose installed (for Docker deployment)
- Server with at least 2GB RAM (3GB+ recommended)
- Python 3.11+ (for direct Python deployment)
- Basic knowledge of Docker and server administration

## Deployment Options

### Option 1: Docker Compose (Recommended)

Best for:
- Consistent deployments
- Easy management
- Production environments
- Model cache persistence

### Option 2: Docker Standalone

Best for:
- Quick deployments
- Single container setup
- CI/CD pipelines

## Option 1: Docker Compose Deployment

### Step 1: Prepare Environment Variables

1. Copy the example environment file:
```bash
cp .env.production.example .env.production
```

2. Edit `.env.production` if needed (most settings have defaults):
```bash
nano .env.production
```

**Required variables:**
- `PORT` - Server port (default: 5001)

### Step 2: Build and Start Service

```bash
# Build the service
docker-compose -f docker-compose.production.yml build

# Start the service
docker-compose -f docker-compose.production.yml up -d

# View logs (first startup takes 1-2 minutes for model download)
docker-compose -f docker-compose.production.yml logs -f
```

### Step 3: Verify Service

```bash
# Check service is running
docker-compose -f docker-compose.production.yml ps

# Wait for model to load (check logs for "Model loaded successfully!")
# Then test health endpoint
curl http://localhost:5001/health

# Expected response:
# {
#   "status": "healthy",
#   "model_loaded": true,
#   "model_name": "all-mpnet-base-v2"
# }

# Test embedding endpoint
curl -X POST http://localhost:5001/embed \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello world"}'
```

### Step 4: Set Up Reverse Proxy (Optional)

If you want to expose the service via a domain:

```nginx
server {
    listen 80;
    server_name embedding.your-domain.com;

    location / {
        proxy_pass http://localhost:5001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Health check endpoint
    location /health {
        proxy_pass http://localhost:5001/health;
        access_log off;
    }
}
```

## Option 2: Docker Standalone

### Step 1: Build Image

```bash
# Build production image
docker build -f Dockerfile.production -t embedding-server:production .
```

### Step 2: Run Container

```bash
# Run container with volume for model cache persistence
docker run -d \
  --name embedding-server-prod \
  --restart unless-stopped \
  -p 5001:5001 \
  -e PORT=5001 \
  -e PYTHONUNBUFFERED=1 \
  --memory="3g" \
  --memory-reservation="1.5g" \
  -v embedding_model_cache:/home/appuser/.cache \
  embedding-server:production
```

### Step 3: Verify

```bash
# Check container status
docker ps | grep embedding-server-prod

# Wait for model to load, then test health endpoint
curl http://localhost:5001/health
```

### Step 4: View Logs

```bash
# View logs
docker logs -f embedding-server-prod
```

## Environment Variables

See [.env.production.example](./.env.production.example) for all environment variables.

### Required Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Server port | `5001` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PYTHONUNBUFFERED` | Python unbuffered output | `1` |
| `TRANSFORMERS_CACHE` | Model cache directory | `/home/appuser/.cache/torch/sentence_transformers` |
| `HF_HOME` | HuggingFace cache | `/home/appuser/.cache/huggingface` |
| `TORCH_HOME` | PyTorch cache | `/home/appuser/.cache/torch` |

## Post-Deployment Steps

### 1. Verify Service

```bash
# Health check
curl http://localhost:5001/health

# Expected response:
# {
#   "status": "healthy",
#   "model_loaded": true,
#   "model_name": "all-mpnet-base-v2"
# }
```

### 2. Test Embedding Endpoint

```bash
curl -X POST http://localhost:5001/embed \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello world"}'

# Expected response:
# {
#   "embedding": [ /* 768-dimensional embedding vector */ ]
# }
```

### 3. Monitor Performance

```bash
# Check container resource usage
docker stats embedding-server-prod

# View logs
docker logs -f embedding-server-prod
```

### 4. Set Up Monitoring

Consider setting up:
- **Health check monitoring**: Monitor `/health` endpoint
- **Resource monitoring**: CPU, memory usage (expect ~1.5-2GB RAM)
- **Response time monitoring**: Track embedding generation time
- **Error tracking**: Monitor error rates

## Troubleshooting

### Service Won't Start

1. Check logs: `docker logs embedding-server-prod`
2. Verify port is not in use: `netstat -tuln | grep 5001`
3. Check disk space: `df -h` (need ~500MB for model)
4. Check memory: `free -h` (need at least 2GB available)

### Model Loading Issues

**First startup takes 1-2 minutes** - this is normal! The model needs to:
1. Download (~420MB) - takes 1-2 minutes depending on internet speed
2. Load into memory - takes 10-30 seconds

**If model loading fails:**

1. Check logs: `docker logs embedding-server-prod`
2. Verify internet connection (for first-time model download)
3. Check disk space (models are ~420MB)
4. Check memory (need at least 2GB available)
5. Verify model cache volume is mounted correctly

**Subsequent startups are faster** (~30 seconds) if model cache is persisted via volume.

### Performance Issues

1. **Slow embeddings**: 
   - Normal: ~100-500ms per request on CPU
   - Check system resources
   - Consider GPU if available

2. **High memory usage**:
   - Normal: ~1.5-2GB RAM for all-mpnet-base-v2
   - Model is loaded in memory for fast responses
   - Memory limit is set to 3GB for safety

3. **Timeout errors**:
   - Increase Gunicorn timeout (default: 300s)
   - Check system load
   - Verify network connectivity

### Health Check Fails

1. Verify service is running: `docker ps | grep embedding-server-prod`
2. Check port binding: `docker port embedding-server-prod`
3. Test locally: `curl http://localhost:5001/health`
4. Check firewall rules
5. Wait for model to finish loading (check logs)

### Container Keeps Restarting

1. Check logs: `docker logs embedding-server-prod`
2. Verify memory limit (need at least 2GB)
3. Check if model download is failing
4. Verify disk space

## Updating the Service

### Docker Compose

```bash
# Pull latest code
git pull

# Rebuild and restart
docker-compose -f docker-compose.production.yml build
docker-compose -f docker-compose.production.yml up -d
```

### Docker Standalone

```bash
# Stop container
docker stop embedding-server-prod
docker rm embedding-server-prod

# Rebuild image
docker build -f Dockerfile.production -t embedding-server:production .

# Start new container
docker run -d \
  --name embedding-server-prod \
  --restart unless-stopped \
  -p 5001:5001 \
  -v embedding_model_cache:/home/appuser/.cache \
  embedding-server:production
```

## Model Information

### all-mpnet-base-v2

- **Dimensions**: 768
- **Size**: ~420MB
- **Quality**: Excellent
- **Speed**: ~100-500ms per embedding on CPU
- **Memory**: ~1.5-2GB RAM when loaded

### First Startup

- **Model download**: 1-2 minutes (depends on internet speed)
- **Model loading**: 10-30 seconds
- **Total**: ~2-3 minutes

### Subsequent Startups

- **Model loading**: ~30 seconds (if cache persisted)
- Much faster if model cache volume is used

## Security Considerations

1. **Firewall**: Only expose port 5001 to necessary services
2. **Authentication**: Consider adding API key authentication for production
3. **Rate limiting**: Implement rate limiting to prevent abuse
4. **HTTPS**: Use reverse proxy with SSL for external access
5. **Resource limits**: Set Docker memory/CPU limits (already configured)
6. **Non-root user**: Service runs as non-root user in Docker

## Integration with Best Chat

To use this service with Best Chat:

1. Set `EXTERNAL_EMBEDDING_URL` in Best Chat's environment:
   ```bash
   EXTERNAL_EMBEDDING_URL=http://embedding-server:5001
   ```

2. For Docker networks, use service name:
   ```bash
   EXTERNAL_EMBEDDING_URL=http://embedding-server:5001
   ```

3. For external services, use full URL:
   ```bash
   EXTERNAL_EMBEDDING_URL=http://embedding.your-domain.com:5001
   ```

## Support

For issues or questions:
1. Check logs first: `docker logs embedding-server-prod`
2. Review this deployment guide
3. Check health endpoint: `curl http://localhost:5001/health`
4. Verify environment variables are set correctly

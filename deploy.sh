#!/bin/bash

# Production Deployment Script for Embedding Server
# This script helps deploy the embedding server to production

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info "Starting Embedding Server production deployment..."

# Check if .env.production exists (optional)
if [ -f ".env.production" ]; then
    print_info "Found .env.production, using it for configuration"
    export $(cat .env.production | grep -v '^#' | xargs)
else
    print_warn ".env.production not found, using defaults"
fi

# Build service
print_info "Building Docker image..."
docker-compose -f docker-compose.production.yml build

# Start service
print_info "Starting service..."
docker-compose -f docker-compose.production.yml up -d

# Wait for service to start
print_info "Waiting for service to start (model download may take 1-2 minutes)..."
sleep 10

# Check service health
print_info "Checking service health..."

# Wait for model to load (can take 1-2 minutes on first startup)
MAX_WAIT=180  # 3 minutes
WAIT_COUNT=0
HEALTHY=false

while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
    if curl -f http://localhost:5001/health > /dev/null 2>&1; then
        HEALTHY=true
        break
    fi
    print_info "Waiting for model to load... ($WAIT_COUNT/$MAX_WAIT seconds)"
    sleep 10
    WAIT_COUNT=$((WAIT_COUNT + 10))
done

if [ "$HEALTHY" = true ]; then
    print_info "✓ Embedding server is healthy"
    
    # Show model status
    MODEL_STATUS=$(curl -s http://localhost:5001/health | python3 -c "import sys, json; data=json.load(sys.stdin); print(f\"Model: {data.get('model_name', 'unknown')}, Loaded: {data.get('model_loaded', False)}\")" 2>/dev/null || echo "Model status unknown")
    print_info "  $MODEL_STATUS"
else
    print_warn "⚠ Health check failed after $MAX_WAIT seconds"
    print_warn "This may be normal on first startup (model download takes 1-2 minutes)"
    print_warn "Check logs with: docker-compose -f docker-compose.production.yml logs -f"
fi

# Show service status
print_info "Service status:"
docker-compose -f docker-compose.production.yml ps

print_info ""
print_info "Deployment complete!"
print_info ""
print_info "Service is running:"
print_info "  - Embedding Server: http://localhost:5001"
print_info ""
print_info "Useful commands:"
print_info "  View logs: docker-compose -f docker-compose.production.yml logs -f"
print_info "  Stop service: docker-compose -f docker-compose.production.yml down"
print_info "  Restart service: docker-compose -f docker-compose.production.yml restart"
print_info "  Test health: curl http://localhost:5001/health"
print_info ""
print_warn "Note: First startup takes 1-2 minutes for model download"
print_warn "Subsequent startups are faster if model cache is persisted"

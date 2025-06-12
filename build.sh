#!/bin/bash

# Build script for the embedding server Docker image

set -e

echo "Building optimized embedding server Docker image..."
echo "Using CPU-only PyTorch for minimal size..."

# Build the image
docker build -t embedding-server:latest .

echo ""
echo "✅ Build completed successfully!"
echo ""
echo "Image size:"
docker images embedding-server:latest --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
echo ""
echo "To run the container:"
echo "  docker run -p 5001:5001 embedding-server:latest"
echo ""
echo "Or use docker-compose:"
echo "  docker-compose up"
echo ""
echo "Test the server:"
echo "  curl -X POST http://localhost:5001/embed -H 'Content-Type: application/json' -d '{\"text\": \"Hello world\"}'"

#!/bin/bash

# Build script for the embedding server Docker image

set -e

echo "Building embedding server Docker image..."

# Build the image
docker build -t embedding-server:latest .

echo "Build completed successfully!"
echo ""
echo "To run the container:"
echo "  docker run -p 5001:5001 embedding-server:latest"
echo ""
echo "Or use docker-compose:"
echo "  docker-compose up"
echo ""
echo "Test the server:"
echo "  curl -X POST http://localhost:5001/embed -H 'Content-Type: application/json' -d '{\"text\": \"Hello world\"}'"

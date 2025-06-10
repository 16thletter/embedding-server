# Multi-stage build for minimal image size
FROM python:3.11-slim AS builder

# Set working directory
WORKDIR /app

# Install system dependencies needed for building
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir --user -r requirements.txt

# Production stage
FROM python:3.11-slim

# Create non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Set working directory
WORKDIR /app

# Install only runtime dependencies
RUN apt-get update && apt-get install -y \
    && rm -rf /var/lib/apt/lists/*

# Copy Python packages from builder stage
COPY --from=builder /root/.local /home/appuser/.local

# Copy application code
COPY app.py .

# Create cache directory for models and set permissions
RUN mkdir -p /home/appuser/.cache/torch/sentence_transformers && \
    chown -R appuser:appuser /home/appuser && \
    chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Set environment variables
ENV PATH=/home/appuser/.local/bin:$PATH
ENV PYTHONPATH=/home/appuser/.local/lib/python3.11/site-packages
ENV TRANSFORMERS_CACHE=/home/appuser/.cache/torch/sentence_transformers
ENV TORCH_HOME=/home/appuser/.cache/torch

# Expose port
EXPOSE 5001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:5001/health')" || exit 1

# Use Gunicorn for production with optimized settings for speed
CMD ["gunicorn", "--bind", "0.0.0.0:5001", "--workers", "1", "--threads", "1", "--timeout", "60", "--preload", "app:app"]

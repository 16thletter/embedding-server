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

# Install CPU-only PyTorch and dependencies in one step for better optimization
RUN pip install --no-cache-dir --user \
    torch==2.7.1+cpu \
    --index-url https://download.pytorch.org/whl/cpu && \
    pip install --no-cache-dir --user -r requirements.txt && \
    # Clean up pip cache and temporary files
    rm -rf /root/.cache/pip && \
    find /root/.local -name "*.pyc" -delete && \
    find /root/.local -name "__pycache__" -type d -exec rm -rf {} + || true

# Production stage
FROM python:3.11-slim

# Create non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Set working directory
WORKDIR /app

# No additional runtime dependencies needed - keep image minimal

# Copy Python packages from builder stage
COPY --from=builder /root/.local /home/appuser/.local

# Copy application code
COPY app.py .

# Create cache directory for models and set permissions
RUN mkdir -p /home/appuser/.cache/torch/sentence_transformers && \
    chown -R appuser:appuser /home/appuser && \
    chown -R appuser:appuser /app && \
    # Clean up any remaining cache files
    find /home/appuser/.local -name "*.pyc" -delete && \
    find /home/appuser/.local -name "__pycache__" -type d -exec rm -rf {} + || true

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
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5001/health')" || exit 1

# Use Flask directly for better memory control during model loading
CMD ["python", "app.py"]
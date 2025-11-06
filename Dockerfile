# CPU-optimized Dockerfile for BGE Reranker v2-m3
# Designed for Google Cloud Run deployment

FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
# Use --no-cache-dir to reduce image size
RUN pip install --no-cache-dir -r requirements.txt

# Download model during build time to reduce cold start
# This increases image size but makes startup much faster
RUN python -c "from transformers import AutoModelForSequenceClassification, AutoTokenizer; \
    model_name='BAAI/bge-reranker-v2-m3'; \
    print('Downloading model...'); \
    AutoTokenizer.from_pretrained(model_name); \
    AutoModelForSequenceClassification.from_pretrained(model_name); \
    print('Model downloaded successfully')"

# Copy application code
COPY app.py .

# Expose port (Cloud Run uses PORT env variable, defaults to 8080)
EXPOSE 8080

# Set environment variables for optimization
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV TRANSFORMERS_OFFLINE=1
ENV HF_HUB_OFFLINE=1

# Health check (optional, but useful for local testing)
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Run the application
# For Cloud Run, use PORT environment variable
CMD uvicorn app:app --host 0.0.0.0 --port ${PORT:-8080} --workers 1

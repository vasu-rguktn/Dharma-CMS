# Use Python 3.11 slim image as base
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies (minimal set for OpenCV headless)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    curl \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    ffmpeg \
    ffmpeg \
    libgthread-2.0-0 \
    fonts-noto \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy requirements file
COPY requirements.txt .

# Install Python dependencies (with optimizations for memory)
# Using --no-cache-dir prevents caching, so no need to purge cache
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create directories for generated reports, temporary videos, and legal RAG
RUN mkdir -p generated_reports/investigation_reports && \
    mkdir -p temp_videos && \
    mkdir -p legal_rag/chroma_db && \
    mkdir -p legal_rag/data && \
    mkdir -p storage/persons

# (Optional) Expose Cloud Run port (informational only)
EXPOSE 8080

# Set default PORT for Cloud Run (Cloud Run will override this)
ENV PORT=8080

# Health check (Cloud Run compatible)
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:${PORT:-8080}/api/health || exit 1

# Run the application (Cloud Run REQUIRED pattern)
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]

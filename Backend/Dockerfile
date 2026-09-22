# ==============================================================================
# Attendance System Backend - Production-Ready Dockerfile
# Python 3.12 + Django REST Framework + DeepFace / SQLite
# ==============================================================================

FROM python:3.12-slim-bookworm

# Set environment variables for Python runtime & framework
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    DEBIAN_FRONTEND=noninteractive \
    DEEPFACE_HOME=/app/.deepface \
    SQLITE_DB_PATH=/app/data/db.sqlite3 \
    PORT=8000

# Install system dependencies required for OpenCV, Pillow, SQLite, and network healthcheck
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    libgl1 \
    libglib2.0-0 \
    libgomp1 \
    sqlite3 \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Create unprivileged user and directories for data, media, static files, and DeepFace cache
RUN groupadd -g 1000 appuser && \
    useradd -u 1000 -g appuser -m appuser && \
    mkdir -p /app/data /app/media /app/staticfiles /app/.deepface && \
    chown -R appuser:appuser /app

# Copy dependency definition first for optimal Docker layer caching
COPY --chown=appuser:appuser requirements.txt /app/

# Install Python packages
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy backend application source code
COPY --chown=appuser:appuser . /app/

# Ensure entrypoint script is executable
RUN chmod +x /app/entrypoint.sh

# Switch to non-root user for security
USER appuser

# Expose HTTP port
EXPOSE 8000

# Define container health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
    CMD curl -f http://localhost:8000/api/v1/health/ || exit 1

# Container entrypoint and startup command
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["gunicorn", "config.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "3", "--timeout", "120"]

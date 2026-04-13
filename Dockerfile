# syntax=docker/dockerfile:1
# Production image for the FastAPI app (challenge.api:app).
# Cloud Run injects PORT; defaults to 8080.

FROM python:3.10-slim-bookworm

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PORT=8080

WORKDIR /app

# Optional build-essential block: enable only if a wheel fails to build on slim.
# RUN apt-get update && apt-get install -y --no-install-recommends \
#     build-essential \
#     && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN pip install --upgrade pip && \
    pip install -r requirements.txt

COPY challenge/ ./challenge/
COPY data/ ./data/

RUN groupadd --gid 1000 app && \
    useradd --uid 1000 --gid app --home /app --shell /usr/sbin/nologin app && \
    chown -R app:app /app

USER app

EXPOSE 8080

# Import loads the CSV and fits the model; the first /health check may be slow.
HEALTHCHECK --interval=30s --timeout=10s --start-period=180s --retries=3 \
    CMD python -c "import os, urllib.request; p=os.environ.get('PORT', '8080'); urllib.request.urlopen('http://127.0.0.1:%s/health' % p)"

CMD ["sh", "-c", "exec uvicorn challenge.api:app --host 0.0.0.0 --port ${PORT:-8080}"]

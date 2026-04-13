# syntax=docker/dockerfile:1
# Imagen de producción para la API FastAPI (challenge.api:app).
# Cloud Run inyecta la variable de entorno PORT; por defecto 8080.

FROM python:3.10-slim-bookworm

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PORT=8080

WORKDIR /app

# Dependencias solo si alguna wheel falla en slim (descomenta si `pip install` falla al compilar):
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

# El arranque carga el CSV y entrena el modelo al importar el módulo: el primer /health puede tardar.
HEALTHCHECK --interval=30s --timeout=10s --start-period=180s --retries=3 \
    CMD python -c "import os, urllib.request; p=os.environ.get('PORT', '8080'); urllib.request.urlopen('http://127.0.0.1:%s/health' % p)"

CMD ["sh", "-c", "exec uvicorn challenge.api:app --host 0.0.0.0 --port ${PORT:-8080}"]

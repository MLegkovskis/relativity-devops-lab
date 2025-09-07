# syntax=docker/dockerfile:1.7
FROM python:3.11-slim AS base
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PIP_NO_CACHE_DIR=1

WORKDIR /app
# copy core library first to leverage layer caching
COPY packages/core_physics /pkg/core_physics
RUN python -m pip install --upgrade pip && \
    python -m pip install /pkg/core_physics

# now the service
COPY services/ray-api/requirements.txt .
RUN pip install -r requirements.txt
COPY services/ray-api/app ./app

EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s --retries=3 CMD curl -f http://localhost:8000/docs || exit 1
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

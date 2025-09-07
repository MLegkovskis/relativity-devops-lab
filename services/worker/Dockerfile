FROM python:3.11-slim
WORKDIR /app
COPY packages/core_physics /pkg/core_physics
RUN python -m pip install --upgrade pip && \
	pip install /pkg/core_physics
COPY services/worker/requirements.txt .
RUN pip install -r requirements.txt
COPY services/worker/worker ./worker
CMD ["celery", "-A", "worker.tasks:celery", "worker", "--loglevel=INFO", "--concurrency=1"]

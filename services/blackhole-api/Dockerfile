FROM python:3.11-slim
WORKDIR /app
COPY packages/core_physics /pkg/core_physics
RUN python -m pip install --upgrade pip && \
	pip install /pkg/core_physics

COPY services/blackhole-api/requirements.txt .
RUN pip install -r requirements.txt
COPY services/blackhole-api/app ./app

EXPOSE 8001
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8001"]

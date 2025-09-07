# Optional: OpenGL renderer Dockerfile (to be implemented later)
FROM python:3.11-slim
WORKDIR /app
COPY services/renderer-gl/requirements.txt .
RUN pip install -r requirements.txt
COPY services/renderer-gl/app ./app
CMD ["python", "app/main.py"]

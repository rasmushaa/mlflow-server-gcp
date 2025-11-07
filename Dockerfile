FROM python:3.13-slim

# Install system dependencies for mysqlclient and MLflow
RUN apt-get update && apt-get install -y \
    default-libmysqlclient-dev \
    build-essential \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*
    
# mysqlclient is the most reliable MySQL driver for MLflow (via SQLAlchemy).
RUN pip install mlflow mysqlclient google-cloud-storage 

ENV PORT=8080
EXPOSE 8080

CMD mlflow server \
  --backend-store-uri=${BACKEND_STORE_URI} \
  --default-artifact-root=${ARTIFACT_ROOT} \
  --host=0.0.0.0 --port=${PORT}
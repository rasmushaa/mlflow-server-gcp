#!/bin/bash
set -euo pipefail


# Use PORT provided by Cloud Run (default 8080)
PORT=${PORT:-8080}

# Limit DB connections (Mlflow + Alchemy wants to create multiple connections by default, and only 25 are supported on potate cloud sql)
export MLFLOW_SQLALCHEMYSTORE_POOL_SIZE=15
export MLFLOW_SQLALCHEMYSTORE_MAX_OVERFLOW=20
export MLFLOW_SQLALCHEMYSTORE_POOL_RECYCLE=180


# Mlflow server
echo "Starting MLflow server (host=0.0.0.0 port=$PORT)"
mlflow server \
    --host 0.0.0.0 \
    --port $PORT \
    --backend-store-uri "$BACKEND_STORE_URI" \
    --default-artifact-root "$ARTIFACT_ROOT" \
    --serve-artifacts
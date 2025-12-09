#!/bin/bash
set -euo pipefail

PORT="${PORT:-8080}"

# MLflow backend settings (must be env vars, not CLI flags)
export MLFLOW_BACKEND_STORE_URI="$BACKEND_STORE_URI"
export MLFLOW_DEFAULT_ARTIFACT_ROOT="$ARTIFACT_ROOT"
export MLFLOW_ENABLE_ARTIFACT_SERVER="true"

# SQLAlchemy pool settings
export MLFLOW_SQLALCHEMYSTORE_POOL_SIZE=15
export MLFLOW_SQLALCHEMYSTORE_MAX_OVERFLOW=20
export MLFOW_SQLALCHEMYSTORE_POOL_RECYCLE=180


echo "Starting MLflow with Gunicorn on port $PORT"

exec gunicorn mlflow.server:app \
    --bind "0.0.0.0:${PORT}" \
    --workers 1 \
    --threads 8 \
    --timeout 300

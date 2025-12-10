#!/bin/bash
set -euo pipefail

PORT="${PORT:-8080}"

# MLflow backend settings (must be env vars, not CLI flags)
export MLFLOW_BACKEND_STORE_URI="$BACKEND_STORE_URI"
export MLFLOW_DEFAULT_ARTIFACT_ROOT="$ARTIFACT_ROOT"

# MLflow tracking auth settings
export WSGI_AUTH_CREDENTIALS="$MLFLOW_TRACKING_USERNAME:$MLFLOW_TRACKING_PASSWORD"

# SQLAlchemy pool settings
export MLFLOW_SQLALCHEMYSTORE_POOL_SIZE=15
export MLFLOW_SQLALCHEMYSTORE_MAX_OVERFLOW=20
export MLFOW_SQLALCHEMYSTORE_POOL_RECYCLE=180

echo "Starting MLflow with Gunicorn on port $PORT"
exec gunicorn -b "${HOST}:${PORT}" -w 4 --log-level debug --access-logfile=- --error-logfile=- --log-level=debug mlflow:app
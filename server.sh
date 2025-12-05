#!/bin/bash
set -euo pipefail


# Use PORT provided by Cloud Run (default 8080)
PORT=${PORT:-8080}


# Ensure Auth Credentials are always provided
if [ -z "${MLFLOW_TRACKING_USERNAME-}" ] || [ -z "${MLFLOW_TRACKING_PASSWORD-}" ]; then
    echo "MLFLOW_TRACKING_USERNAME and MLFLOW_TRACKING_PASSWORD must be set"
    exit 1
fi


# Create the creds-file for nginx
printf "%s:%s\n" "$MLFLOW_TRACKING_USERNAME" "$(openssl passwd -apr1 "$MLFLOW_TRACKING_PASSWORD")" > /etc/nginx/.htpasswd


# Limit DB connections (Mlflow + Alchemy wants to create multiple connections by default, and only 25 are supported on potate cloud sql)
export MLFLOW_SQLALCHEMYSTORE_POOL_SIZE=3
export MLFLOW_SQLALCHEMYSTORE_MAX_OVERFLOW=5
export MLFLOW_SQLALCHEMYSTORE_POOL_RECYCLE=180


# Mlflow server
echo "Starting MLflow server (host=127.0.0.1 port=5000)"
mlflow server \
    --host 127.0.0.1 \
    --port 5000 \
    --backend-store-uri "$BACKEND_STORE_URI" \
    --default-artifact-root "$ARTIFACT_ROOT" \
    --serve-artifacts &


# Wait for MLflow to become available before starting nginx
echo "Waiting for MLflow to become available on http://127.0.0.1:5000"
for i in {1..30}; do
    if curl --fail --silent http://127.0.0.1:5000 >/dev/null 2>&1; then
        echo "MLflow is up"
        break
    fi
    sleep 1
done


# Start Reverse Proxy
echo "Starting nginx in foreground"
nginx -g "daemon off;"
#!/bin/bash
set -e

# Use PORT provided by Cloud Run (default 8080)
PORT=${PORT:-8080}

# Require basic auth credentials
if [ -z "$MLFLOW_TRACKING_USERNAME" ] || [ -z "$MLFLOW_TRACKING_PASSWORD" ]; then
    echo "MLFLOW_TRACKING_USERNAME and MLFLOW_TRACKING_PASSWORD must be set"
    exit 1
fi

# create .htpasswd dynamically
printf "%s:$(openssl passwd -apr1 %s)\n" "$MLFLOW_USER" "$MLFLOW_PASSWORD" > /etc/nginx/.htpasswd

# start MLflow server in background
mlflow server \
    --host 127.0.0.1 \
    --port 5000 \
    --backend-store-uri $MLFLOW_BACKEND_STORE_URI \
    --default-artifact-root $MLFLOW_ARTIFACT_URI &

# start Nginx in foreground (Cloud Run expects PID 1 to keep running)
nginx -g "daemon off;"
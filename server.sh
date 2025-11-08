#!/bin/bash 
set -e

# Create Basic Auth file
if [ -z "$MLFLOW_TRACKING_USERNAME" ] || [ -z "$MLFLOW_TRACKING_PASSWORD" ]; then
    echo "MLFLOW_TRACKING_USERNAME and MLFLOW_TRACKING_PASSWORD must be set"
    exit 1
fi

printf "%s:$(openssl passwd -apr1 %s)\n" "$MLFLOW_TRACKING_USERNAME" "$MLFLOW_TRACKING_PASSWORD" > /etc/nginx/.htpasswd

# Start MLflow server in background
mlflow db upgrade $BACKEND_STORE_URI
mlflow server \
  --host 0.0.0.0 \
  --port 8080 \
  --backend-store-uri $BACKEND_STORE_URI \
  --artifacts-destination $ARTIFACT_ROOT

# Start Nginx in foreground
nginx -g "daemon off;"
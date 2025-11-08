#!/bin/bash
set -e

# Use PORT provided by Cloud Run (default 8080)
PORT=${PORT:-8080}

# Require basic auth credentials
if [ -z "$MLFLOW_TRACKING_USERNAME" ] || [ -z "$MLFLOW_TRACKING_PASSWORD" ]; then
    echo "MLFLOW_TRACKING_USERNAME and MLFLOW_TRACKING_PASSWORD must be set"
    exit 1
fi

printf "%s:$(openssl passwd -apr1 %s)\n" "$MLFLOW_TRACKING_USERNAME" "$MLFLOW_TRACKING_PASSWORD" > /etc/nginx/.htpasswd

# Ensure nginx listens on the configured PORT (replace default 8080 entry)
if grep -q "listen 8080;" /etc/nginx/nginx.conf; then
    sed -i "s/listen 8080;/listen ${PORT};/" /etc/nginx/nginx.conf
fi

# Run DB upgrade if BACKEND_STORE_URI is provided
if [ -n "$BACKEND_STORE_URI" ]; then
    mlflow db upgrade "$BACKEND_STORE_URI"
fi

# Start MLflow server in background so we can run nginx in foreground (Cloud Run PID 1)
mlflow server \
  --host 127.0.0.1 \
  --port 5000 \
  --backend-store-uri "$BACKEND_STORE_URI" \
  --artifacts-destination "$ARTIFACT_ROOT" &

# Replace shell with nginx in foreground so container stays alive and receives signals
exec nginx -g "daemon off;"

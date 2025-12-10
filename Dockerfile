FROM ghcr.io/mlflow/mlflow:v3.7.0

EXPOSE 8080

CMD mlflow server \
    --host 0.0.0.0 \
    --port 8080 \
    --backend-store-uri $BACKEND_STORE_URI \
    --default-artifact-root $ARTIFACT_ROOT
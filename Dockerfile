FROM python:3.13-slim

WORKDIR /

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY requirements.txt requirements.txt

# Install MLflow and Nginx
RUN pip install --upgrade pip && pip install -r requirements.txt
RUN apt-get update && apt-get install -y nginx apache2-utils && rm -rf /var/lib/apt/lists/*

# Create htpasswd file
RUN htpasswd -bc /etc/nginx/.htpasswd mlflowuser mypassword

# Expose port
EXPOSE 8080

# Start both Nginx and MLflow
## Start MLflow and Nginx. Run MLflow bound to 0.0.0.0 so nginx (and other processes)
## in the container can reliably reach it. Start nginx in the foreground so it
## becomes PID 1 and keeps the container alive.
CMD mlflow server --host 0.0.0.0 --port 5000 \
    --backend-store-uri sqlite:///mlflow.db \
    --default-artifact-root ./artifacts & \
    nginx -g "daemon off;"
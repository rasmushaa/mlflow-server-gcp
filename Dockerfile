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
CMD service nginx start && mlflow server --host 127.0.0.1 --port 5000 \
    --backend-store-uri sqlite:///mlflow.db \
    --default-artifact-root ./artifacts
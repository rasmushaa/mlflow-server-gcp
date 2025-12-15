# Use the official MLflow image as base
FROM ghcr.io/mlflow/mlflow:v3.7.0

# Copy the repo
WORKDIR /
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY requirements.txt requirements.txt
COPY server.sh /server.sh

# Fix for SQLAlchemy NullPool issue #19379
ENV MLFLOW_SQLALCHEMYSTORE_POOLCLASS=NullPool

# Install additional dependencies
RUN pip install -r requirements.txt
RUN apt-get update && apt-get install -y nginx apache2-utils openssl && rm -rf /var/lib/apt/lists/*

# server.sh will create the htpasswd file dynamically at container start
RUN chmod +x /server.sh

# Expose port
EXPOSE 8080

# Run server
CMD ["/server.sh"]
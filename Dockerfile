FROM python:3.13-slim

# Copy the repo
WORKDIR /
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY requirements.txt requirements.txt
COPY server.sh /server.sh

# Install MLflow and Nginx
RUN pip install --upgrade pip && pip install -r requirements.txt
RUN apt-get update && apt-get install -y nginx apache2-utils openssl && rm -rf /var/lib/apt/lists/*

# server.sh will create the htpasswd file dynamically at container start
RUN chmod +x /server.sh

# Expose port
EXPOSE 8080

# Run server
CMD ["/server.sh"]
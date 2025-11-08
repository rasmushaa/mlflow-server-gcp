FROM python:3.13-slim

WORKDIR /

# Install nginx and openssl (used to create htpasswd). Keep image small by
# cleaning apt lists after install.
RUN apt-get update \
	&& apt-get install -y --no-install-recommends nginx openssl \
	&& rm -rf /var/lib/apt/lists/*

COPY nginx.conf /etc/nginx/nginx.conf
COPY requirements.txt requirements.txt
COPY server.sh server.sh

RUN pip install --upgrade pip && pip install -r requirements.txt

EXPOSE 8080

RUN chmod +x server.sh

ENTRYPOINT ["./server.sh"]
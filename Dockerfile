FROM python:3.13-slim

WORKDIR /

COPY nginx.conf /etc/nginx/nginx.conf
COPY requirements.txt requirements.txt 
COPY server.sh server.sh

RUN pip install --upgrade pip && pip install -r requirements.txt

EXPOSE 8080

RUN chmod +x server.sh

ENTRYPOINT ["./server.sh"]
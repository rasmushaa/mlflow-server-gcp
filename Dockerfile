FROM python:3.13-slim

WORKDIR /

COPY requirements.txt requirements.txt 
COPY server.sh server.sh

RUN pip install --upgrade pip && pip install -r requirements.txt

EXPOSE 8080

RUN chmod +x server.sh

ENTRYPOINT ["./server.sh"]
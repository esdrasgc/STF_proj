FROM python:3.12.3-slim

WORKDIR /app

# System deps (optional, keep minimal)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Python deps
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt
COPY requirements_coletor_ids.txt /app/
RUN pip install --no-cache-dir -r requirements_coletor_ids.txt

# App code
COPY scrapping_codes /app/scrapping_codes
COPY connect_mongo.py /app/
COPY coleta_processo.py /app/
COPY coleta_aba.py /app/
COPY celery_app.py /app/
COPY coletor_range_ids.py /app/
COPY stf_pause.py /app/
COPY start_worker.sh /app/start_worker.sh

# Start script and port for FastAPI
RUN chmod +x /app/start_worker.sh
EXPOSE 8000

# Default command: start FastAPI + Celery worker
CMD ["sh", "/app/start_worker.sh"]

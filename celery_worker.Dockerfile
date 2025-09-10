FROM python:3.12.3-slim

WORKDIR /app

# System deps (optional, keep minimal)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Python deps
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# App code
COPY scrapping_codes /app/scrapping_codes
COPY connect_mongo.py /app/
COPY coleta_processo.py /app/
COPY coleta_aba.py /app/
COPY celery_app.py /app/

# Default command: start Celery worker listening to both queues
# Increase concurrency as needed or control via docker-compose
CMD ["celery", "-A", "celery_app", "worker", "-Q", "processo,abas", "--loglevel=INFO"]

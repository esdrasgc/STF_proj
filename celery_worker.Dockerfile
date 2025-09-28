FROM python:3.12.3-slim

WORKDIR /app

# System deps (optional, keep minimal)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Python deps
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Coletor (FastAPI) deps
COPY requirements_coletor_ids.txt /app/
RUN pip install --no-cache-dir -r requirements_coletor_ids.txt
# App code
COPY scrapping_codes /app/scrapping_codes
COPY connect_mongo.py /app/
COPY coleta_processo.py /app/
COPY coleta_aba.py /app/
COPY celery_app.py /app/
COPY config_rate_limit.py /app/
COPY rate_limiter.py /app/
COPY aws_ip_rotator.py /app/
COPY coletor_range_ids.py /app/
COPY rate_limit_dispatcher.py /app/

# Start script to run FastAPI (coletor) and Celery worker together
COPY start_worker.sh /app/start_worker.sh
RUN chmod +x /app/start_worker.sh
EXPOSE 8000

# Expose Flower port
EXPOSE 5555

# Default command: start FastAPI + Celery worker. Use JSON to preserve signals.
CMD ["sh", "/app/start_worker.sh"]

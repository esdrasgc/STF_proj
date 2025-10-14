#!/usr/bin/env sh
set -e

# Defaults (can be overridden by env)
UVICORN_HOST="${UVICORN_HOST:-0.0.0.0}"
UVICORN_PORT="${UVICORN_PORT:-8000}"
WORKER_CONCURRENCY="${WORKER_CONCURRENCY:-1}"
WORKER_PREFETCH_MULTIPLIER="${WORKER_PREFETCH_MULTIPLIER:-1}"

echo "[start_worker] Starting FastAPI coletor on ${UVICORN_HOST}:${UVICORN_PORT}"
uvicorn coletor_range_ids:app \
  --host ${UVICORN_HOST} \
  --port ${UVICORN_PORT} \
  --proxy-headers \
  --log-level info &

# Small delay to ensure API starts
sleep 1

echo "[start_worker] Starting Celery worker with concurrency=${WORKER_CONCURRENCY} prefetch=${WORKER_PREFETCH_MULTIPLIER}"
exec celery -A celery_app worker \
  -Q processo,abas \
  -l INFO \
  -c ${WORKER_CONCURRENCY} \
  --prefetch-multiplier=${WORKER_PREFETCH_MULTIPLIER}

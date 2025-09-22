import os
from celery import Celery
from config_rate_limit import config

# Broker (RabbitMQ) and Backend (MongoDB) configuration from environment
BROKER_URL = os.getenv("CELERY_BROKER_URL", "amqp://guest:guest@rabbitmq:5672//")
RESULT_BACKEND = os.getenv(
    "CELERY_RESULT_BACKEND",
    # Default to MongoDB backend on the docker-compose network
    "mongodb://root:example@mongo:27017/celery_results?authSource=admin",
)

app = Celery("stf_proj", broker=BROKER_URL, backend=RESULT_BACKEND)

# General Celery configuration
app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="America/Sao_Paulo",
    enable_utc=False,
    # Route tasks to specific queues
    task_routes={
        "tasks_processo.*": {"queue": "processo"},
        "tasks_abas.*": {"queue": "abas"},
    },
    task_acks_late=True,  # ensure tasks are re-queued if worker dies mid-processing
    worker_prefetch_multiplier=1,  # avoid over-prefetching when tasks may block
    # Rate limiting configurations usando config centralizada
    worker_concurrency=config.WORKER_CONCURRENCY,  # Controla workers simultâneos
    task_default_rate_limit=f'{config.MAX_REQUESTS_PER_MINUTE}/m',  # Rate limit por worker
    # Configurações de retry usando config centralizada
    task_default_retry_delay=config.RETRY_COUNTDOWN_SECONDS,
    task_max_retries=config.MAX_RETRIES
)

# Ensure tasks are registered when worker starts
app.conf.include = [
    'coleta_processo',
    'coleta_aba',
]

# Optional explicit imports (safe-guard during worker boot)
try:
    import coleta_processo  # noqa: F401
    import coleta_aba  # noqa: F401
except Exception:
    pass

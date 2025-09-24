import typing
import logging
import time
from celery import Celery
from kombu import Message, Queue as KQueue

from config_rate_limit import config
from fnmatch import fnmatch
from rate_limiter import RateLimiter, rate_limiter
from celery_app import app as celery_app

logger = logging.getLogger(__name__)


def _pick_from_queue(celeryapp: Celery, queue_name: str) -> typing.Optional[Message]:
    # Ensure the queue exists before trying basic_get
    try:
        q = KQueue(queue_name)
        with celeryapp.connection_for_write() as conn_w:
            q.bind(conn_w).declare()
    except Exception as e:
        logger.warning(f"[Dispatcher] Could not declare queue {queue_name}: {e}")

    with celeryapp.connection_for_read() as conn:
        msg = conn.default_channel.basic_get(queue_name, no_ack=True)
    return msg


def _message_to_dict(message: Message) -> dict:
    # Preserve raw body and amqp properties to avoid re-serialization issues
    return {
        "headers": {**message.headers},
        "body_raw": message.body,  # raw bytes
        "properties": {**getattr(message, "properties", {})},
    }


def _get_queue_name_for_task(celeryapp: Celery, task_name: str) -> str:
    # First, try explicit dict of task_routes using fnmatch
    routes = getattr(celeryapp.conf, "task_routes", {}) or {}
    for pattern, route in routes.items():
        try:
            if fnmatch(task_name, pattern):
                return route.get("queue") or celeryapp.conf.task_default_queue or "processo"
        except Exception:
            continue
    # Fallback by prefix
    if task_name.startswith("tasks_processo."):
        return "processo"
    if task_name.startswith("tasks_abas."):
        return "abas"
    # Final fallback to processo to ensure worker consumes it
    return celeryapp.conf.task_default_queue or "processo"


def _publish_task(celeryapp: Celery, message: Message, queue_name: str):
    try:
        with celeryapp.connection_for_write() as conn:
            producer = conn.Producer()
            msg = _message_to_dict(message)
            routing_key = queue_name
            exchange_name = ""  # direct to queue via default (anon) exchange
            logger.info(
                f"[Dispatcher] Republishing task {msg['headers'].get('task')} -> queue={queue_name}"
            )
            props = msg.get("properties", {})
            producer.publish(
                body=msg["body_raw"],
                headers=msg["headers"],
                exchange=exchange_name,
                routing_key=routing_key,
                content_type=props.get("content_type"),
                content_encoding=props.get("content_encoding"),
                priority=props.get("priority"),
                correlation_id=props.get("correlation_id"),
                reply_to=props.get("reply_to"),
                delivery_mode=props.get("delivery_mode"),
                expiration=props.get("expiration"),
                serializer=None,  # body is already encoded
            )
    except Exception as ex:
        logger.error(f"[Dispatcher] Failed to publish task: {ex}")


def _blocked_now() -> bool:
    # Use RateLimiter's redis to check a global block key
    client = getattr(rate_limiter, "redis_client", None)
    if not client:
        return False
    try:
        until = client.get("stf:block_until")
        if not until:
            return False
        try:
            until_ts = float(until)
        except Exception:
            client.delete("stf:block_until")
            return False
        return time.time() < until_ts
    except Exception:
        return False


def set_global_block(seconds: int = 120):
    client = getattr(rate_limiter, "redis_client", None)
    if not client:
        return
    try:
        until = time.time() + seconds
        client.set("stf:block_until", str(until), ex=seconds)
        logger.warning(f"[Dispatcher] Global block set for {seconds}s")
    except Exception:
        pass


def is_blocked() -> bool:
    """Retorna True se há bloqueio global ativo (ex.: após 403)."""
    return _blocked_now()


@celery_app.on_after_finalize.connect
def setup_periodic_dispatchers(sender, **kwargs):
    # Dispatcher for processo queue cadence
    sender.add_periodic_task(
        config.SECS_PER_TASK_PROCESSO,
        dispatch_from_rate_limited_processo.s().set(queue="processo"),
        name="dispatcher_processo",
    )
    # Dispatcher for abas queue cadence
    sender.add_periodic_task(
        config.SECS_PER_TASK_ABAS,
        dispatch_from_rate_limited_abas.s().set(queue="processo"),
        name="dispatcher_abas",
    )


@celery_app.task(bind=True, name="dispatcher.dispatch_from_rate_limited_processo")
def dispatch_from_rate_limited_processo(self):
    if _blocked_now():
        logger.warning("[Dispatcher] Block active, skipping processo dispatch")
        return
    msg = _pick_from_queue(self.app, "rate_limited_processo")
    if not msg:
        return
    task_name = msg.headers.get("task")
    target_queue = _get_queue_name_for_task(self.app, task_name)
    _publish_task(self.app, msg, target_queue)


@celery_app.task(bind=True, name="dispatcher.dispatch_from_rate_limited_abas")
def dispatch_from_rate_limited_abas(self):
    if _blocked_now():
        logger.warning("[Dispatcher] Block active, skipping abas dispatch")
        return
    msg = _pick_from_queue(self.app, "rate_limited_abas")
    if not msg:
        return
    task_name = msg.headers.get("task")
    target_queue = _get_queue_name_for_task(self.app, task_name)
    _publish_task(self.app, msg, target_queue)

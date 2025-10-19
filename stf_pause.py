import time
from celery_app import app
from celery.app.control import Control

PAUSE_DEFAULT_SECONDS = 150
QUEUES = ["processo", "abas"]

def pause_consumption(seconds: int = PAUSE_DEFAULT_SECONDS):
    try:
        control = Control(app)
        for q in QUEUES:
            control.cancel_consumer(q, destination=None)
        time.sleep(seconds)
    finally:
        for q in QUEUES:
            control.add_consumer(q, destination=None)

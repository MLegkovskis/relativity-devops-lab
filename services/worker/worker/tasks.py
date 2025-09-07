import os
from celery import Celery
from core_physics.integrators import integrate_trajectory
from core_physics.models import BlackHole

CELERY_BROKER_URL = os.getenv("CELERY_BROKER_URL", "redis://redis:6379/0")
CELERY_BACKEND_URL = os.getenv("CELERY_BACKEND_URL", "redis://redis:6379/1")

celery = Celery("bh", broker=CELERY_BROKER_URL, backend=CELERY_BACKEND_URL)

@celery.task
def integrate_task(mass, x, y, vx, vy, steps=50000, dlam=1.0):
    bh = BlackHole(mass=mass)
    return integrate_trajectory(bh, x, y, vx, vy, steps, dlam)

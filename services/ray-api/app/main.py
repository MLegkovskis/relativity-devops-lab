from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from core_physics.models import BlackHole
from core_physics.integrators import integrate_trajectory

app = FastAPI(title="Ray API")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

class IntegrateReq(BaseModel):
    mass: float
    x: float; y: float
    vx: float; vy: float
    steps: int = 1000
    dlam: float = 1.0

@app.post("/integrate")
def integrate(req: IntegrateReq):
    bh = BlackHole(mass=req.mass)
    return integrate_trajectory(bh, req.x, req.y, req.vx, req.vy, req.steps, req.dlam)

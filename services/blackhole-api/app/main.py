from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from core_physics.constants import schwarzschild_radius

app = FastAPI(title="Black Hole API")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

class BHReq(BaseModel):
    mass: float

@app.post("/derived")
def derived(req: BHReq):
    return {"mass": req.mass, "schwarzschild_radius": schwarzschild_radius(req.mass)}

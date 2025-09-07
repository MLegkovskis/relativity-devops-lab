from dataclasses import dataclass
from typing import List, Tuple

@dataclass(frozen=True)
class BlackHole:
    mass: float  # kg

@dataclass
class RayState:
    x: float; y: float
    r: float; phi: float
    dr: float; dphi: float
    E: float
    trail: List[Tuple[float, float]]

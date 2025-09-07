from .constants import schwarzschild_radius
from .models import RayState, BlackHole
import math

def geodesic_rhs(ray: RayState, rs: float):
    r, dr, dphi, E = ray.r, ray.dr, ray.dphi, ray.E
    f = 1.0 - rs / r
    dt_dlam = E / f
    rhs0 = dr
    rhs1 = dphi
    rhs2 = -(rs / (2.0 * r * r)) * f * (dt_dlam * dt_dlam) + (rs / (2.0 * r * r * f)) * (dr * dr) + (r - rs) * (dphi * dphi)
    rhs3 = -2.0 * dr * dphi / r
    return rhs0, rhs1, rhs2, rhs3

def rk4_step(ray: RayState, dlam: float, rs: float):
    y0 = (ray.r, ray.phi, ray.dr, ray.dphi)

    def add(a, b, f): return tuple(a[i] + f*b[i] for i in range(4))
    k1 = geodesic_rhs(ray, rs)
    r2 = RayState(ray.x, ray.y, *add(y0, k1, dlam/2.0), ray.E, ray.trail.copy())
    k2 = geodesic_rhs(r2, rs)
    r3 = RayState(ray.x, ray.y, *add(y0, k2, dlam/2.0), ray.E, ray.trail.copy())
    k3 = geodesic_rhs(r3, rs)
    r4 = RayState(ray.x, ray.y, *add(y0, k3, dlam), ray.E, ray.trail.copy())
    k4 = geodesic_rhs(r4, rs)

    ray.r   += (dlam / 6.0) * (k1[0] + 2*k2[0] + 2*k3[0] + k4[0])
    ray.phi += (dlam / 6.0) * (k1[1] + 2*k2[1] + 2*k3[1] + k4[1])
    ray.dr  += (dlam / 6.0) * (k1[2] + 2*k2[2] + 2*k3[2] + k4[2])
    ray.dphi+= (dlam / 6.0) * (k1[3] + 2*k2[3] + 2*k3[3] + k4[3])

def integrate_trajectory(bh: BlackHole, x: float, y: float, vx: float, vy: float,
                        steps: int = 1000, dlam: float = 1.0):
    rs = schwarzschild_radius(bh.mass)
    r = math.hypot(x, y)
    phi = math.atan2(y, x)
    dr = vx * math.cos(phi) + vy * math.sin(phi)
    dphi = (-vx * math.sin(phi) + vy * math.cos(phi)) / r
    f = 1.0 - rs / r
    dt_dlam = math.sqrt((dr*dr)/(f*f) + (r*r*dphi*dphi)/f)
    E = f * dt_dlam

    ray = RayState(x, y, r, phi, dr, dphi, E, [(x, y)])
    for _ in range(steps):
        if ray.r <= rs:
            break
        rk4_step(ray, dlam, rs)
        ray.x = ray.r * math.cos(ray.phi)
        ray.y = ray.r * math.sin(ray.phi)
        ray.trail.append((ray.x, ray.y))
    return {"trail": ray.trail, "hit_horizon": ray.r <= rs, "rs": rs}

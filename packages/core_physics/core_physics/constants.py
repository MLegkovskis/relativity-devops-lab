import math
c = 299_792_458.0
G = 6.67430e-11
M_PI = math.pi

def schwarzschild_radius(mass: float) -> float:
    return 2.0 * G * mass / (c * c)

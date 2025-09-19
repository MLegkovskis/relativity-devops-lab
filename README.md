
# Blackhole-Sim: Microservices (to be) Physics Demo

>This project is a hands-on introduction to microservices, APIs, and containerization using a physics simulation of light rays near a black hole. It's designed for beginners—no prior experience with microservices or APIs required!

---

## What is this?

**blackhole-sim** splits a physics simulation into small, independent services (microservices). Each service does one job and talks to others via simple APIs. Everything runs in Docker containers, so you can launch the whole system with one command.

---

## Project Structure

```
blackhole-sim/
├── README.md                # This guide
├── .env                     # Environment variables (e.g. Redis URLs)
├── Makefile                 # Shortcuts for common commands
├── pyproject.toml           # Dev tooling config (formatters, etc.)
├── infra/
│   └── docker-compose.yml   # Main file to launch all services
├── packages/
│   └── core_physics/        # Pure physics library (no graphics)
│       ├── core_physics/
│       │   ├── __init__.py
│       │   ├── constants.py
│       │   ├── models.py
│       │   ├── integrators.py
│       │   └── api.py
│       ├── pyproject.toml
│       └── README.md
├── schemas/                 # JSON schemas for API data
│   ├── ray.json
│   ├── blackhole.json
│   └── trajectory.json
├── services/
│   ├── ray-api/             # FastAPI service: integrates ray trajectories
│   ├── blackhole-api/       # FastAPI service: computes black hole properties
│   ├── worker/              # Celery worker: runs long jobs, uses Redis
│   └── renderer-gl/         # (optional) OpenGL renderer
│   └── ui-static/           # Nginx container serving the web UI
├── tools/
│   └── devcontainer/        # VS Code devcontainer config
└── ui/
	└── index.html           # Minimal web UI (canvas + button)
```

---

## How does it work?

### 1. Core Physics Library (`packages/core_physics`)
- Contains all the math and logic for simulating rays near a black hole.
- **Stateless**: Given inputs, it always returns the same outputs.
- Used by all other services—this is the "source of truth" for physics.

### 2. Microservices (in `services/`)

#### a) `ray-api`
- **Purpose**: Accepts ray parameters (position, velocity, etc.) and returns the computed trajectory.
- **Tech**: FastAPI (Python web framework)
- **API**: `/integrate` endpoint (POST)
- **Depends on**: `core_physics` package

#### b) `blackhole-api`
- **Purpose**: Computes black hole properties (e.g., Schwarzschild radius) from mass.
- **Tech**: FastAPI
- **API**: `/derived` endpoint (POST)
- **Depends on**: `core_physics` package

#### c) `worker`
- **Purpose**: Handles long-running physics jobs asynchronously (e.g., for many rays).
- **Tech**: Celery (Python task queue), Redis (message broker)
- **Depends on**: `core_physics`, Redis

#### d) `ui-static`
- **Purpose**: Serves the static web UI (HTML/JS/CSS) via Nginx.
- **Tech**: Nginx
- **Depends on**: None (just serves files)

#### e) `renderer-gl` (optional)
- **Purpose**: (Future) Containerized OpenGL renderer for advanced graphics.
- **Tech**: Python + OpenGL
- **Depends on**: `core_physics` (fetches trajectories)

---

## How do the services talk?

- **APIs**: Services communicate via HTTP APIs (JSON data). For example, the UI calls `ray-api` and `blackhole-api` to get simulation results.
- **Worker**: Uses Redis to queue and process long jobs.

---

## How do I run it?

1. **Install Docker** (if you don't have it).
2. In the project folder, run:
   ```bash
   docker compose up --build
   ```
3. Open [http://localhost:8080](http://localhost:8080) in your browser to see the UI.
4. Click "Fire" to launch rays and watch the simulation!

---

## Key Dependencies

- **Python 3.11** (core code, APIs, worker)
- **FastAPI** (web APIs)
- **Celery** (async worker)
- **Redis** (message broker for worker)
- **Nginx** (serves static UI)
- **Docker Compose** (orchestrates all containers)

---

## Why microservices?

- **Separation of concerns**: Each service does one thing well.
- **Scalability**: You can run more copies of a service if needed.
- **Resilience**: If one service fails, others keep running.
- **Easy updates**: Change one service without breaking the rest.

---

## FAQ

**Q: Do I need to know Docker or APIs to use this?**
A: No! Just follow the steps above. The system is designed to be beginner-friendly.

**Q: How do I change the simulation?**
A: Edit the core physics code in `packages/core_physics/core_physics/`. All services use this code.

**Q: How do I add a new service?**
A: Copy the pattern in `services/`, create a new FastAPI app, and connect it to the core package.

**Q: How do I see the API docs?**
A: Visit [http://localhost:8000/docs](http://localhost:8000/docs) (ray-api) or [http://localhost:8001/docs](http://localhost:8001/docs).

---

## Next steps

- Try changing the UI or physics code and see what happens!
- Add more endpoints or services as you learn.
- Explore Kubernetes or cloud deployment when you're ready.

---

**Enjoy learning microservices with physics!**

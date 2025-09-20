# Blackhole-Sim: Containers & Microservices Learning Lab

This project is a physics-themed sandbox for learning how microservices behave when you package them into containers and orchestrate them with two common tools:

- **Docker Compose** – fast local iteration on a single machine
- **Kubernetes (k3s)** – declarative orchestration with the same services

The code base stays identical; only the deployment descriptors change. That makes it ideal for DevOps engineers who want to compare how the same workload is wired together in Compose versus Kubernetes.

---

## System At A Glance

| Service | Tech | Role | API / Port |
| ------- | ---- | ---- | ---------- |
| `ray-api` | FastAPI | Integrates photon trajectories | `POST /integrate` on `8000` |
| `blackhole-api` | FastAPI | Calculates black hole derived values | `POST /derived` on `8001` |
| `worker` | Celery + Redis | Handles background jobs (not surfaced in UI yet) | connects to Redis |
| `redis` | Redis | Message broker + result store | `6379` |
| `ui-static` | Nginx serving `services/ui-static/index.html` | Browser UI that calls both APIs | `80` (Compose maps to `8080`) |

All services share the same physics library in `packages/core_physics/`.

---

## Repository Layout

```
blackhole-kubernettes/
├── README.md                    # You are here
├── infra/
│   ├── docker-compose.yml       # Compose topology
│   └── k8s/                     # Kubernetes manifests (kustomize base)
├── packages/core_physics/       # Reusable simulation library
├── services/
│   ├── blackhole-api/           # FastAPI microservice
│   ├── ray-api/                 # FastAPI microservice
│   ├── worker/                  # Celery worker
│   └── ui-static/               # Nginx + static UI
└── tools/, schemas/, etc.
```

---

## Running With Docker Compose (local iteration)

1. Build and start everything:
   ```bash
   docker compose -f infra/docker-compose.yml up --build
   ```
2. Open `http://localhost:8080`.
3. Press **Fire** – the UI calls `http://localhost:8000` (ray-api) and `http://localhost:8001` (blackhole-api).
4. Watch logs in your terminal or tail a specific service:
   ```bash
   docker compose -f infra/docker-compose.yml logs -f ray-api
   ```
5. Stop the stack when you are done:
   ```bash
   docker compose -f infra/docker-compose.yml down
   ```

### What to Observe
- **Networking is implicit.** Services discover each other by container name (`http://ray-api:8000` etc.).
- **Images are built in place.** Compose uses local build contexts; no registry push is required.
- **The UI auto-detects this mode.** When it sees the browser running on port `8080`, it calls the host-exposed API ports.

---

## Running On k3s (Kubernetes)

The manifests under `infra/k8s/` create the same services declaratively. Instead of an ingress controller we surface the containers through NodePort services so plain `http://localhost:<port>` works out of the box.

### Images
Push the four service images to a registry reachable by k3s (example uses Docker Hub):
```bash
docker build -t marilee/blackhole-k8s:ui-dev -f services/ui-static/Dockerfile .
docker build -t marilee/blackhole-k8s:ray-api-dev -f services/ray-api/Dockerfile .
docker build -t marilee/blackhole-k8s:blackhole-api-dev -f services/blackhole-api/Dockerfile .
docker build -t marilee/blackhole-k8s:worker-dev -f services/worker/Dockerfile .

docker push marilee/blackhole-k8s:ui-dev
docker push marilee/blackhole-k8s:ray-api-dev
docker push marilee/blackhole-k8s:blackhole-api-dev
docker push marilee/blackhole-k8s:worker-dev
```

### Deploy
```bash
kubectl apply -k infra/k8s
kubectl get pods -n blackhole
kubectl get svc -n blackhole
```
Then browse to the NodePort endpoints:
- UI → `http://localhost:30080`
- ray-api → `http://localhost:30081`
- blackhole-api → `http://localhost:30082`

### Helpful Commands
```bash
kubectl logs -n blackhole -l app.kubernetes.io/name=ray-api --tail=0 -f
kubectl rollout restart deploy/ui -n blackhole
kubectl delete -k infra/k8s  # remove stack
```

### What to Observe
- **Networking is explicit.** Each public endpoint is a NodePort service; the cluster IPs stay internal, the node ports surface on `localhost`.
- **Image pulls are remote.** Deployments reference the pushed tags; `imagePullPolicy: Always` ensures fresh code on each rollout.
- **UI auto-detects this mode.** When it sees port `30080`, it calls the NodePort APIs on `30081/30082`.

### Kubernetes Resource Flow
```mermaid
graph LR
    User((Browser @ localhost)) --> UI_NodePort["Service: ui
NodePort 30080"]
    UI_NodePort --> UI_Pods["Deployment: ui
Pod(s)"]
    UI_Pods --> Ray_NodePort["Service: ray-api
NodePort 30081"]
    UI_Pods --> BH_NodePort["Service: blackhole-api
NodePort 30082"]
    Ray_NodePort --> Ray_Pods["Deployment: ray-api
Pod(s)"]
    BH_NodePort --> BH_Pods["Deployment: blackhole-api
Pod(s)"]
    Worker_Pods["Deployment: worker
Pod(s)"] --> Redis_Svc["Service: redis
ClusterIP 6379"]
    Redis_Svc --> Redis_Pods["Deployment: redis
Pod"]
    subgraph Namespace: blackhole
        UI_NodePort
        UI_Pods
        Ray_NodePort
        Ray_Pods
        BH_NodePort
        BH_Pods
        Worker_Pods
        Redis_Svc
        Redis_Pods
    end
```

### Kubectl Command Reference
Below is a field guide of the `kubectl` commands we used (and a few extras) with context-specific notes and sample outputs. All commands assume the resources live in the `blackhole` namespace established by the manifests.

**Inventory & Status**
```bash
kubectl get pods -n blackhole
```
_Output sample_
```
NAME                             READY   STATUS    RESTARTS   AGE
blackhole-api-74678bf757-6gfgl   1/1     Running   0          5m
ray-api-6896647c7c-597dh         1/1     Running   0          5m
redis-68657b4474-6gzwz           1/1     Running   0          5m
ui-d8d5dd8f7-pwb4m               1/1     Running   0          5m
worker-7fdcb9b789-kt626          1/1     Running   0          5m
```

```bash
kubectl get pods -n blackhole -o wide
```
_Shows pod IPs, nodes, and container images._
```
NAME                             READY   STATUS    RESTARTS   AGE   IP           NODE                    NOMINATED NODE   READINESS GATES
blackhole-api-74678bf757-6gfgl   1/1     Running   0          5m    10.42.0.9    mark-inspiron-14-5425   <none>           <none>
ray-api-6896647c7c-597dh         1/1     Running   0          5m    10.42.0.11   mark-inspiron-14-5425   <none>           <none>
...
```

```bash
kubectl get svc -n blackhole
```
_Verify NodePort allocations and cluster IPs._
```
NAME             TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)           AGE
blackhole-api    NodePort   10.43.82.103   <none>        8001:30082/TCP    5m
ray-api          NodePort   10.43.6.177    <none>        8000:30081/TCP    5m
redis            ClusterIP  10.43.122.38   <none>        6379/TCP          5m
ui               NodePort   10.43.2.78     <none>        80:30080/TCP      5m
```

**Logs & Debugging**
```bash
kubectl logs deploy/ray-api -n blackhole --tail=20
```
_Fetch the latest requests handled by the ray tracer._
```
INFO:     10.42.0.12:49164 - \"POST /integrate HTTP/1.1\" 200 OK
```

```bash
kubectl logs -n blackhole -l app.kubernetes.io/name=ray-api --tail=0 -f
```
_Stream new log lines each time you press **Fire** in the UI (Ctrl+C to stop)._

```bash
kubectl describe pod ray-api-6896647c7c-597dh -n blackhole
```
_Detailed events, environment variables, and probe results for a specific pod._

**Rollouts & Scaling**
```bash
kubectl rollout status deploy/ui -n blackhole
```
_Wait for the UI deployment to become ready after a push._

```bash
kubectl rollout restart deploy/ui -n blackhole
```
_Forces Kubernetes to pull the latest `marilee/blackhole-k8s:ui-dev` tag._

```bash
kubectl scale deploy/ray-api --replicas=2 -n blackhole
```
_Spins up an extra API replica so you can watch request balancing._

**Port Forwarding & One-offs**
```bash
kubectl port-forward svc/ray-api 9000:8000 -n blackhole
```
_Expose the in-cluster API on `localhost:9000` without touching NodePorts._

```bash
kubectl get events -n blackhole --sort-by=.metadata.creationTimestamp
```
_View chronological events to debug probe failures or scheduling delays._

**Cleanup**
```bash
kubectl delete -k infra/k8s
```
_Removes the namespace, deployments, and services created by the manifests._

### Label Cheatsheet
We stick to a small set of labels so selectors stay readable:
- `app.kubernetes.io/name` – canonical service name; used by Services to discover Pods.
- `app.kubernetes.io/instance` – unique identifier for this workload (convenient when you run multiple stacks).
- `app.kubernetes.io/component` – aligns with the Kubernetes recommended labels and pairs with the Service selectors.
- `app.kubernetes.io/part-of` – indicates the broader application so you can query everything related to Blackhole.
- `tier` – human term for the role (`frontend`, `api`, `worker`, `datastore`).
- `system` – umbrella application (`blackhole`).

---
## Compose vs Kubernetes – Side-by-Side

| Concern | Docker Compose | Kubernetes (k3s) | Takeaway |
| ------- | --------------- | ----------------- | -------- |
| Orchestration file | `infra/docker-compose.yml` | `infra/k8s/*.yaml` (kustomize) | Compose is imperative; Kubernetes is declarative. |
| Networking | Automatic service discovery through Docker DNS | Explicit `Service` objects and NodePort exposure | Kubernetes forces you to model networking upfront. |
| Image distribution | Built locally, shared via Docker daemon | Pulled from registry (or preloaded into cluster) | Registries are part of the workflow in Kubernetes. |
| Scaling | `docker compose up --scale service=n` | `spec.replicas` per `Deployment` | Both can scale, Kubernetes records desired state. |
| Config updates | `docker compose up --build` rebuilds and restarts | `kubectl apply` + `kubectl rollout restart` | Kubernetes separates configuration from rollout control. |
| Logs | `docker compose logs` | `kubectl logs` with label selectors | Same data, different tooling. |
| UI routing | Browser hits host ports directly (`localhost:8080` → `8000/8001`) | Browser uses NodePorts (`localhost:30080` → `30081/30082`) | The UI detects which path to use at runtime. |

Both environments share the same code, Dockerfiles, and environment variables. The only difference is how endpoints are exposed and how images reach the runtime.

---

## Learning Checklist

1. **Trace a request** – When you press **Fire**, follow the call in both environments:
   - UI → `blackhole-api` `/derived`
   - UI → `ray-api` `/integrate`
   - UI renders trajectory

2. **Inspect logs** – Compose vs Kubernetes commands above.

3. **Modify the physics** – Change `packages/core_physics/core_physics/integrators.py`, rebuild images, and redeploy in both setups to observe the update flow.

4. **Scale a service** – Try `docker compose up --scale ray-api=2` vs `kubectl scale deploy/ray-api --replicas=2 -n blackhole` and watch how each platform balances requests.

---

## Troubleshooting Cheatsheet

| Symptom | Likely Cause | Fix |
| ------- | ------------ | --- |
| UI shows `NetworkError` in Compose | APIs not reachable on host ports | Ensure Compose stack is up; check `docker compose ps`. |
| UI shows `NetworkError` on k3s | NodePort services not reachable or images stale | Reapply manifests, ensure images are pushed, and confirm ports 30080-30082 are open. |
| Pods stay in `ImagePullBackOff` | Registry not accessible or tag missing | Push images to the configured registry or preload them: `k3s ctr images import`. |

---

## Cleaning Up

- **Stop Compose stack**: `docker compose -f infra/docker-compose.yml down`
- **Remove Kubernetes stack**: `kubectl delete -k infra/k8s`
- **Uninstall k3s entirely** *(optional)*: `sudo /usr/local/bin/k3s-uninstall.sh`

---

### Why This Project Matters

The code stays constant while the orchestration changes. By diffing the Compose and Kubernetes directories you can see exactly what extra plumbing Kubernetes expects—namespaces, services, NodePorts, rollouts—without changing a single line of application logic. That tangible comparison makes it an effective jump-off point for learning containers, microservices, and modern platform engineering.

Enjoy the journey!

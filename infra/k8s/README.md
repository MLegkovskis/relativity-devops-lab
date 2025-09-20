# Blackhole on Kubernetes

This directory contains Kubernetes manifests for running the application on a local k3s cluster. Resources are organised as a small kustomize base so you can apply everything with a single command.

## Layout
- `namespace.yaml` – creates the `blackhole` namespace used by all workloads.
- `redis.yaml` – deployment and service for the Redis datastore.
- `ray-api.yaml` / `blackhole-api.yaml` – API deployments with NodePort services you can hit from localhost.
- `worker.yaml` – background worker deployment wired to Redis.
- `ui.yaml` – static UI deployment with a NodePort service.
- `kustomization.yaml` – helper to apply the stack.

## Usage
1. Build the images referenced in the manifests (`marilee/blackhole-k8s:ui-dev`, `marilee/blackhole-k8s:ray-api-dev`, etc.) and load them into k3s. For a local cluster you can run `k3s ctr images import <tarball>` or push to a registry accessible to k3s.
2. Apply the manifests:
   ```bash
   kubectl apply -k infra/k8s
   ```
3. Once the pods are ready, open the UI on the NodePort service: http://localhost:30080
   - ray-api lives at http://localhost:30081
   - blackhole-api lives at http://localhost:30082
4. Check rollouts:
   ```bash
   kubectl get pods -n blackhole
   kubectl get svc -n blackhole
   ```

To remove everything, run `kubectl delete -k infra/k8s`.

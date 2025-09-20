# Blackhole on Kubernetes

This directory contains Kubernetes manifests for running the application on a local k3s cluster. Resources are organised as a small kustomize base so you can apply everything with a single command.

## Layout
- `namespace.yaml` – creates the `blackhole` namespace used by all workloads.
- `redis.yaml` – deployment and service for the Redis datastore.
- `ray-api.yaml` / `blackhole-api.yaml` – API deployments with internal services.
- `worker.yaml` – background worker deployment wired to Redis.
- `ui.yaml` – static UI deployment with service exposed via ingress.
- `ingress.yaml` – Traefik ingress routing `localhost` to the UI service.
- `kustomization.yaml` – helper to apply the stack.

## Usage
1. Build the images referenced in the manifests (`marilee/blackhole-k8s:ui-dev`, `marilee/blackhole-k8s:ray-api-dev`, etc.) and load them into k3s. For a local cluster you can run `k3s ctr images import <tarball>` or push to a registry accessible to k3s.
2. Apply the manifests:
   ```bash
   kubectl apply -k infra/k8s
   ```
3. Browse to http://localhost/ once the pods are ready.
4. Check rollouts:
   ```bash
   kubectl get pods -n blackhole
   kubectl get ingress -n blackhole
   ```

To remove everything, run `kubectl delete -k infra/k8s`.

# Launching the UI with Helm

This chart deploys the `ui` service into a Kubernetes cluster with a single configurable value: the container image repository.

## Prerequisites

- `kubectl` and `helm` installed and pointing at your target cluster (`kubectl config current-context`).
- Permission to create the `blackhole` namespace if it does not exist.

## Install or Upgrade

```bash
helm upgrade --install blackhole infra/helm \
  --namespace blackhole \
  --create-namespace \
  --set repository=<your-docker-username>/blackhole-k8s
```

Skip the `--set` flag to keep the default repository defined in `values.yaml`.

If you previously created the `ui` resources with another tool (for example Kustomize), remove them first so Helm can take ownership:

```bash
kubectl delete svc ui -n blackhole
kubectl delete deployment ui -n blackhole  # ignore if it is missing
```

Rerun the Helm command once the old resources are gone.

## Verify the Deployment

```bash
kubectl get pods -n blackhole -w
```

Wait until the `ui` pod reports `Running`, then press `Ctrl+C` to stop watching.

## Access the UI

The service is exposed as a NodePort on `30080`. In k3s you can hit any node's IP on that port:

```bash
kubectl get svc ui -n blackhole
```

## Optional: Render Without Installing

```bash
helm template blackhole-ui infra/helm --namespace blackhole
```

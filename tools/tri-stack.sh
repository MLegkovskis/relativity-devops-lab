#!/usr/bin/env bash
# Launch or tear down the app via Docker Compose, k3s (Kustomize), and Helm simultaneously.
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
COMPOSE_FILE="$ROOT_DIR/infra/docker-compose.yml"
KUSTOMIZE_DIR="$ROOT_DIR/infra/k8s"
HELM_CHART="$ROOT_DIR/infra/helm"
UI_SOURCE="$ROOT_DIR/services/ui-static/index.html"
HELM_INDEX="$HELM_CHART/files/index.html"
K8S_INDEX_DIR="$KUSTOMIZE_DIR/ui-index"
K8S_INDEX="$K8S_INDEX_DIR/index.html"

COMPOSE_UI_PORT=8080
K3S_UI_PORT=30080
K3S_RAY_PORT=30081
K3S_BH_PORT=30082
K3S_NAMESPACE=blackhole

HELM_UI_PORT=31080
HELM_RAY_PORT=31081
HELM_BH_PORT=31082
HELM_RELEASE=blackhole-ui-helm
HELM_NAMESPACE=blackhole-helm

log() {
  printf '[%(%H:%M:%S)T] %s\n' -1 "$*"
}

fatal() {
  echo "Error: $*" >&2
  exit 1
}

sync_ui_assets() {
  [[ -f $UI_SOURCE ]] || fatal "UI source HTML not found at $UI_SOURCE"
  mkdir -p "$(dirname "$HELM_INDEX")"
  mkdir -p "$(dirname "$K8S_INDEX")"
  ln -sf "$UI_SOURCE" "$HELM_INDEX"
  ln -sf "$UI_SOURCE" "$K8S_INDEX"
}

wait_for_url() {
  local label=$1
  local url=$2
  local timeout=${3:-180}
  local interval=${4:-2}
  local spinner='|/-\\'
  local tick=0
  local elapsed=0

  printf '\r[%(%H:%M:%S)T] Waiting for %s at %s' -1 "$label" "$url"
  while (( elapsed < timeout )); do
    if curl --silent --fail --max-time 2 "$url" >/dev/null; then
      printf '\r[%(%H:%M:%S)T] %s ready (%ss)%-40s\n' -1 "$label" "$elapsed" ""
      return 0
    fi
    local frame=${spinner:tick%4:1}
    printf '\r[%(%H:%M:%S)T] %s warming %s (%ss)%-40s' -1 "$label" "$frame" "$elapsed" ""
    sleep "$interval"
    (( elapsed+=interval, tick++ ))
  done
  printf '\r[%(%H:%M:%S)T] %s not reachable after %ss (%s)%-40s\n' -1 "$label" "$elapsed" "$url" ""
  return 1
}

ensure_cmd() {
  command -v "$1" >/dev/null 2>&1 || fatal "Required command '$1' is not installed"
}

compose_command() {
  if docker compose version >/dev/null 2>&1; then
    echo "docker compose"
  elif command -v docker-compose >/dev/null 2>&1; then
    echo "docker-compose"
  else
    fatal "Docker Compose plugin or binary is required"
  fi
}

start_compose() {
  local -a compose_cmd
  read -r -a compose_cmd <<<"$(compose_command)"
  log "Starting Docker Compose stack"
  "${compose_cmd[@]}" -f "$COMPOSE_FILE" up -d --build
}

start_kustomize() {
  log "Applying k3s (Kustomize) manifests"
  if ! kubectl apply -k "$KUSTOMIZE_DIR"; then
    log "kubectl apply failed, attempting to delete conflicting resources and retry"
    kubectl delete deployment/ui service/ui \
      -n "$K3S_NAMESPACE" --ignore-not-found=true
    kubectl apply -k "$KUSTOMIZE_DIR"
  fi
}

start_helm() {
  log "Installing Helm release $HELM_RELEASE in namespace $HELM_NAMESPACE"
  helm upgrade --install "$HELM_RELEASE" "$HELM_CHART" \
    --namespace "$HELM_NAMESPACE" \
    --create-namespace \
    --set service.nodePort="$HELM_UI_PORT" \
    --set rayApi.nodePort="$HELM_RAY_PORT" \
    --set blackholeApi.nodePort="$HELM_BH_PORT" \
    --set service.type=NodePort
}

print_summary() {
  cat <<SUMMARY
All stacks are being brought up. UIs will be reachable as they become ready:
- Docker Compose → http://localhost:$COMPOSE_UI_PORT
- k3s (Kustomize) → http://localhost:$K3S_UI_PORT
- Helm → http://localhost:$HELM_UI_PORT
Helm APIs surface at http://localhost:$HELM_RAY_PORT (ray) and http://localhost:$HELM_BH_PORT (blackhole)
SUMMARY
}

stop_compose() {
  local -a compose_cmd
  read -r -a compose_cmd <<<"$(compose_command)"
  log "Stopping Docker Compose stack"
  "${compose_cmd[@]}" -f "$COMPOSE_FILE" down --volumes --remove-orphans
}

stop_kustomize() {
  log "Removing k3s (Kustomize) resources"
  kubectl delete -k "$KUSTOMIZE_DIR" --ignore-not-found=true
  kubectl delete namespace "$K3S_NAMESPACE" --ignore-not-found=true >/dev/null 2>&1 || true
}

stop_helm() {
  log "Uninstalling Helm release $HELM_RELEASE"
  helm uninstall "$HELM_RELEASE" --namespace "$HELM_NAMESPACE" --ignore-not-found
  log "Deleting namespace $HELM_NAMESPACE if empty"
  kubectl delete namespace "$HELM_NAMESPACE" --ignore-not-found=true >/dev/null 2>&1 || true
}

cleanup_all() {
  log "Ensuring previous deployments are cleaned up"
  set +e
  stop_helm
  stop_kustomize
  stop_compose
  set -e
}

main() {
  local targets=()
  if (( $# == 0 )); then
    targets=(compose k8s helm)
  else
    for arg in "$@"; do
      case "$arg" in
        compose|docker-compose|compose-only)
          targets+=(compose)
          ;;
        k8s|kustomize|k3s)
          targets+=(k8s)
          ;;
        helm)
          targets+=(helm)
          ;;
        *)
          echo "Usage: ${0##*/} [compose] [k8s] [helm]" >&2
          exit 1
          ;;
      esac
    done
  fi

  ensure_cmd docker
  ensure_cmd kubectl
  ensure_cmd helm
  ensure_cmd curl
  sync_ui_assets

  cleanup_all

  local summary=()
  for target in "${targets[@]}"; do
    case "$target" in
      compose)
        start_compose
        summary+=("- Docker Compose → http://localhost:$COMPOSE_UI_PORT")
        ;;
      k8s)
        start_kustomize
        summary+=("- k3s (Kustomize) → http://localhost:$K3S_UI_PORT")
        ;;
      helm)
        start_helm
        summary+=("- Helm → http://localhost:$HELM_UI_PORT")
        ;;
    esac
  done

  if ((${#summary[@]} > 0)); then
    printf 'Stacks launched:\n'
    printf '%s\n' "${summary[@]}"
  else
    printf 'No stacks launched.\n'
  fi

  [[ " ${targets[*]} " == *" compose "* ]] && wait_for_url "Compose UI" "http://localhost:$COMPOSE_UI_PORT" 180 3 || true
  [[ " ${targets[*]} " == *" k8s "* ]] && wait_for_url "k3s UI" "http://localhost:$K3S_UI_PORT" 180 3 || true
  [[ " ${targets[*]} " == *" helm "* ]] && wait_for_url "Helm UI" "http://localhost:$HELM_UI_PORT" 240 3 || true
}

main "$@"

#!/usr/bin/env bash
# Prepare an Ubuntu EC2 host with Docker, k3s, helm, and dependencies for tri-stack deployments.
set -euo pipefail

REMOTE_USER=${REMOTE_USER:-ubuntu}

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root (use sudo)." >&2
  exit 1
fi

echo "[setup] Updating apt repositories"
apt-get update -y

echo "[setup] Installing base packages"
apt-get install -y docker.io docker-compose-plugin curl git jq unzip rsync

echo "[setup] Enabling Docker"
systemctl enable --now docker

if ! id -nG "$REMOTE_USER" | grep -qw docker; then
  usermod -aG docker "$REMOTE_USER"
fi

# Install k3s (lightweight Kubernetes). "INSTALL_K3S_EXEC" allows chmod on kubeconfig for non-root use.
echo "[setup] Installing k3s"
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --write-kubeconfig-mode=644" sh -

mkdir -p /home/$REMOTE_USER/.kube

for _ in {1..30}; do
  if [[ -f /etc/rancher/k3s/k3s.yaml ]]; then
    cp /etc/rancher/k3s/k3s.yaml /home/$REMOTE_USER/.kube/config
    chown -R $REMOTE_USER:$REMOTE_USER /home/$REMOTE_USER/.kube
    break
  fi
  sleep 2
done

if [[ ! -f /home/$REMOTE_USER/.kube/config ]]; then
  echo "[setup] Timed out waiting for k3s kubeconfig" >&2
  exit 1
fi

cat >/etc/profile.d/k3s.sh <<PROFILE
export KUBECONFIG=/home/$REMOTE_USER/.kube/config
PROFILE
chmod 644 /etc/profile.d/k3s.sh

# Install Helm
if ! command -v helm >/dev/null 2>&1; then
  echo "[setup] Installing Helm"
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

echo "[setup] Host ready for tri-stack deployments"

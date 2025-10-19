# Dev Stacks Helper

`tri-stack.sh` is a convenience wrapper that spins up the Blackhole stacks across Docker Compose, k3s (Kustomize), and Helm.

## Usage

```bash
./tri-stack.sh [compose] [k8s] [helm]
```

- No arguments → launch all three orchestrations after a clean slate.
- Provide one or more keywords to launch only those stacks (e.g. `./tri-stack.sh compose helm`).

Each run:
- Removes any previous deployments to avoid conflicts.
- Syncs the UI HTML into the Helm and k3s ConfigMaps so the front-end matches across deployments.
- Brings up the requested stacks and shows readiness spinners for their UIs.

## Fixed Port Map

| Stack | UI | ray-api | blackhole-api |
|-------|----|---------|----------------|
| Docker Compose | `http://<host>:8080` | `http://<host>:8000` | `http://<host>:8001` |
| k3s (Kustomize) | `http://<host>:30080` | `http://<host>:30081` | `http://<host>:30082` |
| Helm | `http://<host>:31080` | `http://<host>:31081` | `http://<host>:31082` |

Adjust the constants near the top of `tri-stack.sh` if you need to remap ports.

## AWS CI/CD Pipeline

The workflow in `.github/workflows/deploy-aws.yml` boots an Ubuntu EC2 instance, installs prerequisites with `tools/setup-ubuntu-host.sh`, copies this repository over SSH, and runs `./tools/tri-stack.sh`. The job cleans up any previous instance tagged with `Project=tri-stack-demo` before launching a fresh one, so every run rebuilds the environment from scratch.

### One-time AWS Setup

1. Create (or reuse) an IAM user with AdministratorAccess and generate an access key.
2. Create an EC2 key pair the pipeline can reuse:
   ```bash
   aws ec2 create-key-pair \
     --region eu-west-2 \
     --key-name tri-stack-deploy \
     --query 'KeyMaterial' --output text > tri-stack-deploy.pem
   chmod 600 tri-stack-deploy.pem
   ```
3. Add the following GitHub repository secrets:
- `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` from step 1.
- `EC2_KEY_PAIR_NAME` → `tri-stack-deploy` (or your chosen key-pair name).
- `EC2_SSH_KEY` → entire contents of `tri-stack-deploy.pem`.
- The workflow currently associates the Elastic IP `eipalloc-0c3424a1ac1587995`, and after association it publishes both the IP and the AWS DNS hostname (for example `ec2-18-169-114-79.eu-west-2.compute.amazonaws.com`). Replace the Allocation ID in `.github/workflows/deploy-aws.yml` if you allocate a different address.

### Running the Workflow

- Trigger the pipeline manually (`workflow_dispatch`) or by pushing to `main`.
- The job will:
  1. Ensure a security group with open ports `22`, `8080`, `30080-30082`, `31080-31082` exists.
  2. Terminate any previously tagged instance and launch a new `t3.medium` Ubuntu host.
  3. Install Docker/k3s/Helm via `tools/setup-ubuntu-host.sh`.
  4. Copy the repo and execute `./tools/tri-stack.sh` (all stacks).
  5. Print public URLs: `http://<public-ip>:8080`, `:30080`, and `:31080`.

Use the same secrets to tear the stack down by re-running the workflow; it always replaces the existing instance.

### Host Bootstrap Script

`tools/setup-ubuntu-host.sh` is invoked remotely by the workflow to install Docker, k3s, Helm, and related packages on a fresh Ubuntu host. You can reuse it manually with:

```bash
scp tools/setup-ubuntu-host.sh ubuntu@<host>:/tmp/setup.sh
ssh ubuntu@<host> "sudo REMOTE_USER=ubuntu bash /tmp/setup.sh"
```

`tri-stack.sh` copies `services/ui-static/index.html` into `infra/helm/files/index.html` and `infra/k8s/ui-index/index.html` each run, so the UI only needs to be edited in one place while keeping the deployment manifests satisfied. The copies are `.gitignore`d and regenerated automatically.

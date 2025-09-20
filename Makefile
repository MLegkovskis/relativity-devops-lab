.PHONY: help compose-up compose-down compose-logs compose-smoke images-build images-push k8s-apply k8s-pods k8s-logs-ray k8s-logs-bh k8s-restart-ui k8s-delete

# Quick reference for running and debugging the stack in Docker Compose and k3s.
help:
	@echo "Targets:"
	@echo "  compose-up        Build and start the local Compose stack"
	@echo "  compose-down      Stop the Compose stack"
	@echo "  compose-logs      Tail Compose logs for all services"
	@echo "  compose-smoke     Hit the FastAPI endpoints exposed via Compose"
	@echo "  images-build      Build all images with the marilee/blackhole-k8s tags"
	@echo "  images-push       Push tagged images to Docker Hub"
	@echo "  k8s-apply         Apply the kustomize base to k3s"
	@echo "  k8s-pods          List workloads in the blackhole namespace"
	@echo "  k8s-logs-ray      Follow ray-api logs (updates when Fire is pressed)"
	@echo "  k8s-logs-bh       Follow blackhole-api logs"
	@echo "  k8s-restart-ui    Roll the UI deployment to pick up a fresh image"
	@echo "  k8s-delete        Tear down everything created by this project"

# --- Docker Compose workflow -------------------------------------------------
compose-up:
	docker compose -f infra/docker-compose.yml up --build

compose-down:
	docker compose -f infra/docker-compose.yml down

compose-logs:
	docker compose -f infra/docker-compose.yml logs -f

compose-smoke:
	curl -X POST localhost:8001/derived -H 'content-type: application/json' -d '{"mass": 8.54e36}'
	curl -X POST localhost:8000/integrate -H 'content-type: application/json' -d '{"mass": 8.54e36,"x":-1e11,"y":3.2760630272e10,"vx":299792458.0,"vy":0.0,"steps":1000,"dlam":1.0}'

# --- Image build & publish ---------------------------------------------------
images-build:
	docker build -t marilee/blackhole-k8s:ui-dev -f services/ui-static/Dockerfile .
	docker build -t marilee/blackhole-k8s:ray-api-dev -f services/ray-api/Dockerfile .
	docker build -t marilee/blackhole-k8s:blackhole-api-dev -f services/blackhole-api/Dockerfile .
	docker build -t marilee/blackhole-k8s:worker-dev -f services/worker/Dockerfile .

images-push:
	docker push marilee/blackhole-k8s:ui-dev
	docker push marilee/blackhole-k8s:ray-api-dev
	docker push marilee/blackhole-k8s:blackhole-api-dev
	docker push marilee/blackhole-k8s:worker-dev

# --- Kubernetes workflow -----------------------------------------------------
k8s-apply:
	kubectl apply -k infra/k8s

k8s-pods:
	kubectl get pods -n blackhole

k8s-logs-ray:
	kubectl logs -n blackhole -l app.kubernetes.io/name=ray-api --tail=0 -f

k8s-logs-bh:
	kubectl logs -n blackhole -l app.kubernetes.io/name=blackhole-api --tail=0 -f

k8s-restart-ui:
	kubectl rollout restart deploy/ui -n blackhole

k8s-delete:
	kubectl delete -k infra/k8s

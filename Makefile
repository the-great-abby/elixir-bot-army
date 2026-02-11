# Internal Docker registry (override if different)
REGISTRY ?= 127.0.0.1:32000
# Image name for Docker build and Kubernetes deploy
IMAGE ?= $(REGISTRY)/bot-army:latest
# Kubernetes namespace for Rancher/K8s deploy
K8S_NAMESPACE ?= bot-army
K8S_DIR = deploy/kubernetes

.PHONY: help deps get nats start-nats run start iex test format compile clean reset-nats check
.PHONY: docker-build docker-push docker-run docker-show-base-image k8s-deploy k8s-deploy-nats k8s-deploy-app k8s-destroy

# Default target: show help
help:
	@echo "BotArmy – available commands:"
	@echo ""
	@echo "  make deps         Get Mix dependencies"
	@echo "  make nats         Start NATS server (Docker)"
	@echo "  make run          Start app in IEx (iex -S mix)"
	@echo "  make test         Run tests"
	@echo "  make format       Format code"
	@echo "  make compile      Compile the project"
	@echo "  make clean        Clean build artifacts"
	@echo "  make reset-nats   Stop and remove NATS container"
	@echo "  make check        Compile, check format, run tests (CI)"
	@echo ""
	@echo "Docker (single-host):"
	@echo "  make docker-build           Build container image (IMAGE=$(IMAGE))"
	@echo "  make docker-show-base-image Show current/pinned Elixir base image for Dockerfile"
	@echo "  make docker-push             Push image to registry $(REGISTRY)"
	@echo "  make docker-run             Run container (requires NATS; use make nats)"
	@echo ""
	@echo "Kubernetes / Rancher:"
	@echo "  make k8s-deploy      Deploy namespace + NATS + BotArmy (IMAGE=$(IMAGE))"
	@echo "  make k8s-deploy-nats Deploy only NATS into $(K8S_NAMESPACE)"
	@echo "  make k8s-deploy-app  Deploy only BotArmy (namespace + configmap + deployment)"
	@echo "  make k8s-destroy     Delete namespace $(K8S_NAMESPACE) and all resources"
	@echo ""

# Dependencies
deps get:
	mix deps.get

# NATS
nats start-nats:
	./start_nats.sh

# Run app
run start iex:
	iex -S mix

# Test & format
test:
	mix test

format:
	mix format

compile:
	mix compile

clean:
	mix clean

# Stop and remove NATS container (from QUICKSTART)
reset-nats:
	docker stop nats-dev 2>/dev/null || true
	docker rm nats-dev 2>/dev/null || true
	@echo "NATS container removed. Run 'make nats' to start again."

# CI-style check: compile, verify format, test
check:
	mix compile --warnings-as-errors
	mix format --check-formatted
	mix test

# --- Docker (single-host) ---
# Elixir base image: auto from script when building, or set ELIXIR_BASE=tag to override

docker-show-base-image:
	@echo "Elixir base image tag: $$(sh script/latest_elixir_base_tag.sh)"
	@echo "  (from script/latest_elixir_base_tag.sh; override with make docker-build ELIXIR_BASE=tag)"

docker-build:
	@BASE=$$(sh script/latest_elixir_base_tag.sh); \
	docker build --build-arg ELIXIR_BASE=$${ELIXIR_BASE:-$$BASE} -t $(IMAGE) .

docker-push: docker-build
	docker push $(IMAGE)

docker-run:
	docker run --rm -it \
		-e NATS_HOST=$${NATS_HOST:-host.docker.internal} \
		-e NATS_PORT=$${NATS_PORT:-4222} \
		$(IMAGE)

# --- Kubernetes / Rancher ---
k8s-deploy: k8s-deploy-nats k8s-deploy-app

k8s-deploy-nats:
	kubectl apply -f $(K8S_DIR)/namespace.yaml
	kubectl apply -f $(K8S_DIR)/nats.yaml

k8s-deploy-app:
	kubectl apply -f $(K8S_DIR)/namespace.yaml
	kubectl apply -f $(K8S_DIR)/bot-army-configmap.yaml
	@if [ -n "$(IMAGE)" ]; then \
		sed 's|image: .*|image: $(IMAGE)|' $(K8S_DIR)/bot-army-deployment.yaml | kubectl apply -f -; \
	else \
		kubectl apply -f $(K8S_DIR)/bot-army-deployment.yaml; \
	fi

k8s-destroy:
	kubectl delete namespace $(K8S_NAMESPACE) --ignore-not-found

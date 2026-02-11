# Deploy BotArmy

Default Docker registry: **127.0.0.1:32000** (override with `REGISTRY=...` or `IMAGE=...` when running make).

Two deployment targets:

- **Docker** – single host, `docker run` (or Compose).
- **Kubernetes (Rancher)** – deploy to any Kubernetes cluster (e.g. Rancher).

## Docker

Build and run locally or on a single host:

```bash
# Build image
make docker-build

# Run NATS (if not already running)
make nats

# Run BotArmy (connects to NATS at host.docker.internal or localhost)
make docker-run
```

Push to the internal registry (default `127.0.0.1:32000/bot-army:latest`):

```bash
make docker-push
```

To use a different registry: `make docker-push REGISTRY=myreg.io` or `make docker-build IMAGE=myreg.io/myorg/bot-army:0.1.0 && docker push ...`.

## Kubernetes (Rancher)

Deploy to a Kubernetes cluster (Rancher-managed or any kube cluster).

### Prerequisites

- `kubectl` configured for your cluster.
- Optional: `docker` (or another builder) to build the image; cluster must be able to pull the image.

### 1. Build and push the image

Build and push to the internal registry (default `127.0.0.1:32000/bot-army:latest`):

```bash
make docker-push
```

Or set a different image: `make docker-push IMAGE=myreg.io/myorg/bot-army:0.1.0`

### 2. Deploy to Kubernetes

Create namespace and apply manifests (NATS + BotArmy). Image defaults to `127.0.0.1:32000/bot-army:latest`:

```bash
make k8s-deploy
```

Use a different image: `make k8s-deploy IMAGE=myreg.io/myorg/bot-army:0.1.0`

This applies, in order:

1. `deploy/kubernetes/namespace.yaml`
2. `deploy/kubernetes/nats.yaml` (in-cluster NATS)
3. `deploy/kubernetes/bot-army-configmap.yaml`
4. `deploy/kubernetes/bot-army-deployment.yaml` (with `IMAGE` if set)

### 3. Use existing NATS instead

If NATS is already in the cluster or external, skip the in-cluster NATS and point BotArmy at it:

1. Do **not** apply `deploy/kubernetes/nats.yaml` (or remove it from the Makefile apply list).
2. Set `NATS_HOST` (and optionally `NATS_PORT`) in the BotArmy ConfigMap to your NATS service or external host.

Example for NATS in another namespace:

- In `deploy/kubernetes/bot-army-configmap.yaml`, set  
  `NATS_HOST: "nats.nats-system.svc.cluster.local"`  
  (adjust namespace and service name to match your NATS).

### Useful commands

```bash
# Deploy/update only BotArmy (no NATS, no namespace)
make k8s-deploy-app

# Deploy only NATS
make k8s-deploy-nats

# Delete everything in namespace bot-army
make k8s-destroy
```

## Image name

- **Docker target:** `make docker-build` and `make docker-run` use `IMAGE` if set; default `bot-army:latest`.
- **Kubernetes target:** `make k8s-deploy` and `make k8s-deploy-app` use `IMAGE` if set; otherwise the manifests use `bot-army:latest` (so you must build and tag locally or set `IMAGE` when applying).

Always set `IMAGE` when pushing to a registry and deploying to Kubernetes.

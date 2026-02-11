# Kubernetes cheatsheet for BotArmy

**For:** You know *what* Kubernetes is (containers, orchestration) but not the exact commands.  
**Goal:** Run the right `kubectl` commands and know what each YAML file is for.

---

## One-page command reference

### Deploy / tear down (use the Makefile)

```bash
make k8s-deploy          # Deploy namespace + NATS + BotArmy (set IMAGE=... if needed)
make k8s-deploy-app      # Deploy only BotArmy (NATS already there)
make k8s-deploy-nats     # Deploy only namespace + NATS
make k8s-destroy         # Delete namespace bot-army and everything in it
```

### Inspect (kubectl)

| What | Command |
|------|--------|
| List pods in our namespace | `kubectl get pods -n bot-army` |
| List all resources in namespace | `kubectl get all -n bot-army` |
| App logs (follow) | `kubectl logs -f deployment/bot-army -n bot-army` |
| NATS logs (follow) | `kubectl logs -f deployment/nats -n bot-army` |
| Describe a pod (events, state) | `kubectl describe pod -n bot-army -l app=bot-army` |
| Execute a shell in app pod | `kubectl exec -it deployment/bot-army -n bot-army -- /bin/sh` |

**💡 Why `-n bot-army`?** Our resources live in the `bot-army` namespace. If you omit `-n`, kubectl uses `default`.

---

## What each Kubernetes resource does (and why we have it)

### Namespace (`namespace.yaml`)

- **What:** A namespace is like a folder for resources. All our stuff lives in `bot-army`.
- **Why:** So we can `kubectl delete namespace bot-army` and remove the whole project. Also keeps our resources separate from other apps.

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: bot-army
```

---

### Deployment (`nats.yaml` and `bot-army-deployment.yaml`)

- **What:** “Run this container image and keep N copies running.” If a pod dies, Kubernetes starts another.
- **Why:** We want one NATS server and one BotArmy app running. Deployment is the standard way to run stateless (or single-instance) workloads.

**Key parts of a Deployment:**

- **replicas: 1** – Run one pod.
- **containers[].image** – Which image to run.
- **containers[].env / envFrom** – Environment variables (we use ConfigMap).
- **resources** – requests/limits for CPU and memory (scheduler and limits).

---

### Service (`nats.yaml` – second resource)

- **What:** Gives a stable DNS name and port for pods (e.g. `nats:4222`). Traffic to the Service is sent to one of the matching pods.
- **Why:** BotArmy needs to connect to NATS. Pod IPs change when pods restart. The Service name `nats` stays the same, so we set `NATS_HOST=nats`.

```yaml
# Result: inside the cluster you can reach NATS at "nats" on port 4222
spec:
  ports:
    - port: 4222
      targetPort: 4222
  selector:
    app: nats   # Routes to pods with label app=nats
```

---

### ConfigMap (`bot-army-configmap.yaml`)

- **What:** Key-value config (non-secret). We put `NATS_HOST` and `NATS_PORT` here.
- **Why:** So the same Docker image can run against different NATS (local vs cluster) by changing config, not the image. For secrets (e.g. API keys), use a **Secret** instead.

**How the app gets it:** In the Deployment we have `envFrom: configMapRef: name: bot-army`, so every key in the ConfigMap becomes an environment variable in the container.

---

## Picture: how it fits together

```
  kubectl apply -f namespace.yaml
  kubectl apply -f nats.yaml
  kubectl apply -f bot-army-configmap.yaml
  kubectl apply -f bot-army-deployment.yaml

  ┌─────────────────────────────────────────────────────────────┐
  │  Namespace: bot-army                                        │
  │                                                              │
  │  ConfigMap: bot-army                                         │
  │    NATS_HOST=nats, NATS_PORT=4222                            │
  │                                                              │
  │  Deployment: nats          Service: nats (ClusterIP :4222)   │
  │    └─ Pod (nats container)     ↑                             │
  │                                 │                            │
  │  Deployment: bot-army          │                             │
  │    └─ Pod (bot-army container) │                             │
  │         env from ConfigMap ────┘                             │
  │         → NATS_HOST=nats → connects to Service "nats"        │
  └─────────────────────────────────────────────────────────────┘
```

---

## Common issues

| Problem | What to try |
|--------|--------------|
| Pods not starting | `kubectl get pods -n bot-army` and `kubectl describe pod <name> -n bot-army` (look at Events). |
| Image pull errors | Image must be pullable from the cluster (e.g. push to a registry and set `IMAGE=registry/bot-army:tag`). |
| App can’t reach NATS | Check ConfigMap has `NATS_HOST=nats` and NATS Service/pod are in same namespace: `kubectl get svc,pods -n bot-army`. |
| “Namespace doesn’t exist” | Run `make k8s-deploy` or `kubectl apply -f deploy/kubernetes/namespace.yaml` first. |

---

## Job interview takeaway

- **Namespace** = scope for resources; easy cleanup.
- **Deployment** = “keep N copies of this container running.”
- **Service** = stable network name for pods (DNS + load balancing).
- **ConfigMap** = non-secret config; **Secret** = for passwords/keys.
- **kubectl get/describe/logs** = your main debugging tools.

You don’t need to memorize YAML; you need to know what each resource is for and how to run and inspect the app. This project gives you one concrete example of each.

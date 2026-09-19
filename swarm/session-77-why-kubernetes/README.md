# Session 77 — Why Learn Kubernetes After Docker?

Chapter 12: Docker Swarm and Introduction to Kubernetes

This lesson is the transition from Docker/Swarm concepts to Kubernetes thinking. The goal is to understand why container orchestration becomes necessary when workloads grow across multiple hosts.

## Learning objectives

By the end of this session, you should be able to explain:

- why Docker alone is not enough for large multi-node production environments
- what container orchestration means
- the difference between Docker Compose, Docker Swarm, and Kubernetes
- desired state and reconciliation
- self-healing
- why Kubernetes uses Pods instead of exposing containers as the primary deployment unit
- the relationship between Docker images, registries, container runtimes, and Kubernetes
- the purpose of readiness and liveness probes
- how Docker/Swarm knowledge maps to Kubernetes concepts

## Lab environment

| Host | Address | Role |
|---|---|---|
| `DEV-1` | `192.0.2.10` | Swarm manager, image build/push client |
| `DEV-2` | `192.0.2.11` | Swarm worker |
| Registry | `192.0.2.10:8085` | Nexus Docker registry |

> The addresses above are documentation-only example addresses. Replace them with the addresses assigned to your own lab.

The lab publishes the demo service on port `8181` to avoid common conflicts with monitoring and registry services.

## Core idea: desired state

Instead of manually managing individual containers, an orchestrator lets you declare a desired state.

Example:

```text
Desired replicas = 2
Actual replicas  = 1
```

The orchestrator detects the difference and creates a replacement task or workload until the actual state matches the desired state.

## Docker vs orchestration

A standalone Docker Engine can restart a failed container on the same host using a restart policy, but it cannot recover a workload if the entire host disappears.

An orchestrator adds cluster-level behavior such as:

- scheduling
- replica management
- service discovery
- load balancing
- rolling updates
- failure recovery
- node maintenance handling

## Docker Compose vs Docker Swarm vs Kubernetes

### Docker Compose

Useful for defining and running a multi-container application, usually on a single Docker host.

### Docker Swarm

Adds cluster orchestration to Docker Engine and introduces:

- manager and worker nodes
- services
- replicas
- desired state
- overlay networking
- routing mesh
- rolling updates
- rollback

### Kubernetes

Extends orchestration with a much broader platform and ecosystem for:

- scheduling
- self-healing
- services and discovery
- configuration and secrets
- persistent storage
- resource requests and limits
- namespaces
- RBAC
- autoscaling
- stateful workloads
- daemon workloads
- jobs
- network policies
- operators and extensibility

## Important runtime concept

Kubernetes does not require Docker Engine as its container runtime.

Modern Kubernetes communicates with container runtimes through the Container Runtime Interface (CRI). Common runtimes include:

- `containerd`
- `CRI-O`

Docker images are still valid container images. A typical flow can be:

```text
Developer
   |
   v
Docker build
   |
   v
Container image
   |
   v
Registry
   |
   v
Kubernetes
   |
   v
containerd
   |
   v
Container
```

## Concept mapping

| Docker / Swarm concept | Kubernetes concept |
|---|---|
| Container | Pod |
| Swarm service | Deployment |
| Replica count | Deployment replicas |
| Healthcheck | Liveness / Readiness / Startup Probe |
| Environment variables | ConfigMap / Secret |
| Volume | Volume / PV / PVC / StorageClass |
| Docker network | Pod network / CNI |
| Published service | Service / Ingress |
| Swarm desired state | Controllers and reconciliation |

## Swarm lab

### 1. Verify Docker on DEV-1

```bash
hostname
docker version
docker info --format 'Swarm={{.Swarm.LocalNodeState}} NodeID={{.Swarm.NodeID}}'
```

### 2. Verify Docker on DEV-2

```bash
hostname
docker version
docker info --format 'Swarm={{.Swarm.LocalNodeState}} NodeID={{.Swarm.NodeID}}'
```

### 3. Check nodes from the manager

Run on `DEV-1`:

```bash
docker node ls
```

### 4. Initialize Swarm only if needed

Run on `DEV-1` only when the host is not already part of a Swarm:

```bash
docker swarm init --advertise-addr 192.0.2.10
```

Then get the worker join command:

```bash
docker swarm join-token worker
```

Run the generated join command on `DEV-2`.

### 5. Verify Swarm ports

Important ports:

- `2377/TCP` — manager control plane
- `7946/TCP` — node communication
- `7946/UDP` — node communication
- `4789/UDP` — overlay networking

Check listeners:

```bash
ss -lntup | grep -E ':(2377|7946|4789)\b' || true
```

### 6. Prepare and push the demo image

Run on `DEV-1`:

```bash
docker pull nginx:alpine
docker tag nginx:alpine 192.0.2.10:8085/lesson77-nginx:v1
docker login 192.0.2.10:8085
docker push 192.0.2.10:8085/lesson77-nginx:v1
```

### 7. Create the Swarm service

Run on `DEV-1`:

```bash
docker service create \
  --name lesson77-web \
  --replicas 2 \
  --publish published=8181,target=80 \
  --restart-condition any \
  --update-parallelism 1 \
  --update-delay 5s \
  --with-registry-auth \
  192.0.2.10:8085/lesson77-nginx:v1
```

Verify:

```bash
docker service ls
docker service ps lesson77-web
```

### 8. Test routing mesh

```bash
curl http://192.0.2.10:8181
curl http://192.0.2.11:8181
```

### 9. Simulate task failure

On the node currently running a `lesson77-web` task:

```bash
docker ps --filter label=com.docker.swarm.service.name=lesson77-web
```

Remove one task container:

```bash
docker rm -f $(docker ps -q --filter label=com.docker.swarm.service.name=lesson77-web | head -n 1)
```

Then verify from `DEV-1`:

```bash
docker service ps lesson77-web
```

The service should create a replacement task to restore the desired replica count.

### 10. Simulate node maintenance

Find the exact node name:

```bash
docker node ls
```

Drain the worker:

```bash
docker node update --availability drain DEV-2
```

Verify placement:

```bash
docker service ps lesson77-web
```

Return the node to active state:

```bash
docker node update --availability active DEV-2
```

### 11. Scale the service

Scale out:

```bash
docker service scale lesson77-web=4
docker service ps lesson77-web
```

Scale back:

```bash
docker service scale lesson77-web=2
```

## Kubernetes preview

The file `kubernetes-preview.yaml` contains a small Deployment and Service example showing how the same ideas appear in Kubernetes:

- image
- replicas
- container port
- readiness probe
- liveness probe
- CPU and memory requests/limits
- stable Service abstraction

This manifest is included for study and is not required to complete the Swarm lab.

## Readiness vs liveness

### Liveness

Answers: "Is this application still healthy enough to keep running?"

A failed liveness probe can cause the container to be restarted.

### Readiness

Answers: "Is this application ready to receive traffic right now?"

A Pod can be running but not ready. In that case it can be excluded from Service endpoints until it becomes ready.

## Interview questions

### Why learn Kubernetes after Docker?

Docker provides container build and runtime workflows. Kubernetes manages containerized workloads across a cluster and adds scheduling, self-healing, service discovery, scaling, configuration, storage, rollout, and policy capabilities.

### What is desired state?

Desired state is the state declared by the operator, such as three replicas of an application. Controllers continuously compare actual state with desired state and reconcile differences.

### What is self-healing?

Self-healing is the ability of the orchestration platform to detect failed workloads and restore the declared desired state by restarting or replacing them.

### What is the smallest deployable unit in Kubernetes?

A Pod.

### Can a Pod contain more than one container?

Yes. A Pod may contain one or more tightly coupled containers that share networking and other Pod-level resources.

### Does Kubernetes require Docker Engine?

No. Kubernetes works with CRI-compatible runtimes such as containerd and CRI-O. Docker Engine is not the default Kubernetes runtime interface.

### Why not always use Kubernetes?

Kubernetes adds capability but also complexity. Smaller systems may be better served by Docker Compose or another simpler deployment model when advanced cluster orchestration is not required.

## Cleanup

Remove the demo service when the lab is finished:

```bash
docker service rm lesson77-web
```

> This removes the Swarm service and its tasks. It does not remove your Nexus image.

## Files

- `README.md` — lesson notes and runnable lab
- `CHEATSHEET.md` — command and concept quick reference
- `kubernetes-preview.yaml` — study-only Kubernetes Deployment and Service example

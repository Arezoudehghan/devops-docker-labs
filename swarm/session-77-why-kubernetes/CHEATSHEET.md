# Session 77 Cheat Sheet — Docker to Kubernetes Mindset

## Core concepts

- **Containerization:** package and run applications in containers.
- **Orchestration:** manage many workloads across multiple nodes.
- **Desired state:** the declared target state of the system.
- **Actual state:** what is currently running.
- **Reconciliation:** continuously move actual state toward desired state.
- **Self-healing:** replace or restart failed workloads automatically.
- **Scheduling:** choose an appropriate node for a workload.
- **Service discovery:** provide stable discovery for changing workload instances.

## Docker / Swarm to Kubernetes mapping

- Container → Pod
- Swarm service → Deployment
- Replica count → Deployment replicas
- Healthcheck → Liveness / Readiness / Startup Probe
- Environment variables → ConfigMap / Secret
- Volume → Volume / PV / PVC / StorageClass
- Docker network → Pod network / CNI
- Published service → Service / Ingress
- Swarm reconciliation → Kubernetes controllers

## Swarm status

```bash
docker info --format 'Swarm={{.Swarm.LocalNodeState}} NodeID={{.Swarm.NodeID}}'
```

Purpose: show whether the local Docker Engine is in Swarm mode and display its node ID.

```bash
docker node ls
```

Purpose: list Swarm nodes. Run from a manager.

## Initialize Swarm

```bash
docker swarm init --advertise-addr 192.0.2.10
```

Purpose: initialize a new Swarm and advertise the manager address.

```bash
docker swarm join-token worker
```

Purpose: print the worker join command and token.

## Swarm ports

```bash
ss -lntup | grep -E ':(2377|7946|4789)\b' || true
```

Important ports:

- `2377/TCP` — manager control
- `7946/TCP` and `7946/UDP` — node communication
- `4789/UDP` — overlay networking

## Registry workflow

```bash
docker pull nginx:alpine
```

```bash
docker tag nginx:alpine 192.0.2.10:8085/lesson77-nginx:v1
```

```bash
docker login 192.0.2.10:8085
```

```bash
docker push 192.0.2.10:8085/lesson77-nginx:v1
```

## Create the service

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

Key options:

- `--replicas 2` — desired task count.
- `--publish published=8181,target=80` — publish Swarm port 8181 to container port 80.
- `--restart-condition any` — restart replacement behavior for exited tasks.
- `--update-parallelism 1` — update one task at a time.
- `--update-delay 5s` — wait five seconds between task updates.
- `--with-registry-auth` — pass current registry credentials to Swarm agents for image pulls.

## Inspect the service

```bash
docker service ls
```

```bash
docker service ps lesson77-web
```

## Routing mesh test

```bash
curl http://192.0.2.10:8181
curl http://192.0.2.11:8181
```

## Find service containers

```bash
docker ps --filter label=com.docker.swarm.service.name=lesson77-web
```

## Simulate task failure

```bash
docker rm -f $(docker ps -q --filter label=com.docker.swarm.service.name=lesson77-web | head -n 1)
```

Explanation:

1. `docker ps -q --filter ...` returns matching container IDs.
2. `head -n 1` selects one ID.
3. `$(...)` substitutes that ID into the outer command.
4. `docker rm -f` force-removes that task container.
5. Swarm should create a replacement because the desired replica count did not change.

## Node maintenance

```bash
docker node update --availability drain DEV-2
```

Purpose: prevent new tasks from running on the node and move Swarm service tasks away where possible.

```bash
docker node update --availability active DEV-2
```

Purpose: make the node eligible for scheduling again.

## Scale

```bash
docker service scale lesson77-web=4
```

```bash
docker service scale lesson77-web=2
```

## Cleanup

```bash
docker service rm lesson77-web
```

Warning: this removes the Swarm service and its running tasks.

## Kubernetes interview reminders

- Smallest deployable Kubernetes unit: **Pod**
- Common stateless controller: **Deployment**
- Stable network abstraction: **Service**
- Container runtime interface: **CRI**
- Common runtimes: **containerd**, **CRI-O**
- Health signals: **startup**, **readiness**, **liveness**
- Configuration: **ConfigMap**
- Sensitive configuration: **Secret**
- Persistent storage concepts: **PV**, **PVC**, **StorageClass**
- Cluster networking implementation: **CNI**

## One-sentence interview answer

Docker teaches you how to build and run containers; Kubernetes teaches you how to declare, schedule, expose, scale, and recover containerized workloads across a cluster.

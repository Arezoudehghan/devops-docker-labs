# Session 74 — Docker Swarm Service, Replica, and Overlay Network

Practical DevOps lab for learning Docker Swarm services, replicas, tasks, overlay networking, service discovery, routing mesh, scaling, health checks, and self-healing.

## Lab architecture

- **DEV-1** — `192.168.94.90`
  - Docker Swarm Manager
- **DEV-2** — `192.168.94.91`
  - Docker Swarm Worker

## Learning goals

By the end of this lab you should be able to explain and demonstrate:

- The difference between a container, task, replica, and service.
- How Swarm maintains a desired replica count.
- How overlay networks connect services across multiple Docker hosts.
- How Swarm DNS-based service discovery works.
- How the ingress routing mesh exposes a published service port on every node.
- How to scale a service up and down.
- How Swarm replaces a failed task to restore the desired state.

## Important note

This session intentionally does **not** use a Dockerfile, Compose file, or Swarm stack file. The goal is to work directly with Docker Swarm service commands.

## 1. Verify Docker and Swarm state

Run on **DEV-1**:

```bash
hostname
ip -br a
docker version
docker info --format 'Swarm={{.Swarm.LocalNodeState}} ControlAvailable={{.Swarm.ControlAvailable}} NodeID={{.Swarm.NodeID}}'
```

Run on **DEV-2**:

```bash
hostname
ip -br a
docker version
docker info --format 'Swarm={{.Swarm.LocalNodeState}} ControlAvailable={{.Swarm.ControlAvailable}} NodeID={{.Swarm.NodeID}}'
```

On the manager, verify the cluster:

```bash
docker node ls
```

If the swarm is already active, do not initialize it again.

## 2. Initialize the swarm only if required

Run on **DEV-1** only when Swarm is not already initialized:

```bash
docker swarm init --advertise-addr 192.168.94.90
```

Display the worker join command:

```bash
docker swarm join-token worker
```

Run the generated `docker swarm join ...` command on **DEV-2**, then verify again on **DEV-1**:

```bash
docker node ls
```

## 3. Swarm ports

The nodes must be able to communicate over the Swarm ports:

- `2377/TCP` — cluster management.
- `7946/TCP` and `7946/UDP` — node communication and discovery.
- `4789/UDP` — overlay network data path.

Check the firewall status on both nodes:

```bash
sudo ufw status
```

## 4. Pull the lab images

Run on **DEV-1**:

```bash
docker pull nginx:1.30.4-alpine
docker pull alpine:3.24.1
```

Run on **DEV-2**:

```bash
docker pull nginx:1.30.4-alpine
docker pull alpine:3.24.1
```

## 5. Create the overlay network

Run on **DEV-1**:

```bash
docker network create \
  --driver overlay \
  --attachable \
  swarm-app-net
```

Verify it:

```bash
docker network ls
docker network inspect swarm-app-net
```

The `--attachable` option allows standalone troubleshooting containers to connect to the overlay network.

## 6. Create the replicated service

Run on **DEV-1**:

```bash
docker service create \
  --name web-demo \
  --replicas 3 \
  --network swarm-app-net \
  --publish published=8088,target=80,protocol=tcp,mode=ingress \
  --health-cmd 'wget -q -O /dev/null http://127.0.0.1/ || exit 1' \
  --health-interval 10s \
  --health-timeout 3s \
  --health-retries 3 \
  --health-start-period 5s \
  nginx:1.30.4-alpine
```

The desired state is now three service tasks.

## 7. Verify service and task placement

Run on **DEV-1**:

```bash
docker service ls
docker service ps web-demo
```

A healthy service should converge to:

```text
3/3
```

Inspect local service containers on **DEV-1** and **DEV-2**:

```bash
docker ps \
  --filter label=com.docker.swarm.service.name=web-demo
```

Remember:

- `docker ps` shows containers on the local Docker host.
- `docker service ps web-demo` shows service tasks across the Swarm cluster.

## 8. Test the routing mesh

Test the published port through the manager:

```bash
curl -I http://192.168.94.90:8088
```

Test the same service through the worker:

```bash
curl -I http://192.168.94.91:8088
```

Both nodes should accept traffic on the published port because the service uses ingress mode.

## 9. Inspect the service and VIP

Run on **DEV-1**:

```bash
docker service inspect web-demo --pretty
```

Inspect the service virtual IP information:

```bash
docker service inspect web-demo \
  --format '{{json .Endpoint.VirtualIPs}}'
```

## 10. Test overlay DNS and service discovery

Because the overlay network is attachable, run this troubleshooting container on **DEV-2**:

```bash
docker run --rm \
  --network swarm-app-net \
  alpine:3.24.1 \
  nslookup web-demo
```

Test HTTP access by service name:

```bash
docker run --rm \
  --network swarm-app-net \
  alpine:3.24.1 \
  wget -qO- http://web-demo
```

No container IP is required. The service is reached by its Swarm service name.

## 11. Scale the service

Scale up to five replicas:

```bash
docker service scale web-demo=5
docker service ls
docker service ps web-demo
```

Scale down to two replicas:

```bash
docker service scale web-demo=2
docker service ls
docker service ps web-demo
```

Return to three replicas before the self-healing test:

```bash
docker service scale web-demo=3
docker service ls
```

## 12. Self-healing test

On **DEV-2**, locate the service containers:

```bash
docker ps \
  --filter label=com.docker.swarm.service.name=web-demo \
  --format '{{.ID}}  {{.Names}}  {{.Status}}'
```

Kill one local task container:

```bash
docker kill $(docker ps \
  --filter label=com.docker.swarm.service.name=web-demo \
  -q | head -n 1)
```

Then watch the manager restore the desired state:

```bash
docker service ps web-demo
docker service ls
```

The failed task remains visible in service history, while Swarm creates a replacement task so the service returns to `3/3`.

## 13. Inspect overlay networks

Run on both nodes:

```bash
docker network ls --filter driver=overlay
```

The custom `swarm-app-net` network carries service-to-service traffic. Swarm also maintains its own `ingress` network for published-port routing.

## Practice challenge

Build the same scenario again with:

- Overlay network: `production-net`
- Service: `frontend`
- Replicas: `4`
- Published port: `8888`
- Target port: `80`
- Health check enabled

Then:

1. Test port `8888` through both Swarm nodes.
2. Reach the service by the name `frontend` from an attached troubleshooting container.
3. Scale from four to six replicas.
4. Kill one task container.
5. Verify that Swarm restores the desired state to six replicas.

## Cleanup

Remove the service first:

```bash
docker service rm web-demo
```

Then remove the lab overlay network:

```bash
docker network rm swarm-app-net
```

Verify cleanup:

```bash
docker service ls
docker network ls
```

Do not leave the Swarm cluster after this session because later Swarm labs reuse the same manager and worker.

## Interview review

Key ideas to be able to explain:

- A **service** defines the desired state for an application in Swarm.
- A **replica** represents one desired service task instance.
- A **task** is a scheduling unit that normally runs one container.
- An **overlay network** provides multi-host networking across Swarm nodes.
- **Service discovery** lets services reach each other by service name.
- **Routing mesh** makes an ingress-published service port reachable through every Swarm node.
- **Horizontal scaling** changes the number of replicas.
- **Self-healing** replaces failed tasks so the actual state converges back to the desired state.

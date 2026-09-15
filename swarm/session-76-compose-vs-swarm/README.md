# Session 76 — Docker Compose vs Docker Swarm

This lab compares a single-host Docker Compose deployment with a clustered Docker Swarm deployment using the same lightweight Nginx workload.

## Learning goals

By the end of this lab you should be able to explain and demonstrate:

- Docker Compose as a multi-container application tool on a single Docker Engine.
- Docker Swarm as a cluster orchestrator across multiple Docker Engines.
- The difference between a Compose service and a Swarm service/task model.
- Desired state and reconciliation in Swarm.
- Replicas, scheduling, overlay networking, ingress routing mesh, scaling, and node drain.
- Why `docker compose up` does not deploy an application across a Swarm cluster.

## Lab layout

```text
session-76-compose-vs-swarm/
├── README.md
├── compose/
│   └── compose.yaml
└── swarm/
    └── stack.yaml
```

## Example lab environment

| Host | Example address | Role |
|---|---|---|
| `DEV-1` | `192.0.2.10` | Swarm manager |
| `DEV-2` | `192.0.2.11` | Swarm worker |

The addresses above are documentation-only example addresses. Replace them with the actual addresses assigned to your own lab VMs.

## Prerequisites

Run on both hosts:

```bash
docker --version
docker compose version
docker info --format 'Swarm={{.Swarm.LocalNodeState}}'
hostname
ip -br addr
```

Pull the lab image if needed:

```bash
docker pull nginx:alpine
```

Swarm nodes must be able to communicate on these ports:

- `2377/tcp` — cluster management traffic.
- `7946/tcp` and `7946/udp` — node communication.
- `4789/udp` — overlay network traffic.

## Part 1 — Docker Compose on one host

Run this part on `DEV-2`.

```bash
cd swarm/session-76-compose-vs-swarm/compose
docker compose config --quiet
docker compose up -d
docker compose ps
curl http://127.0.0.1:8088
```

Expected behavior:

- The workload runs only on the Docker Engine where `docker compose up` was executed.
- The returned page contains the container hostname.
- `DEV-1` does not automatically receive a Compose container.

Inspect the container health state:

```bash
docker inspect --format '{{json .State.Health}}' session76-compose-web-1
```

### Compose scaling note

This lab publishes fixed host port `8088`. Multiple Compose replicas on the same host cannot all bind the same fixed host port. That is intentional: it highlights that local Compose scaling and cluster-level Swarm service publishing are different problems.

Stop the Compose workload before deploying the Swarm stack so port `8088` is free:

```bash
docker compose down
```

## Part 2 — Build the Swarm cluster

If `DEV-1` is not already a Swarm manager, initialize it using its real management address:

```bash
docker swarm init --advertise-addr 192.0.2.10
```

Display the worker join command on `DEV-1`:

```bash
docker swarm join-token worker
```

Run the generated join command on `DEV-2`. Do not store the real join token in this repository.

Verify cluster membership on `DEV-1`:

```bash
docker node ls
```

## Part 3 — Deploy the Swarm stack

Run on the manager (`DEV-1`):

```bash
cd swarm/session-76-compose-vs-swarm/swarm
docker stack config -c stack.yaml > /dev/null
docker stack deploy -c stack.yaml compare
```

Verify the stack and service:

```bash
docker stack ls
docker stack services compare
docker service ps compare_web
docker stack ps compare
```

The desired state is three replicas.

## Part 4 — Test ingress routing mesh

From a host that can reach both Swarm nodes:

```bash
curl http://192.0.2.10:8088
curl http://192.0.2.11:8088
```

Run repeated requests against the manager:

```bash
for i in {1..10}; do curl -s http://192.0.2.10:8088; echo; done
```

You may see different task hostnames because requests can be routed to different service tasks.

## Part 5 — Desired state and reconciliation

List task containers on a node:

```bash
docker ps --filter label=com.docker.swarm.service.name=compare_web
```

For the lab, remove one task container using its real ID:

```bash
docker rm -f CONTAINER_ID
```

Then verify that Swarm recreates a task to return to the desired replica count:

```bash
docker service ps compare_web
docker stack services compare
```

## Part 6 — Scale the Swarm service

Scale from three replicas to five:

```bash
docker service scale compare_web=5
docker service ps compare_web
```

Return to three replicas:

```bash
docker service scale compare_web=3
```

## Part 7 — Drain and reactivate a node

Use the exact node name shown by `docker node ls`.

```bash
docker node update --availability drain dev-2
docker node ls
docker service ps compare_web
```

Reactivate the node:

```bash
docker node update --availability active dev-2
```

Swarm does not necessarily rebalance already healthy tasks immediately after a node becomes active again.

## Troubleshooting

Show full task errors:

```bash
docker service ps compare_web --no-trunc
```

Inspect the service specification:

```bash
docker service inspect compare_web --pretty
```

Inspect networks:

```bash
docker network ls
```

Check Swarm-related listening ports:

```bash
ss -lntup | grep -E '2377|7946|4789'
```

## Cleanup

Remove only the stack and keep the Swarm cluster for later labs:

```bash
docker stack rm compare
```

Verify removal:

```bash
docker stack ls
```

## Key comparison

**Docker Compose** defines and runs a multi-container application on a Docker Engine.

**Docker Swarm** manages desired state for services across a cluster and adds scheduling, replicas, overlay networking, routing mesh, and node-level orchestration.

## Interview review

1. Why does `docker compose up` not deploy workloads across all Swarm nodes?
2. What is the difference between a Swarm service, task, and container?
3. What is desired state and how does reconciliation work?
4. What happens when one task container is deleted manually?
5. What is ingress routing mesh?
6. What happens when a worker node is placed in `drain` mode?
7. Why is a single-manager Swarm acceptable for a lab but not highly available for production?

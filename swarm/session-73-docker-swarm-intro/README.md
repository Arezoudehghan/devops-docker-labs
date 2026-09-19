# Session 73 — Docker Swarm Introduction

This lab introduces Docker Swarm using a two-node environment and focuses on the core orchestration concepts that later map naturally to Kubernetes: nodes, manager and worker roles, services, tasks, desired state, scheduling, self-healing, overlay networking, ingress routing mesh, and scaling.

## Learning goals

By the end of this lab you should be able to explain and demonstrate:

- What Docker Swarm is and why orchestration is needed.
- The difference between a node, manager, worker, service, task, and container.
- Desired state and reconciliation.
- Replicated and global services.
- Swarm scheduling and self-healing.
- Swarm management, node communication, and overlay network ports.
- Ingress routing mesh behavior.
- How Swarm concepts prepare you for Kubernetes.

## Lab layout

```text
session-73-docker-swarm-intro/
├── README.md
└── commands-cheatsheet.txt
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
hostname
ip -br addr
systemctl is-active docker
docker version
docker info --format 'Swarm={{.Swarm.LocalNodeState}} NodeID={{.Swarm.NodeID}}'
```

Check that application port `8088` is currently unused:

```bash
ss -lntup | grep ':8088 ' || true
```

Swarm nodes must be able to communicate on:

- `2377/tcp` — cluster management.
- `7946/tcp` and `7946/udp` — node communication.
- `4789/udp` — overlay network data path.

Do not expose `4789/udp` to untrusted networks.

## Part 1 — Initialize the Swarm manager

Run on `DEV-1` using its real management address:

```bash
docker swarm init --advertise-addr 192.0.2.10
```

Verify manager state:

```bash
docker info --format 'Swarm={{.Swarm.LocalNodeState}} ControlAvailable={{.Swarm.ControlAvailable}} NodeID={{.Swarm.NodeID}}'
docker node ls
```

## Part 2 — Join the worker

Display the worker join command on `DEV-1`:

```bash
docker swarm join-token worker
```

Run the generated join command on `DEV-2`. Never commit the real join token.

Example syntax:

```bash
docker swarm join --token YOUR_WORKER_TOKEN 192.0.2.10:2377
```

Verify membership on `DEV-1`:

```bash
docker node ls
```

## Part 3 — Inspect Swarm networking

Run on both nodes:

```bash
docker network ls
```

After Swarm is enabled, you should see Swarm-related networking such as `ingress` and `docker_gwbridge`.

## Part 4 — Prepare the image

Run on both nodes if the image is not already present:

```bash
docker image inspect nginx:alpine >/dev/null 2>&1 && echo "IMAGE EXISTS" || echo "IMAGE NOT FOUND"
docker pull nginx:alpine
```

## Part 5 — Create the first Swarm service

Run on the manager:

```bash
docker service create \
  --name web-demo \
  --replicas 2 \
  --publish published=8088,target=80 \
  nginx:alpine
```

Verify the service and its tasks:

```bash
docker service ls
docker service ps web-demo
```

Inspect task containers on each node:

```bash
docker ps --filter label=com.docker.swarm.service.name=web-demo
```

## Part 6 — Test ingress routing mesh

From a host that can reach both Swarm nodes:

```bash
curl -I http://192.0.2.10:8088
curl -I http://192.0.2.11:8088
```

A published Swarm service port can accept traffic on a Swarm node and route it to an active task, even when the task is running on another node.

## Part 7 — Scale the service

Run on `DEV-1`:

```bash
docker service scale web-demo=4
docker service ls
docker service ps web-demo
```

The service definition now declares a desired state of four replicas. Swarm creates and schedules tasks until the actual state matches it.

## Part 8 — Demonstrate self-healing

Find a task container on either node:

```bash
docker ps --filter label=com.docker.swarm.service.name=web-demo
```

Kill one task container for the lab:

```bash
docker kill CONTAINER_ID
```

Then verify reconciliation from the manager:

```bash
docker service ps web-demo
docker service ls
```

The failed task is not revived as the same task. Swarm creates a replacement task to restore the declared replica count.

## Core mental model

```text
Service
  ↓ desired replicas
Task
  ↓ scheduled to a node
Container
```

A service expresses desired state. Tasks are the unit of scheduling. Each task runs one container.

## Replicated vs global services

Replicated service example:

```bash
docker service create --name web --replicas 3 nginx:alpine
```

Global service example:

```bash
docker service create --name agent --mode global alpine top
```

A replicated service runs a requested number of tasks. A global service runs one task on each eligible node.

## Troubleshooting

Inspect cluster state:

```bash
docker info
docker node ls
```

Inspect service state:

```bash
docker service ls
docker service ps web-demo --no-trunc
docker service inspect web-demo --pretty
docker service logs web-demo
```

Inspect networks:

```bash
docker network ls
```

Check manager reachability and Docker:

```bash
ping -c 3 192.0.2.10
ss -lntp | grep 2377
systemctl status docker --no-pager
```

## Cleanup

Remove only the demo service and keep the Swarm cluster for later labs:

```bash
docker service rm web-demo
docker service ls
```

Only when intentionally destroying the lab cluster, leave from the worker first:

```bash
docker swarm leave
```

Then remove the final single manager:

```bash
docker swarm leave --force
```

`--force` is destructive in this context and should not be used casually on production managers.

## Interview review

1. What problem does Docker Swarm solve?
2. What is the difference between a manager and a worker node?
3. What is the difference between a service, task, and container?
4. What is desired state?
5. What does reconciliation mean?
6. What happens when a task container crashes?
7. What is the difference between replicated and global services?
8. What is ingress routing mesh?
9. What is an overlay network?
10. What are the main Swarm ports?
11. Why are odd numbers of managers commonly used in highly available Swarm clusters?
12. How do Swarm concepts prepare you for Kubernetes?

## Command reference

See [`commands-cheatsheet.txt`](commands-cheatsheet.txt) for the executable commands used in this session.
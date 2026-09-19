# Session 74 — Docker Swarm Command Cheat Sheet

This cheat sheet contains the executable commands used in Session 74: **Service, Replica, and Overlay Network**.

## Environment and Swarm verification

Show the current host name:

```bash
hostname
```

Show network interfaces and addresses in brief form:

```bash
ip -br a
```

Show Docker client and server versions:

```bash
docker version
```

Show the local Swarm state, manager availability, and node ID:

```bash
docker info --format 'Swarm={{.Swarm.LocalNodeState}} ControlAvailable={{.Swarm.ControlAvailable}} NodeID={{.Swarm.NodeID}}'
```

List Swarm nodes from a manager:

```bash
docker node ls
```

Initialize Swarm on DEV-1 when it is not already initialized:

```bash
docker swarm init --advertise-addr 192.168.94.90
```

Display the worker join command and token:

```bash
docker swarm join-token worker
```

Check UFW firewall state:

```bash
sudo ufw status
```

## Images

Pull the Nginx image used by the service:

```bash
docker pull nginx:1.30.4-alpine
```

Pull Alpine for DNS and HTTP troubleshooting:

```bash
docker pull alpine:3.24.1
```

## Overlay network

Create an attachable Swarm overlay network:

```bash
docker network create \
  --driver overlay \
  --attachable \
  swarm-app-net
```

List Docker networks:

```bash
docker network ls
```

Inspect the lab overlay network:

```bash
docker network inspect swarm-app-net
```

List only overlay networks:

```bash
docker network ls --filter driver=overlay
```

## Service creation

Create the Nginx service with three replicas, ingress publishing, and a health check:

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

## Service verification

List Swarm services:

```bash
docker service ls
```

Show task history and placement for `web-demo`:

```bash
docker service ps web-demo
```

Show a readable service specification:

```bash
docker service inspect web-demo --pretty
```

Show service virtual IP data:

```bash
docker service inspect web-demo \
  --format '{{json .Endpoint.VirtualIPs}}'
```

## Local containers

List all local running containers:

```bash
docker ps
```

List local containers that belong to the Swarm service:

```bash
docker ps \
  --filter label=com.docker.swarm.service.name=web-demo
```

Show service container ID, name, and status:

```bash
docker ps \
  --filter label=com.docker.swarm.service.name=web-demo \
  --format '{{.ID}}  {{.Names}}  {{.Status}}'
```

Return only local container IDs for the service:

```bash
docker ps --filter label=com.docker.swarm.service.name=web-demo -q
```

Select the first line from piped output:

```bash
head -n 1
```

## Routing mesh tests

Test the published port through DEV-1:

```bash
curl -I http://192.168.94.90:8088
```

Test the same service through DEV-2:

```bash
curl -I http://192.168.94.91:8088
```

## Overlay DNS and HTTP tests

Resolve the service name from an attached Alpine container:

```bash
docker run --rm \
  --network swarm-app-net \
  alpine:3.24.1 \
  nslookup web-demo
```

Send an HTTP request to the service by service name:

```bash
docker run --rm \
  --network swarm-app-net \
  alpine:3.24.1 \
  wget -qO- http://web-demo
```

## Scaling

Scale the service to five replicas:

```bash
docker service scale web-demo=5
```

Scale the service to two replicas:

```bash
docker service scale web-demo=2
```

Return the service to three replicas:

```bash
docker service scale web-demo=3
```

## Self-healing test

Kill the first local container belonging to the service:

```bash
docker kill $(docker ps \
  --filter label=com.docker.swarm.service.name=web-demo \
  -q | head -n 1)
```

The command substitution `$(...)` runs the inner command first and passes the resulting container ID to `docker kill`.

## Cleanup

Remove the service:

```bash
docker service rm web-demo
```

Remove the custom overlay network:

```bash
docker network rm swarm-app-net
```

Verify the remaining services and networks:

```bash
docker service ls
docker network ls
```

## Fast operational sequence

```bash
docker node ls
docker network create --driver overlay --attachable swarm-app-net
docker service ls
docker service ps web-demo
docker service inspect web-demo --pretty
docker service scale web-demo=5
docker service scale web-demo=3
docker network ls --filter driver=overlay
```

## Swarm ports to remember

- `2377/TCP` — Swarm management.
- `7946/TCP` and `7946/UDP` — node communication and discovery.
- `4789/UDP` — overlay network data path.

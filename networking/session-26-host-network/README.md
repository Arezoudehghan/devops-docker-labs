# Session 26 — Docker Host Network

This lab demonstrates Docker host networking on a Linux Docker host. It compares bridge networking with `--network host`, verifies the active network mode, shows how host ports are shared directly, and reproduces a host-port conflict with a second Nginx container.

## Files

```text
session-26-host-network/
├── README.md
├── compose.yaml
└── DevOps_Host_Network_Session_26_Commands_CheatSheet.txt
```

## Learning goals

- Understand how `--network host` differs from bridge networking.
- Verify that a host-networked container uses the Docker host network stack.
- Confirm that normal Docker port publishing is unnecessary in host mode.
- Detect a host-port conflict.
- Run the same host-network configuration with Docker Compose.

## 1. Inspect Docker networks

```bash
docker network ls
```

Check the Docker host addresses:

```bash
ip addr
```

## 2. Bridge-network comparison

Run Nginx with normal bridge networking and publish host port `8080` to container port `80`:

```bash
docker run -d \
  --name web \
  -p 8080:80 \
  nginx:alpine
```

Verify the running container:

```bash
docker ps
```

## 3. Run Nginx with host networking

Remove the bridge-network comparison container before reusing the name if needed, then run Nginx in host network mode:

```bash
docker run -d \
  --name host-nginx \
  --network host \
  nginx:alpine
```

Host mode does not require `-p` because the container uses the host network stack directly.

Verify the service locally:

```bash
curl http://127.0.0.1
curl http://localhost
```

To test from another machine, replace the example address below with the real Docker host IP:

```bash
curl http://192.168.1.50
```

## 4. Verify the network mode

```bash
docker inspect host-nginx \
  --format '{{.HostConfig.NetworkMode}}'
```

Expected value:

```text
host
```

## 5. Inspect listening ports

```bash
sudo ss -lntp
```

Filter for port `80`:

```bash
sudo ss -lntp | grep ':80'
```

## 6. Reproduce a host-port conflict

Start a second Nginx container with host networking:

```bash
docker run -d \
  --name host-nginx-2 \
  --network host \
  nginx:alpine
```

Because both Nginx processes try to bind the same host port, the second container may stop immediately.

Inspect its state and logs:

```bash
docker ps -a
docker logs host-nginx-2
```

## 7. Bridge-network contrast with two containers

Bridge networking allows two containers to expose the same internal port through different host ports:

```bash
docker run -d \
  --name web1 \
  -p 8081:80 \
  nginx:alpine
```

```bash
docker run -d \
  --name web2 \
  -p 8082:80 \
  nginx:alpine
```

## 8. Docker Compose host networking

The included `compose.yaml` contains:

```yaml
services:
  nginx:
    image: nginx:alpine
    network_mode: host
```

Validate the Compose file:

```bash
docker compose config --quiet
```

Start it:

```bash
docker compose up -d
```

Verify:

```bash
curl http://127.0.0.1:80
```

View logs if needed:

```bash
docker compose logs nginx
```

Stop the Compose lab:

```bash
docker compose down
```

## Troubleshooting checklist

Check all containers:

```bash
docker ps -a
```

Read the host-network container logs:

```bash
docker logs host-nginx
```

Check whether port `80` is already in use:

```bash
sudo ss -lntp | grep ':80'
```

Confirm the configured network mode:

```bash
docker inspect host-nginx \
  --format '{{.HostConfig.NetworkMode}}'
```

## Key concept

```text
Bridge mode:
Client -> Host published port -> Docker bridge/NAT -> Container IP:port

Host mode:
Client -> Host IP:port -> Application inside container
```

With host networking, the container shares the host network stack. This reduces network isolation and makes host-port conflicts more direct, so use host mode only when the workload actually needs it.

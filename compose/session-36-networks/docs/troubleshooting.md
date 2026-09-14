# Troubleshooting Guide

## Port 8086 is already in use

### Symptom

Compose reports an error similar to `address already in use` while creating the Frontend container.

### Verification

```bash
sudo ss -lntp | grep ':8086'
```

### Resolution

Change `HOST_PORT` in `.env`, then recreate the application:

```bash
docker compose up -d --build
```

## Frontend returns 502 Bad Gateway

### Likely causes

- The API is not healthy.
- The API container is not running.
- Frontend and API do not share `frontend_net`.
- Nginx cannot resolve the `api` service name.

### Verification

```bash
docker compose ps
docker compose logs --tail=100 api
docker compose logs --tail=100 frontend
docker compose exec frontend nslookup api
```

## API returns 503 Service Unavailable

### Likely causes

- Redis is stopped or unhealthy.
- API and Redis do not share `backend_net`.
- `REDIS_HOST` or `REDIS_PORT` is incorrect.

### Verification

```bash
docker compose ps
docker compose logs --tail=100 redis
docker compose logs --tail=100 api
docker compose exec api python -c "import socket; print(socket.gethostbyname('redis'))"
```

## Frontend can resolve Redis unexpectedly

### Cause

Frontend was accidentally attached to `backend_net`, removing the intended network isolation.

### Verification

```bash
docker network inspect compose-networks-lab_backend_net
```

Only API and Redis should be members of this network.

## Source changes are not applied

Rebuild and recreate the containers:

```bash
docker compose up -d --build --force-recreate
```

## Inspect project networks

```bash
docker network ls --filter name=compose-networks-lab
docker network inspect compose-networks-lab_frontend_net
docker network inspect compose-networks-lab_backend_net
```

Expected membership:

| Network | Expected services |
|---|---|
| `frontend_net` | Frontend and API |
| `backend_net` | API and Redis |

## Collect diagnostic information

```bash
docker compose config
docker compose ps
docker compose logs --tail=200
docker network ls
```

Do not use container IP addresses as permanent configuration values. They may change after a container is recreated.

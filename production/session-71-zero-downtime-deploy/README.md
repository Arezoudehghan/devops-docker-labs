# Session 71 — Simple Zero-Downtime Deployment

A hands-on Blue/Green deployment lab using Docker and Nginx on a single Docker host.

The goal is to deploy a new application version, validate it before cutover, switch traffic with an Nginx graceful reload, and keep the previous version available for fast rollback.

## Architecture

```text
Client
  |
  v
DEV-2:8088
  |
  v
app-proxy (Nginx)
  |                 \
  v                  v
app-blue           app-green
zero-app:v1        zero-app:v2
       \            /
           prod-net
```

Only `app-proxy` publishes a host port. Blue and Green stay private on the Docker network, which allows both versions to run at the same time without host-port conflicts.

## Project structure

```text
session-71-zero-downtime-deploy/
├── nginx/
│   └── default.conf
├── releases/
│   ├── v1/
│   │   ├── Dockerfile
│   │   ├── health
│   │   └── index.html
│   └── v2/
│       ├── Dockerfile
│       ├── health
│       └── index.html
├── scripts/
│   └── switch.sh
├── CHEATSHEET.md
└── README.md
```

## Command cheat sheet

For the complete Session 71 command reference, see [`CHEATSHEET.md`](CHEATSHEET.md).

## Requirements

- Docker Engine
- `curl`
- Port `8088` available on the deployment host

## 1. Build both versions

Run from this lab directory:

```bash
docker build -t zero-app:v1 releases/v1
docker build -t zero-app:v2 releases/v2
```

## 2. Create the production network

```bash
docker network create prod-net
```

If the network already exists, keep the existing network and continue.

## 3. Start Blue (current production)

```bash
docker run -d \
  --name app-blue \
  --network prod-net \
  --restart unless-stopped \
  zero-app:v1
```

Verify the Docker health status:

```bash
docker inspect --format='{{.State.Health.Status}}' app-blue
```

Expected state after the health check succeeds:

```text
healthy
```

## 4. Start the Nginx reverse proxy

The supplied `nginx/default.conf` initially routes traffic to `app-blue`.

```bash
docker run -d \
  --name app-proxy \
  --network prod-net \
  -p 8088:80 \
  --restart unless-stopped \
  -v "$PWD/nginx:/etc/nginx/conf.d:ro" \
  nginx:alpine
```

Validate the Nginx configuration:

```bash
docker exec app-proxy nginx -t
```

Verify production traffic:

```bash
curl -fsS http://127.0.0.1:8088/
```

Expected response:

```text
VERSION=v1 SLOT=BLUE
```

## 5. Start Green (candidate release)

```bash
docker run -d \
  --name app-green \
  --network prod-net \
  --restart unless-stopped \
  zero-app:v2
```

Check its Docker health status:

```bash
docker inspect --format='{{.State.Health.Status}}' app-green
```

Then verify Green from the proxy network before sending user traffic to it:

```bash
docker exec app-proxy wget -qO- http://app-green/
docker exec app-proxy wget -qO- http://app-green/health
```

Expected responses:

```text
VERSION=v2 SLOT=GREEN
OK
```

## 6. Cut over to Green

The switch script performs these gates before and after cutover:

1. Validate the target argument.
2. Require the target container to be `healthy`.
3. Verify the target from inside `app-proxy`.
4. Back up the active Nginx configuration.
5. Update the upstream target.
6. Run `nginx -t`.
7. Perform a graceful Nginx reload.
8. Run a post-deployment HTTP check.
9. Restore the previous Nginx configuration automatically if the post-deployment check fails.

Make the script executable:

```bash
chmod +x scripts/switch.sh
```

Switch production traffic to Green:

```bash
./scripts/switch.sh app-green
```

Verify:

```bash
curl -fsS http://127.0.0.1:8088/
```

Expected response:

```text
VERSION=v2 SLOT=GREEN
```

## 7. Roll back to Blue

Blue remains running as the known-good release.

```bash
./scripts/switch.sh app-blue
```

Verify:

```bash
curl -fsS http://127.0.0.1:8088/
```

Expected response:

```text
VERSION=v1 SLOT=BLUE
```

## Zero-downtime verification

With Blue active, send repeated requests:

```bash
rm -f /tmp/zero-downtime-test.log
(
  for i in $(seq 1 100); do
    if BODY=$(curl -fsS --max-time 2 http://127.0.0.1:8088/); then
      printf '%s OK %s\n' "$(date '+%H:%M:%S.%3N')" "$BODY"
    else
      printf '%s FAILED\n' "$(date '+%H:%M:%S.%3N')"
    fi
    sleep 0.1
  done
) | tee /tmp/zero-downtime-test.log &
MON_PID=$!
```

Perform the cutover while requests are running:

```bash
./scripts/switch.sh app-green
wait "$MON_PID"
```

Count failed requests:

```bash
grep -c 'FAILED' /tmp/zero-downtime-test.log
```

Target result:

```text
0
```

## Troubleshooting

Check the proxy:

```bash
docker ps -a --filter name=app-proxy
docker logs --tail 100 app-proxy
docker exec app-proxy nginx -t
```

Check Docker networking:

```bash
docker network inspect prod-net
docker exec app-proxy wget -qO- http://app-blue/
docker exec app-proxy wget -qO- http://app-green/
```

Inspect an unhealthy release:

```bash
docker inspect --format='{{json .State.Health}}' app-green
docker logs --tail 100 app-green
```

## Important production note

This lab demonstrates zero-downtime deployment on one Docker host. It does **not** provide host-level high availability. If the Docker host fails, Blue, Green, and the reverse proxy all become unavailable. Real HA requires redundant hosts and an external load-balancing/orchestration design.

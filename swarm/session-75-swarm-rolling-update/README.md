# Session 75 — Docker Swarm Rolling Update

Practical DevOps lab for learning rolling updates, health checks, automatic rollback, manual rollback, and rolling restart in Docker Swarm.

## Lab architecture

- **DEV-1** — `192.168.94.90`
  - Docker Swarm Manager
  - Docker build host
  - Nexus Docker Registry: `192.168.94.90:8085`
- **DEV-2** — `192.168.94.91`
  - Docker Swarm Worker

## Project files

- `app.py` — Small Python HTTP service with `/` and `/health` endpoints.
- `Dockerfile` — Builds the application image and defines the container health check.
- `stack.yml` — Swarm stack with 4 replicas, rolling-update policy, and rollback policy.
- `CHEATSHEET.md` — Session-only command reference for deployment, rolling update, rollback, verification, and troubleshooting.

## Application behavior

The root endpoint returns the application version and container hostname:

```text
VERSION=v1 HOST=<container-hostname>
```

The health endpoint returns `200 OK` when `HEALTH_MODE=ok` and `500` when `HEALTH_MODE=fail`.

## Build and push the images

Login to the private registry first:

```bash
docker login 192.168.94.90:8085
```

Build and push the healthy `v1` image:

```bash
docker build \
  --build-arg APP_VERSION=v1 \
  --build-arg HEALTH_MODE=ok \
  -t 192.168.94.90:8085/swarm-rolling-demo:v1 .

docker push 192.168.94.90:8085/swarm-rolling-demo:v1
```

Build and push the healthy `v2` image:

```bash
docker build \
  --build-arg APP_VERSION=v2 \
  --build-arg HEALTH_MODE=ok \
  -t 192.168.94.90:8085/swarm-rolling-demo:v2 .

docker push 192.168.94.90:8085/swarm-rolling-demo:v2
```

Build and push the intentionally unhealthy image used to test automatic rollback:

```bash
docker build \
  --build-arg APP_VERSION=v3-broken \
  --build-arg HEALTH_MODE=fail \
  -t 192.168.94.90:8085/swarm-rolling-demo:v3-broken .

docker push 192.168.94.90:8085/swarm-rolling-demo:v3-broken
```

## Validate the stack

```bash
docker stack config -c stack.yml
```

## Deploy v1

```bash
docker stack deploy \
  --with-registry-auth \
  -c stack.yml \
  rolling
```

Verify the service:

```bash
docker stack services rolling
docker service ps rolling_web
curl http://192.168.94.90:8088/
```

## Rolling update: v1 → v2

Change the image tag in `stack.yml` from `v1` to `v2`, validate the stack, and deploy again:

```bash
docker stack config -c stack.yml

docker stack deploy \
  --with-registry-auth \
  -c stack.yml \
  rolling
```

Monitor the update:

```bash
watch -n 1 'docker service ps rolling_web'
```

The stack uses:

- `parallelism: 1`
- `delay: 10s`
- `monitor: 15s`
- `failure_action: rollback`
- `order: start-first`

## Automatic rollback test

Change the image tag in `stack.yml` from `v2` to `v3-broken` and deploy again. The new tasks fail their health check and Swarm should automatically roll the service back to the previous healthy specification.

Inspect the result with:

```bash
docker service inspect --pretty rolling_web
docker service ps rolling_web --no-trunc
curl http://192.168.94.90:8088/
```

After the test, restore `stack.yml` to the healthy `v2` tag so the declared configuration matches the running service.

## Manual rollback

Use manual rollback when the container is technically healthy but the new application version has a logical or business-level bug:

```bash
docker service update --rollback rolling_web
```

## Rolling restart without changing the image

```bash
docker service update \
  --force \
  --update-parallelism 1 \
  --update-delay 10s \
  rolling_web
```

## Troubleshooting commands

```bash
docker node ls
docker service ls
docker service ps rolling_web --no-trunc
docker service inspect --pretty rolling_web
docker service logs -f rolling_web
```

## Learning goals

This lab demonstrates the operational ideas that later map naturally to Kubernetes Deployments: gradual replacement of replicas, availability during rollout, health-based failure detection, rollout observation, and rollback.

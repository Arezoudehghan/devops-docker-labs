# Session 68 - Docker Resource Limits: CPU and RAM

A hands-on production lab for controlling container CPU and memory usage with Docker Engine and Docker Compose.

The goal is to prevent one container from consuming uncontrolled host resources, observe CPU throttling and memory pressure, and verify limits with Docker inspection and runtime statistics.

## Project structure

```text
session-68-resource-limit-cpu-ram/
|- compose.yaml
|- DevOps_Docker_Resource_Limit_CPU_RAM_Session_68_Commands_CheatSheet.txt
`- README.md
```

## Requirements

- Docker Engine
- Docker Compose plugin
- Port `8080` available on the Docker host

## 1. Run the Compose lab

Validate the Compose file:

```bash
docker compose config
```

Start the service:

```bash
docker compose up -d
```

Check the service:

```bash
docker compose ps
```

Observe resource usage:

```bash
docker stats
```

The Compose service uses `0.50` CPU, a `256m` hard memory limit, a `128m` memory reservation, and a `256m` RAM-plus-swap limit.

## 2. CPU hard-limit test

```bash
docker run -d \
  --name cpu-test \
  --cpus="0.5" \
  alpine \
  sh -c 'while true; do :; done'
```

```bash
docker stats cpu-test
```

```bash
docker rm -f cpu-test
```

## 3. CPU shares test

Run two busy containers on the same logical CPU with different relative weights:

```bash
docker run -d \
  --name cpu-high \
  --cpuset-cpus="0" \
  --cpu-shares=1024 \
  alpine \
  sh -c 'while true; do :; done'
```

```bash
docker run -d \
  --name cpu-low \
  --cpuset-cpus="0" \
  --cpu-shares=512 \
  alpine \
  sh -c 'while true; do :; done'
```

```bash
docker stats cpu-high cpu-low
```

```bash
docker rm -f cpu-high cpu-low
```

`--cpu-shares` is a relative scheduling weight during CPU contention, not a hard CPU ceiling.

## 4. Memory and OOM test

```bash
docker run \
  --name ram-test \
  --memory="100m" \
  --memory-swap="100m" \
  python:3.12-slim \
  python -c 'a=bytearray(200*1024*1024); import time; time.sleep(60)'
```

Inspect the result:

```bash
docker inspect \
  --format 'OOMKilled={{.State.OOMKilled}} ExitCode={{.State.ExitCode}}' \
  ram-test
```

A typical OOM result is `OOMKilled=true ExitCode=137`.

```bash
docker rm ram-test
```

## 5. Production-style example

```bash
docker run -d \
  --name production-web \
  --restart=unless-stopped \
  --cpus="1.0" \
  --memory="512m" \
  --memory-reservation="384m" \
  --memory-swap="512m" \
  -p 8080:80 \
  nginx:alpine
```

Verify runtime usage:

```bash
docker stats --no-stream production-web
```

Inspect configured limits:

```bash
docker inspect --format '{{.HostConfig.Memory}}' production-web
docker inspect --format '{{.HostConfig.NanoCpus}}' production-web
```

Update limits on an existing container:

```bash
docker update \
  --cpus="1.0" \
  --memory="512m" \
  production-web
```

## Troubleshooting

```bash
docker ps -a
docker inspect --format 'Status={{.State.Status}} OOMKilled={{.State.OOMKilled}} ExitCode={{.State.ExitCode}}' production-web
docker logs production-web
```

## Cleanup

```bash
docker compose down
docker rm -f production-web
```

## Key lesson

Use monitoring and load testing to size CPU and memory limits. A missing limit can allow a container to affect the whole host, while a limit that is too small can cause throttling, OOM kills, and restart loops.

# Session 62 — Monitoring Containers with cAdvisor

Chapter 10 — Logging and Monitoring

This lab introduces container-level monitoring with cAdvisor on DEV-2. It runs cAdvisor as a Docker container, exposes its web interface and Prometheus metrics endpoint, and verifies CPU, memory, network, filesystem, and OOM-related metrics.

## Execution host

Run this lab on `DEV-2`.

Lab address used in this lesson:

`192.168.94.91`

## Architecture

```text
Docker Containers
       |
       v
    cAdvisor
       |
       | /metrics
       v
   Prometheus
       |
       v
     Grafana
       |
       v
 Alertmanager
```

This session focuses on cAdvisor itself. Prometheus integration is shown only as the next monitoring step.

## Repository files

- `README.md`: hands-on cAdvisor lab.
- `docs/DevOps_cAdvisor_Monitoring_Session_62_Commands_CheatSheet.txt`: command cheat sheet for this lesson.

## 1. Check the current Docker host

Check whether a cAdvisor container already exists:

```bash
docker ps -a --filter name=cadvisor
```

Check whether TCP port 8080 is already in use:

```bash
sudo ss -lntp | grep ':8080' || true
```

List currently running containers:

```bash
docker ps
```

If cAdvisor already exists, inspect the configured image:

```bash
docker inspect cadvisor \
  --format '{{.Config.Image}}'
```

## 2. Pull cAdvisor

```bash
docker pull ghcr.io/google/cadvisor:v0.60.5
```

Verify the local image:

```bash
docker image ls ghcr.io/google/cadvisor
```

Check the kernel message device:

```bash
ls -l /dev/kmsg
```

## 3. Run cAdvisor

If an old cAdvisor container must be replaced:

```bash
docker rm -f cadvisor 2>/dev/null || true
```

Start cAdvisor:

```bash
docker run -d \
  --name cadvisor \
  --restart unless-stopped \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --volume=/dev/disk/:/dev/disk:ro \
  --publish=192.168.94.91:8080:8080 \
  --privileged \
  --device=/dev/kmsg \
  ghcr.io/google/cadvisor:v0.60.5
```

The host mounts are read-only. cAdvisor is still a privileged container, so its port should not be exposed directly to an untrusted network.

## 4. Verify cAdvisor

Check the container:

```bash
docker ps --filter name=cadvisor
```

Check recent logs:

```bash
docker logs --tail 50 cadvisor
```

Follow logs when troubleshooting:

```bash
docker logs -f cadvisor
```

Open the web interface:

```text
http://192.168.94.91:8080/
```

Check the Prometheus metrics endpoint:

```bash
curl -fsS http://192.168.94.91:8080/metrics | head
```

## 5. Inspect important metrics

CPU:

```bash
curl -fsS http://192.168.94.91:8080/metrics \
  | grep '^container_cpu_usage_seconds_total' \
  | head
```

Memory usage:

```bash
curl -fsS http://192.168.94.91:8080/metrics \
  | grep '^container_memory_usage_bytes' \
  | head
```

Memory limit:

```bash
curl -fsS http://192.168.94.91:8080/metrics \
  | grep '^container_spec_memory_limit_bytes' \
  | head
```

Network metrics:

```bash
curl -fsS http://192.168.94.91:8080/metrics \
  | grep '^container_network_' \
  | head -n 20
```

Filesystem metrics:

```bash
curl -fsS http://192.168.94.91:8080/metrics \
  | grep '^container_fs_' \
  | head -n 20
```

OOM events:

```bash
curl -fsS http://192.168.94.91:8080/metrics \
  | grep '^container_oom_events_total'
```

## 6. Create a monitored test container

Run a small Nginx container with CPU and memory limits:

```bash
docker run -d \
  --name cadvisor-lab \
  --memory=128m \
  --cpus=0.50 \
  nginx:alpine
```

Verify it is running:

```bash
docker ps --filter name=cadvisor-lab
```

Compare cAdvisor monitoring with a one-time Docker statistics snapshot:

```bash
docker stats --no-stream cadvisor-lab
```

cAdvisor automatically discovers containers on the Docker host. It does not need to be installed inside each application container.

## 7. Prometheus target example

A later Prometheus configuration can scrape cAdvisor through its metrics endpoint:

```yaml
scrape_configs:
  - job_name: cadvisor
    scrape_interval: 5s

    static_configs:
      - targets:
          - cadvisor:8080
```

Do not apply this snippet until cAdvisor and Prometheus share networking that makes the target name `cadvisor` resolvable.

## 8. Final verification

Confirm cAdvisor is running:

```bash
docker ps --filter name=cadvisor
```

Confirm port 8080 is listening:

```bash
sudo ss -lntp | grep ':8080'
```

Confirm HTTP responds:

```bash
curl -I http://192.168.94.91:8080/
```

Confirm metrics are available:

```bash
curl -fsS http://192.168.94.91:8080/metrics | head
```

Confirm CPU metrics are exported:

```bash
curl -fsS http://192.168.94.91:8080/metrics \
  | grep '^container_cpu_usage_seconds_total' \
  | head
```

Confirm memory metrics are exported:

```bash
curl -fsS http://192.168.94.91:8080/metrics \
  | grep '^container_memory_usage_bytes' \
  | head
```

## 9. Clean up the test container

Remove only the temporary Nginx lab container:

```bash
docker rm -f cadvisor-lab
```

Keep the `cadvisor` container running for the next monitoring sessions.

## Key concepts

- `docker stats` is useful for quick live troubleshooting.
- cAdvisor exports structured container metrics.
- Node Exporter focuses on host-level Linux metrics.
- cAdvisor focuses on container-level resource metrics.
- Prometheus scrapes and stores metrics.
- Grafana visualizes metrics.
- Alertmanager handles alerts.

## Commands cheat sheet

See:

`docs/DevOps_cAdvisor_Monitoring_Session_62_Commands_CheatSheet.txt`

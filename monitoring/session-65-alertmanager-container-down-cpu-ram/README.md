# Session 65 — Alertmanager for Container Down / CPU / RAM

Chapter 10 — Logging and Monitoring

This lab extends the existing Docker monitoring stack with Prometheus alert rules for container availability, high CPU usage, and high memory usage, then forwards firing alerts to Alertmanager.

## Execution host

Run this lab on `DEV-2`.

The lesson assumes the monitoring stack already provides:

- Prometheus on port `9090`
- Alertmanager on port `9093`
- cAdvisor on port `8080`
- Node Exporter on port `9100`

## Project files

```text
session-65-alertmanager-container-down-cpu-ram/
├── prometheus/
│   ├── prometheus.yml
│   └── alerts/
│       └── container-alerts.yml
├── docs/
│   └── DevOps_Alertmanager_Container_Down_CPU_RAM_Session_65_Commands_CheatSheet.txt
└── README.md
```

## 1. Verify cAdvisor metrics

```bash
docker ps
curl -s http://localhost:8080/metrics | grep '^container_cpu_usage_seconds_total' | head
curl -s http://localhost:8080/metrics | grep '^container_memory_working_set_bytes' | head
curl -s http://localhost:8080/metrics | grep '^container_last_seen' | head
```

For Docker Engine 29.x, also inspect the cAdvisor logs for Docker API or container-factory errors:

```bash
docker version
docker logs cadvisor 2>&1 | tail -50
```

## 2. Create the test container

```bash
docker rm -f alert-demo 2>/dev/null || true

docker run -d \
  --name alert-demo \
  --memory=128m \
  --cpus=1 \
  python:3.12-slim \
  sleep infinity
```

Verify the container and cAdvisor labels:

```bash
docker ps --filter name=alert-demo
docker stats alert-demo --no-stream
curl -s http://localhost:8080/metrics | grep 'alert-demo' | head -20
```

## 3. Prometheus configuration

The included `prometheus/prometheus.yml` loads alert rules from:

```text
/etc/prometheus/alerts/*.yml
```

and sends alerts to:

```text
alertmanager:9093
```

The existing Prometheus Compose service must mount both files:

```yaml
volumes:
  - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
  - ./prometheus/alerts:/etc/prometheus/alerts:ro
```

## 4. Validate before restart

From the existing monitoring project directory:

```bash
cd /opt/monitoring
docker compose config -q

docker compose exec -T prometheus \
  promtool check config /etc/prometheus/prometheus.yml

docker compose exec -T prometheus \
  promtool check rules /etc/prometheus/alerts/container-alerts.yml
```

Restart and inspect the services:

```bash
docker compose restart prometheus alertmanager
docker compose ps
docker compose logs --tail=50 prometheus
docker compose logs --tail=50 alertmanager
```

## 5. High CPU alert

Generate CPU load:

```bash
docker exec -d alert-demo \
  python -c 'while True: pass'
```

Check the container:

```bash
docker stats alert-demo --no-stream
```

PromQL:

```promql
100 * sum by (name) (
  rate(container_cpu_usage_seconds_total{name="alert-demo"}[1m])
)
```

The `ContainerHighCPU` rule fires when usage stays above 80% of one CPU core for one minute.

Reset the container:

```bash
docker restart alert-demo
```

## 6. High memory alert

Allocate about 90 MiB:

```bash
docker exec -d alert-demo \
  python -c 'import time; x=bytearray(90*1024*1024); time.sleep(300)'
```

PromQL:

```promql
100 *
sum by (name) (
  container_memory_working_set_bytes{name="alert-demo"}
)
/
sum by (name) (
  container_spec_memory_limit_bytes{name="alert-demo"}
)
```

The `ContainerHighMemory` rule fires when usage stays above 70% of the configured memory limit for one minute.

Reset the container:

```bash
docker restart alert-demo
```

## 7. Container down alert

Stop the expected container:

```bash
docker stop alert-demo
```

PromQL:

```promql
absent(container_last_seen{name="alert-demo"})
```

When the cAdvisor series disappears, `ContainerDown` becomes pending and then firing after `30s`.

Recover the container:

```bash
docker start alert-demo
```

## 8. Final verification

```bash
curl -s http://localhost:9090/-/ready
curl -s http://localhost:9093/-/ready
curl -s http://localhost:8080/metrics | grep '^container_last_seen' | head
curl -s http://localhost:8080/metrics | grep 'alert-demo' | head
```

Prometheus alerts:

```text
http://localhost:9090/alerts
```

Alertmanager:

```text
http://localhost:9093
```

## Alert semantics

- `ContainerDown`: the expected `alert-demo` cAdvisor series is absent.
- `ContainerHighCPU`: CPU usage is above 80% of one CPU core for one minute.
- `ContainerHighMemory`: working-set memory is above 70% of the configured limit for one minute.
- `up{job="cadvisor"} == 0`: the cAdvisor scrape target itself is down; it does not mean that one application container is down.

## Command cheat sheet

See:

`docs/DevOps_Alertmanager_Container_Down_CPU_RAM_Session_65_Commands_CheatSheet.txt`

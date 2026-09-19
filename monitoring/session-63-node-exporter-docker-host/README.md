# Session 63 — Node Exporter and Docker Host

This lab adds Prometheus Node Exporter to a Docker host so Prometheus can collect host-level Linux metrics such as CPU, memory, filesystem, disk, load, and network statistics.

## Lab target

- Host: `DEV-2`
- Documentation address: `192.0.2.11`
- Node Exporter port: `9100`
- Node Exporter image: `quay.io/prometheus/node-exporter:v1.12.1`

> The repository uses documentation-only IP addresses. Replace `192.0.2.11` with the address assigned to your own DEV-2 VM.

## Files

- `compose.yaml` — Node Exporter service configured for host monitoring.
- `prometheus-scrape-job.yml` — scrape job to add under Prometheus `scrape_configs`.
- `docs/DevOps_Node_Exporter_and_Docker_Host_Session_63_Commands_CheatSheet.txt` — commands cheat sheet for this lesson.

## 1. Validate the Compose file

```bash
docker compose -f compose.yaml config --quiet
```

## 2. Start Node Exporter

```bash
docker compose up -d
```

## 3. Verify the container

```bash
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}' | grep -i node
```

Because the service uses `network_mode: host`, Docker does not publish a separate `9100:9100` port mapping.

## 4. Verify the metrics endpoint

```bash
curl -s http://127.0.0.1:9100/metrics | head
```

Check Node Exporter metrics specifically:

```bash
curl -s http://127.0.0.1:9100/metrics | grep '^node_' | head
```

## 5. Add the Prometheus scrape job

Add the contents of `prometheus-scrape-job.yml` under the existing Prometheus `scrape_configs` section.

Example target:

```text
192.0.2.11:9100
```

After updating Prometheus, validate the active configuration before restarting or reloading it.

Example when Prometheus runs in Docker:

```bash
PROM_CONTAINER=$(docker ps --format '{{.Names}} {{.Image}}' \
  | awk 'tolower($0) ~ /prom\/prometheus/ {print $1; exit}')

docker exec "$PROM_CONTAINER" \
  promtool check config /etc/prometheus/prometheus.yml
```

## 6. Verify Prometheus

Open the Prometheus targets page and confirm that the Node Exporter target is `UP`.

Useful PromQL:

```promql
up{job="node-exporter"}
```

CPU usage:

```promql
100 - (
  avg by(instance) (
    rate(node_cpu_seconds_total{mode="idle"}[5m])
  ) * 100
)
```

Memory usage:

```promql
100 * (
  1 -
  (
    node_memory_MemAvailable_bytes
    /
    node_memory_MemTotal_bytes
  )
)
```

Root filesystem usage:

```promql
100 * (
  1 -
  (
    node_filesystem_avail_bytes{mountpoint="/"}
    /
    node_filesystem_size_bytes{mountpoint="/"}
  )
)
```

## 7. CPU load test

Create a temporary CPU load container:

```bash
docker run --rm -d \
  --name session63-cpu-load \
  alpine \
  sh -c 'while true; do :; done'
```

Then watch the Node Exporter CPU query in Prometheus.

Cleanup:

```bash
docker rm -f session63-cpu-load
```

## Node Exporter vs cAdvisor

- Node Exporter: host-level metrics.
- cAdvisor: container-level resource metrics.

They complement each other in a Docker monitoring stack.

## Stop the lab

```bash
docker compose down
```

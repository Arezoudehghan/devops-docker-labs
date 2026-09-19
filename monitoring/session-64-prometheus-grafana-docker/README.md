# Session 64 — Prometheus + Grafana for Docker

A hands-on monitoring lab that collects Linux host metrics with Node Exporter, Docker container metrics with cAdvisor, stores and queries them in Prometheus, and visualizes them in Grafana.

## Architecture

```text
Linux host ----> Node Exporter :9100 ----\
                                      \
Docker --------> cAdvisor :8080 --------> Prometheus :9094 ----> Grafana :3004
Containers                             /
Prometheus self-metrics :9090 --------/
```

Prometheus runs inside Docker and reaches the host exporters through `host.docker.internal` mapped to Docker's `host-gateway`.

## Project structure

```text
session-64-prometheus-grafana-docker/
├── .env.example
├── compose.yaml
├── prometheus/
│   └── prometheus.yml
├── grafana/
│   └── provisioning/
│       └── datasources/
│           └── prometheus.yml
├── DevOps_Prometheus_Grafana_Docker_Session_64_Commands_CheatSheet.txt
└── README.md
```

## Requirements

- Docker Engine
- Docker Compose plugin
- Node Exporter already available on host port `9100`
- cAdvisor already available on host port `8080`
- Host ports `9094` and `3004` available
- `curl` for verification

## 1. Create the local environment file

Do not commit a real `.env` file.

```bash
cp .env.example .env
```

Replace the placeholder password, or generate a random one:

```bash
umask 077
printf 'GRAFANA_ADMIN_PASSWORD=%s\n' "$(openssl rand -hex 12)" > .env
```

## 2. Validate the Compose configuration

```bash
docker compose config
```

## 3. Pull the images

```bash
docker compose pull
```

## 4. Start Prometheus and Grafana

```bash
docker compose up -d
docker compose ps
```

## 5. Verify Prometheus

```bash
curl -fsS http://127.0.0.1:9094/-/ready
```

Open Prometheus in a browser:

```text
http://<DEV-2-IP>:9094
```

Check **Status → Target health**. These jobs should be `UP`:

- `prometheus`
- `node-exporter`
- `cadvisor`

Query:

```promql
up
```

API verification:

```bash
curl -sG \
  --data-urlencode 'query=up' \
  http://127.0.0.1:9094/api/v1/query \
  | python3 -m json.tool
```

## 6. Verify Grafana

```bash
curl -fsS http://127.0.0.1:3004/api/health
```

Open Grafana:

```text
http://<DEV-2-IP>:3004
```

Login user:

```text
admin
```

The Prometheus data source is provisioned automatically as:

```text
http://prometheus:9090
```

## Useful PromQL queries

Host CPU usage:

```promql
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

Host memory usage:

```promql
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
```

Container CPU rate:

```promql
rate(container_cpu_usage_seconds_total[1m])
```

Container memory:

```promql
container_memory_working_set_bytes{name!=""}
```

Container receive traffic:

```promql
sum by (name) (rate(container_network_receive_bytes_total{name!=""}[1m]))
```

Container transmit traffic:

```promql
sum by (name) (rate(container_network_transmit_bytes_total{name!=""}[1m]))
```

## Grafana dashboards used in the lesson

- Node Exporter Full: dashboard ID `1860`
- cAdvisor Docker Insights: dashboard ID `19908`

Imported dashboards may need query or label adjustments depending on the exact Node Exporter, cAdvisor, Docker, and Grafana versions in the environment.

## Troubleshooting

Prometheus logs:

```bash
docker logs --tail 100 session64-prometheus
```

Check the host mapping inside Prometheus:

```bash
docker exec session64-prometheus cat /etc/hosts | grep host.docker.internal
```

Verify the host exporters:

```bash
curl -fsS http://127.0.0.1:9100/metrics | head
curl -fsS http://127.0.0.1:8080/metrics | head
```

## Persistence

Prometheus and Grafana use named volumes:

- `session64-prometheus-data`
- `session64-grafana-data`

A normal `docker compose down` leaves these named volumes available.

```bash
docker compose down
```

Using `-v` removes the Compose volumes:

```bash
docker compose down -v
```

## Command cheat sheet

See:

`DevOps_Prometheus_Grafana_Docker_Session_64_Commands_CheatSheet.txt`

It contains the executable commands and PromQL expressions used in this lesson with beginner-friendly English explanations.

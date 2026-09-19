# Session 61 — Docker Logs and Log Drivers

Chapter 10: Logging and Monitoring

This lab practices Docker container logs, logging drivers, log rotation, Compose logging configuration, and basic logging troubleshooting.

## Learning goals

- Read container logs with `docker logs`
- Follow logs live and filter them by time or line count
- Inspect a container's logging driver and log path
- Compare `json-file`, `local`, and `none`
- Configure log rotation with `max-size` and `max-file`
- See the difference between application file logging and stdout/stderr logging
- Configure a Compose service with the `local` logging driver
- Validate a Docker daemon logging configuration safely

## Lab files

- `compose.yaml` — Compose logging lab using the `local` driver
- `daemon.local.example.json` — example daemon logging defaults; merge these keys into an existing `/etc/docker/daemon.json` instead of blindly overwriting it
- `docs/DevOps_Docker_Logs_Log_Driver_Session_61_Commands_CheatSheet.txt` — commands from the lesson with beginner-friendly English explanations

## 1. Check the daemon default logging driver

```bash
docker info --format 'Default Logging Driver: {{.LoggingDriver}}'
```

## 2. Generate stdout and stderr logs

```bash
docker rm -f session61-log-demo 2>/dev/null || true

docker run -d \
  --name session61-log-demo \
  python:3.12-slim \
  sh -c 'i=1; while true; do echo "INFO request_id=$i status=200"; echo "ERROR request_id=$i simulated=true" >&2; i=$((i+1)); sleep 2; done'
```

Read and follow the logs:

```bash
docker logs --tail 10 session61-log-demo
docker logs -f --tail 20 session61-log-demo
docker logs -t --tail 5 session61-log-demo
docker logs --since 1m session61-log-demo
```

Inspect the configured logging driver:

```bash
docker inspect -f '{{.HostConfig.LogConfig.Type}}' session61-log-demo
docker inspect -f '{{json .HostConfig.LogConfig}}' session61-log-demo
```

## 3. Test json-file rotation

The small `20k` value below is intentionally used for the lab so rotation happens quickly.

```bash
docker rm -f session61-rotate 2>/dev/null || true

docker run -d \
  --name session61-rotate \
  --log-driver json-file \
  --log-opt max-size=20k \
  --log-opt max-file=3 \
  python:3.12-slim \
  sh -c 'payload=$(printf "%02048d" 0); i=1; while true; do echo "line=$i $payload"; i=$((i+1)); sleep 0.05; done'
```

Verify:

```bash
docker inspect -f '{{json .HostConfig.LogConfig}}' session61-rotate
docker logs --tail 5 session61-rotate
```

## 4. Test the local log driver

```bash
docker rm -f session61-local 2>/dev/null || true

docker run -d \
  --name session61-local \
  --log-driver local \
  --log-opt max-size=20k \
  --log-opt max-file=3 \
  python:3.12-slim \
  sh -c 'i=1; while true; do echo "LOCAL log_id=$i"; i=$((i+1)); sleep 1; done'
```

Verify:

```bash
docker inspect -f '{{.HostConfig.LogConfig.Type}}' session61-local
docker logs --tail 5 session61-local
```

## 5. Compare file-only application logging

This container writes only to a file inside the container, not to stdout/stderr.

```bash
docker rm -f session61-file-only 2>/dev/null || true

docker run -d \
  --name session61-file-only \
  python:3.12-slim \
  sh -c 'while true; do echo "$(date) application-running" >> /tmp/app.log; sleep 2; done'

sleep 5
docker logs session61-file-only
docker exec session61-file-only tail -n 5 /tmp/app.log
```

The file contains log entries even though `docker logs` has no application output to read.

## 6. Test the none log driver

```bash
docker rm -f session61-none 2>/dev/null || true

docker run -d \
  --name session61-none \
  --log-driver none \
  python:3.12-slim \
  sh -c 'while true; do echo "THIS IS A LOG"; sleep 2; done'

docker inspect -f '{{.HostConfig.LogConfig.Type}}' session61-none
```

With `none`, Docker-managed container logs are unavailable.

## 7. Compose logging lab

Validate the file first:

```bash
docker compose config
```

Start the service:

```bash
docker compose up -d
docker compose ps
```

Read logs:

```bash
docker compose logs --tail 5 app
docker compose logs -f --tail 10 app
```

Verify the logging configuration:

```bash
CID="$(docker compose ps -q app)"

docker inspect \
  -f 'Driver={{.HostConfig.LogConfig.Type}} Config={{json .HostConfig.LogConfig.Config}}' \
  "$CID"
```

## 8. Host-wide default logging configuration

`daemon.local.example.json` contains the lesson example for making `local` the default driver with rotation.

Do not replace an existing daemon configuration blindly. Merge the logging keys into the current file, preserve existing Docker settings, back up the original file, and validate before restarting Docker.

Validation command:

```bash
sudo dockerd \
  --validate \
  --config-file=/etc/docker/daemon.json
```

Only after successful validation:

```bash
sudo systemctl restart docker
sudo systemctl is-active docker
docker info --format 'Default Logging Driver: {{.LoggingDriver}}'
```

The new default applies to newly created containers; existing containers keep their current logging configuration until they are recreated.

## Troubleshooting

Check all containers:

```bash
docker ps -a
```

Check recent timestamped logs:

```bash
docker logs --tail 100 -t CONTAINER_NAME
```

Check the logging driver:

```bash
docker inspect -f '{{.HostConfig.LogConfig.Type}}' CONTAINER_NAME
```

Check Docker service status and journal:

```bash
sudo systemctl status docker --no-pager -l
sudo journalctl -u docker -n 100 --no-pager
```

## Cleanup

Remove only the containers created by this lab:

```bash
docker rm -f \
  session61-log-demo \
  session61-rotate \
  session61-local \
  session61-file-only \
  session61-none \
  session61-default-test \
  session61-nonblocking \
  log-test \
  2>/dev/null || true

docker compose down
```

## Command cheat sheet

See:

`docs/DevOps_Docker_Logs_Log_Driver_Session_61_Commands_CheatSheet.txt`

# Session 60 — Log in Docker

Chapter 10 — Logging and Monitoring

This lab focuses on Docker container logging: stdout/stderr, `docker logs`, logging drivers, log rotation, and Docker daemon logs.

## Execution host

Run the lab on `DEV-1`.

## Repository files

- `README.md`: practical lab guide for Session 60.
- `examples/daemon-json-json-file.json`: example global `json-file` logging configuration with rotation.
- `examples/daemon-json-local.json`: example global `local` logging driver configuration.
- `docs/DevOps_Log_in_Docker_Session_60_Commands_CheatSheet.txt`: command cheat sheet for this lesson.

## 1. Check the default logging driver

~~~bash
docker info --format 'Default Logging Driver: {{.LoggingDriver}}'
~~~

Docker uses a logging driver to handle container stdout and stderr. The default driver is commonly `json-file`.

## 2. Create a logger container with json-file rotation

~~~bash
docker rm -f session60-logger 2>/dev/null || true

docker run -d \
  --name session60-logger \
  --log-driver json-file \
  --log-opt max-size=1m \
  --log-opt max-file=3 \
  alpine:3.20 \
  sh -c 'i=1; while true; do echo "INFO request=$i status=200"; echo "ERROR request=$i demo-error" >&2; i=$((i+1)); sleep 2; done'
~~~

Verify the container:

~~~bash
docker ps --filter name=session60-logger
~~~

## 3. Read and follow container logs

~~~bash
docker logs session60-logger
docker logs --tail 10 session60-logger
docker logs -f session60-logger
docker logs --timestamps --tail 10 session60-logger
docker logs --since 5m session60-logger
~~~

A useful troubleshooting form is:

~~~bash
docker logs \
  -f \
  --tail 100 \
  --timestamps \
  CONTAINER_NAME
~~~

## 4. File-only output vs stdout/stderr

Write a value directly into a file inside the container:

~~~bash
docker exec session60-logger \
  sh -c 'echo "FILE_ONLY_TEST" >> /tmp/app.log'

docker exec session60-logger cat /tmp/app.log
~~~

Then compare it with:

~~~bash
docker logs --tail 20 session60-logger
~~~

The file content is not automatically the same thing as the Docker-managed stdout/stderr log stream.

## 5. Inspect the logging configuration

~~~bash
docker inspect \
  -f 'Driver={{.HostConfig.LogConfig.Type}}' \
  session60-logger

docker inspect \
  -f 'Options={{json .HostConfig.LogConfig.Config}}' \
  session60-logger

docker inspect \
  -f 'LogPath={{.LogPath}}' \
  session60-logger
~~~

Do not manually edit Docker-managed log files under `/var/lib/docker/containers/`.

## 6. Test the local logging driver

~~~bash
docker rm -f session60-local 2>/dev/null || true

docker run -d \
  --name session60-local \
  --log-driver local \
  --log-opt max-size=5m \
  --log-opt max-file=3 \
  alpine:3.20 \
  sh -c 'i=1; while true; do echo "LOCAL-LOG request=$i"; i=$((i+1)); sleep 3; done'
~~~

Verify the driver and logs:

~~~bash
docker inspect \
  -f '{{.HostConfig.LogConfig.Type}}' \
  session60-local

docker logs --tail 5 session60-local
~~~

## 7. Global Docker logging configuration examples

Before changing `/etc/docker/daemon.json`, inspect the existing file first:

~~~bash
sudo test -f /etc/docker/daemon.json \
  && sudo cat /etc/docker/daemon.json \
  || echo "daemon.json does not exist"
~~~

The `examples/` directory contains the two configurations demonstrated in this lesson.

Validate a Docker daemon configuration before restarting Docker:

~~~bash
sudo dockerd \
  --validate \
  --config-file=/etc/docker/daemon.json
~~~

Then, only when the configuration is ready and a Docker restart is appropriate:

~~~bash
sudo systemctl restart docker
~~~

Check the default driver again:

~~~bash
docker info --format 'Default Logging Driver: {{.LoggingDriver}}'
~~~

Changing the daemon default affects newly created containers, not existing containers.

## 8. Docker daemon logs

Container logs and Docker daemon logs are different.

Container log example:

~~~bash
docker logs nginx
~~~

Docker daemon log examples on a systemd-based Linux host:

~~~bash
sudo journalctl \
  -u docker.service \
  --since "10 minutes ago"

sudo journalctl -fu docker.service
~~~

## Final verification

~~~bash
docker info --format 'Default Logging Driver: {{.LoggingDriver}}'

docker inspect \
  -f 'Driver={{.HostConfig.LogConfig.Type}} Options={{json .HostConfig.LogConfig.Config}}' \
  session60-logger

docker logs \
  --timestamps \
  --tail 6 \
  session60-logger

docker inspect \
  -f 'Driver={{.HostConfig.LogConfig.Type}} Options={{json .HostConfig.LogConfig.Config}}' \
  session60-local
~~~

## Commands cheat sheet

See:

`docs/DevOps_Log_in_Docker_Session_60_Commands_CheatSheet.txt`

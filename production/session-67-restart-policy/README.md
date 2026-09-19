# Session 67 — Docker Restart Policy

A hands-on Docker Production lab for understanding and testing container restart policies.

This session focuses on the difference between `no`, `on-failure`, `always`, and `unless-stopped`, and shows how Docker behaves after an application crash, a manual stop, and daemon or host restarts.

## Lab goals

- Inspect the restart policy of an existing container.
- Change a restart policy without recreating the container.
- Test `on-failure:3` with an intentional non-zero exit.
- Test `unless-stopped` with Nginx.
- Compare an unexpected container exit with an administrator-initiated stop.
- Inspect restart count, exit code, logs, and container state.

## Project structure

```text
session-67-restart-policy/
├── compose.yaml
├── DevOps_Docker_Restart_Policy_Session_67_Commands_CheatSheet.txt
└── README.md
```

## Requirements

- Docker Engine
- Docker Compose plugin
- Port `8089` available on the Docker host

## 1. Run the Nginx restart-policy lab

```bash
docker run -d \
  --name rp-nginx \
  --restart=unless-stopped \
  -p 8089:80 \
  nginx:alpine
```

Verify the configured policy:

```bash
docker inspect -f '{{.HostConfig.RestartPolicy.Name}}' rp-nginx
```

Expected value:

```text
unless-stopped
```

## 2. Simulate an unexpected container termination

```bash
docker kill rp-nginx
```

Check that Docker started the container again:

```bash
docker ps
docker inspect -f '{{.RestartCount}}' rp-nginx
```

The restart count should increase after Docker restarts the container.

## 3. Compare with a manual stop

```bash
docker stop rp-nginx
docker ps -a
```

With `unless-stopped`, a manual stop is treated as an administrator decision and the container stays stopped.

Start it again when needed:

```bash
docker start rp-nginx
```

## 4. Test `on-failure:3`

Create a container that intentionally exits with code `1` after 12 seconds:

```bash
docker run -d \
  --name rp-test \
  --restart=on-failure:3 \
  alpine \
  sh -c 'sleep 12; exit 1'
```

Inspect the result:

```bash
docker ps -a
docker inspect -f '{{.RestartCount}}' rp-test
docker inspect -f '{{json .HostConfig.RestartPolicy}}' rp-test
```

The container retries after failed exits and eventually remains stopped after the configured retry limit is reached.

## 5. Change restart policy on an existing container

You do not need to recreate a container just to change its restart policy.

```bash
docker update --restart=unless-stopped rp-nginx
```

Verify:

```bash
docker inspect -f '{{.HostConfig.RestartPolicy.Name}}' rp-nginx
```

## 6. Run the same lab with Docker Compose

Validate the Compose file:

```bash
docker compose config --quiet
```

Start both services:

```bash
docker compose up -d
```

Inspect them:

```bash
docker ps -a
docker inspect -f '{{.HostConfig.RestartPolicy.Name}}' rp-nginx
docker inspect -f '{{json .HostConfig.RestartPolicy}}' rp-test
```

## Troubleshooting

Check container logs:

```bash
docker logs --tail 100 rp-nginx
docker logs --tail 100 rp-test
```

Inspect restart count:

```bash
docker inspect -f '{{.RestartCount}}' rp-nginx
docker inspect -f '{{.RestartCount}}' rp-test
```

Inspect exit code and full state:

```bash
docker inspect -f '{{.State.ExitCode}}' rp-test
docker inspect -f '{{json .State}}' rp-test
```

## Key production point

Restart policy is a container lifecycle mechanism, not a health-check replacement.

A container can be `unhealthy` while its main process is still running. Docker restart policy reacts to container exit behavior; it does not automatically restart a container only because a health check reports `unhealthy`.

For long-running standalone Docker services, `unless-stopped` is often useful because it recovers from unexpected exits while preserving an intentional administrator stop.

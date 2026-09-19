# Session 66 — Docker Healthcheck

A hands-on Docker production lab for understanding the difference between a container that is merely running and an application that is actually healthy.

## Learning goals

- Understand why `running` does not always mean `healthy`.
- Define Docker health checks with `HEALTHCHECK`.
- Configure health checks with Docker Compose.
- Inspect `starting`, `healthy`, and `unhealthy` states.
- Troubleshoot a failing health check.
- Understand that Docker Engine does not automatically restart a container only because it becomes `unhealthy`.

## Project structure

```text
session-66-healthcheck/
├── Dockerfile
├── compose.yaml
├── DevOps_Docker_Healthcheck_Session_66_Commands_CheatSheet.txt
└── README.md
```

## Healthcheck model

```text
Container running
      |
      v
Healthcheck command
      |
      +--> success --> healthy
      |
      +--> repeated failures --> unhealthy
```

A container can remain in the `running` state while its application is `unhealthy`.

## 1. Build the image

Run from this lab directory:

```bash
docker build -t my-nginx:1.0 .
```

## 2. Run the container

```bash
docker run -d \
  --name my-nginx \
  -p 8080:80 \
  my-nginx:1.0
```

Check the container:

```bash
docker ps
```

After the health check succeeds, the status should include:

```text
(healthy)
```

## 3. Inspect only the health status

```bash
docker inspect --format='{{.State.Health.Status}}' my-nginx
```

Expected healthy state:

```text
healthy
```

## 4. Inspect complete health information

```bash
docker inspect --format='{{json .State.Health}}' my-nginx
```

This output includes the health status, exit codes, timestamps, and command output.

## 5. Docker Compose

Start the same lab with Compose:

```bash
docker compose up -d
```

Check the service:

```bash
docker compose ps
```

Inspect the health status directly:

```bash
docker inspect --format='{{.State.Health.Status}}' healthcheck-demo
```

## 6. Manual health probe

Enter the container:

```bash
docker exec -it healthcheck-demo sh
```

Run the same probe manually:

```bash
wget -q --spider http://127.0.0.1/
```

Check its exit code:

```bash
echo $?
```

An exit code of `0` means the probe succeeded.

## Healthcheck configuration

The Dockerfile uses:

```dockerfile
HEALTHCHECK --interval=30s \
            --timeout=5s \
            --start-period=10s \
            --retries=3 \
  CMD wget -q --spider http://127.0.0.1/ || exit 1
```

The main options are:

- `--interval`: how often Docker runs the probe.
- `--timeout`: maximum allowed time for one probe.
- `--start-period`: startup grace period for the application.
- `--retries`: number of consecutive failures required before Docker reports `unhealthy`.

## Important production note

Docker Engine uses the health check to report application health. A container becoming `unhealthy` does not, by itself, guarantee an automatic restart. Restart policies mainly react to the container process exiting, while orchestration or monitoring systems can use health information for higher-level recovery actions.

## Port reminder

A health check runs inside the container network namespace.

If the host mapping is:

```text
8080:80
```

the health check normally tests the container-side port:

```text
80
```

not the host-side port:

```text
8080
```

## Troubleshooting order

1. Confirm the container is running.
2. Inspect the configured healthcheck command.
3. Confirm `wget` or `curl` exists inside the image.
4. Confirm the application is listening on the expected internal port.
5. Verify the endpoint path.
6. Check timeout, start period, and retry values.
7. Inspect `.State.Health` for recent probe failures.

## Cleanup

```bash
docker compose down
```

If you used the standalone `docker run` example instead:

```bash
docker rm -f my-nginx
```

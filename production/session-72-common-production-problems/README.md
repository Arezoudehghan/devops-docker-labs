# Session 72 — Common Docker Production Problems

A practical Docker Production troubleshooting runbook for diagnosing common container, host, storage, network, health, restart, and deployment problems.

The main troubleshooting rule for this session is:

```text
Evidence → Diagnose → Root Cause → Fix → Verify
```

Do not restart a container before collecting the evidence that can explain why it failed.

## Lab environment

This session is designed for the deployment host:

```text
DEV-2
Docker Deploy Server
```

The examples use a container named `app` and common production ports such as `8088`.

## Project structure

```text
session-72-common-production-problems/
├── DevOps_Docker_Production_Common_Problems_Session_72_Commands_CheatSheet.txt
└── README.md
```

## Command cheat sheet

The complete command reference for this session is available in:

[DevOps_Docker_Production_Common_Problems_Session_72_Commands_CheatSheet.txt](DevOps_Docker_Production_Common_Problems_Session_72_Commands_CheatSheet.txt)

## First incident checks

Start by checking container state, exit information, logs, and recent Docker events:

```bash
docker ps
docker ps -a
docker inspect --format='status={{.State.Status}} exit={{.State.ExitCode}} oom={{.State.OOMKilled}} error={{.State.Error}}' app
docker logs --tail 100 app
docker events --since 10m
```

The goal is to collect evidence before changing the container state.

## 1. Container exited

Check the logs and exit code:

```bash
docker logs --tail 100 app
docker inspect --format='{{.State.ExitCode}}' app
```

For possible out-of-memory termination, verify the OOM flag:

```bash
docker inspect --format='{{.State.OOMKilled}}' app
```

An exit code of `137` means the process was killed with `SIGKILL`. OOM is a common cause, but the exit code alone does not prove an OOM event.

## 2. Restart loop

```bash
docker ps -a
docker logs --tail 200 app
docker inspect --format='{{.HostConfig.RestartPolicy.Name}}' app
```

A restart policy can improve availability after a crash, but it does not fix an application configuration or runtime failure.

## 3. OOMKilled and memory pressure

```bash
docker stats
docker stats --no-stream
docker inspect --format='{{.HostConfig.Memory}}' app
free -h
sudo dmesg -T | grep -i -E 'out of memory|killed process'
```

Example container with CPU and memory limits:

```bash
docker run -d \
  --name app \
  --memory=512m \
  --cpus=1.0 \
  myapp:1.4
```

## 4. High CPU usage

```bash
docker stats --no-stream
docker top app
top
htop
```

High CPU can be caused by legitimate traffic, an application loop, or an unsuitable resource limit.

## 5. Disk full

```bash
df -h
docker system df
docker system df -v
```

A destructive cleanup command used in this lesson is:

```bash
docker system prune -a --volumes
```

**Warning:** do not run this blindly in production. Review images, containers, build cache, and volumes before removing data.

## 6. Logs consuming disk space

```bash
docker inspect --format='{{.HostConfig.LogConfig.Type}}' app
docker logs --tail 100 app
```

Compose logging with rotation:

```yaml
services:
  app:
    image: myapp:1.4
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
```

Using the local logging driver:

```yaml
services:
  app:
    image: myapp:1.4
    logging:
      driver: local
```

## 7. Port conflict

```bash
docker ps --format 'table {{.Names}}\t{{.Ports}}'
sudo ss -ltnp | grep :8088
docker port app
```

Find the process or container that owns the port before changing the application port.

## 8. Container is up but application is unavailable

```bash
docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no-healthcheck{{end}}' app
```

Example Dockerfile health check:

```dockerfile
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD curl -f http://localhost:8000/health || exit 1
```

```text
Running ≠ Healthy ≠ Available ≠ Performant
```

## 9. DNS or container-to-container communication problem

```bash
docker network ls
docker inspect --format='{{json .NetworkSettings.Networks}}' app
docker network inspect my-network
docker exec app getent hosts db
```

Inside a container, `localhost` means that same container. Use the service/container name such as `db` for communication over the Docker network.

## 10. Volume permission problem

```bash
docker inspect --format='{{range .Mounts}}{{println .Type .Source "->" .Destination "RW=" .RW}}{{end}}' app
docker exec app id
ls -ld /path/to/data
docker exec app sh -c 'touch /data/.write-test && rm /data/.write-test'
```

The following command appeared as an incorrect-practice example in the lesson:

```bash
chmod -R 777 /data
```

Do not use broad `777` permissions as the default fix. Diagnose UID, GID, ownership, and required permissions instead.

## 11. Container does not return after host reboot

```bash
systemctl status docker
docker ps -a
docker inspect --format='{{.HostConfig.RestartPolicy.Name}}' app
docker update --restart=unless-stopped app
```

## 12. Application starts before the database is ready

```yaml
services:

  web:
    image: myapp:1.4
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:17
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
```

## 13. Wrong application version after deployment

```bash
docker inspect --format='image-name={{.Config.Image}} image-id={{.Image}}' app
docker image ls
```

Prefer exact version or build tags over relying only on a moving `latest` tag.

## Production troubleshooting runbook

```bash
docker ps -a
docker inspect --format='status={{.State.Status}} exit={{.State.ExitCode}} oom={{.State.OOMKilled}} error={{.State.Error}}' app
docker logs --tail 200 app
docker stats --no-stream
free -h
df -h
docker system df
sudo ss -ltnp
docker network inspect my-network
docker inspect app
```

After finding and fixing the root cause, restart only when needed:

```bash
docker restart app
```

Then verify:

```bash
docker ps
docker logs --tail 50 app
```

## Key production lesson

A production troubleshooting workflow should preserve evidence, identify the real root cause, apply the smallest safe fix, and verify the application from the user-facing path instead of stopping at `docker ps`.

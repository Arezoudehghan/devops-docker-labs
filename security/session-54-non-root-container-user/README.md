# Session 54 — Run Docker Containers as a Non-Root User

This lab demonstrates how to reduce container privileges by running the application with a non-root UID/GID.

## Learning goals

- Observe the default root identity inside a container.
- Set a fixed runtime identity with `USER 10001:10001`.
- Preserve application file ownership with `COPY --chown`.
- Verify the effective UID/GID at runtime.
- Confirm that the application cannot write to `/root`.
- Understand bind-mount permission behavior with numeric UID/GID.
- Compare Dockerfile `USER` with runtime `--user`.

## Lab files

- `Dockerfile` — builds the non-root Python HTTP server image.
- `index.html` — simple web page served by the container.
- `compose.yaml` — optional Compose runtime definition.
- `DevOps_Docker_Non_Root_User_Session_54_Commands_CheatSheet.txt` — command cheat sheet for this session.

## Build

```bash
docker build \
  -t session54-app:1.0 \
  .
```

Verify the configured user:

```bash
docker image inspect session54-app:1.0 \
  --format 'User={{.Config.User}} WorkDir={{.Config.WorkingDir}} Ports={{json .Config.ExposedPorts}}'
```

Expected user:

```text
10001:10001
```

## Run

```bash
docker run -d \
  --name session54-nonroot \
  -p 127.0.0.1:18054:8000 \
  session54-app:1.0
```

Test the application:

```bash
curl -sS http://127.0.0.1:18054/
```

## Verify the non-root identity

```bash
docker exec session54-nonroot id
```

The UID and GID should be `10001`, not `0`.

Confirm that writing under `/root` is blocked:

```bash
docker exec session54-nonroot \
  sh -c 'touch /root/security-test'
```

The command should fail with a permission error.

Confirm that the application can write under its own directory:

```bash
docker exec session54-nonroot \
  sh -c 'echo "created by non-root" > /app/ok.txt && ls -ln /app/ok.txt'
```

## Runtime user override

Dockerfile `USER` defines the image default, but `docker run --user` can override it.

```bash
docker run --rm \
  --user 20000:20000 \
  python:3.12-slim \
  id
```

This also means a caller with Docker access can explicitly override the image back to UID/GID 0:

```bash
docker run --rm \
  --user 0:0 \
  session54-app:1.0 \
  id
```

## Bind-mount permission lab

Create the host directory with root ownership:

```bash
mkdir -p data
rm -f data/from-container.txt
chown root:root data
chmod 755 data
ls -ldn data
```

The non-root container should not be able to write into it:

```bash
docker run --rm \
  --mount type=bind,src="$PWD/data",dst=/data \
  session54-app:1.0 \
  sh -c 'id && touch /data/from-container.txt'
```

Give the directory the same UID/GID as the container:

```bash
chown 10001:10001 data
```

Run the test again:

```bash
docker run --rm \
  --mount type=bind,src="$PWD/data",dst=/data \
  session54-app:1.0 \
  sh -c 'id && touch /data/from-container.txt && ls -ln /data/from-container.txt'
```

## Docker Compose

Build the image first, then start the Compose service:

```bash
docker compose up -d
```

The Compose file explicitly keeps the runtime identity at `10001:10001`.

## Key security point

Running the application as a non-root user follows the least-privilege principle. It is an important hardening control, but it is only one security layer and does not replace other Docker security controls.

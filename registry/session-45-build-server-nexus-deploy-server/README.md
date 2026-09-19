# Session 45 — Build Server → Nexus → Deploy Server

Chapter 7: Registry and Nexus

This lab demonstrates a complete image-delivery workflow where an image is built and tested on a build server, pushed to a Nexus Docker hosted repository, pulled by a deploy server, and then run as a container.

```text
DEV-1 (Build Server)
        |
        | docker build / test / tag / push
        v
Nexus Docker Registry :8085
        |
        | docker pull
        v
DEV-2 (Deploy Server)
        |
        | docker run
        v
Session 45 Web App :18045
```

## Lab environment

| Host | Documentation address | Role |
|---|---|---|
| `DEV-1` | `192.0.2.10` | Docker build host and Nexus Registry host |
| `DEV-2` | `192.0.2.11` | Docker deploy host |
| Nexus Docker connector | `192.0.2.10:8085` | Docker hosted Registry endpoint |

> The repository documentation uses example addresses from `192.0.2.0/24`. Replace them with the addresses assigned to your own lab VMs.

## Files

- `Dockerfile` — builds the Session 45 web image.
- `index.html` — static test application served by Python.
- `docs/DevOps_Build_Server_Nexus_Deploy_Server_Session_45_Commands_CheatSheet.txt` — complete command Cheat Sheet extracted from the lesson.

## 1. Build the image on DEV-1

```bash
docker build -t session45-web:1.0 .
docker image ls session45-web
```

## 2. Test the image before publishing

```bash
docker run -d \
  --name session45-build-test \
  -p 18045:8000 \
  session45-web:1.0

curl -fsS http://127.0.0.1:18045/
docker inspect session45-build-test --format '{{json .State.Health}}'
docker rm -f session45-build-test
```

## 3. Tag and push to Nexus

Set the Registry address for your own environment:

```bash
export NEXUS_REGISTRY='192.0.2.10:8085'
export IMAGE_NAME='session45-web'
export IMAGE_TAG='1.0'
export REMOTE_IMAGE="${NEXUS_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
```

Authenticate without placing the password directly in the command history:

```bash
read -rp 'Nexus username: ' NEXUS_USER
read -rsp 'Nexus password: ' NEXUS_PASS
echo

printf '%s\n' "$NEXUS_PASS" | \
docker login "$NEXUS_REGISTRY" \
  --username "$NEXUS_USER" \
  --password-stdin

unset NEXUS_PASS
```

Tag and push:

```bash
docker tag session45-web:1.0 "$REMOTE_IMAGE"
docker push "$REMOTE_IMAGE"
```

## 4. Pull on DEV-2

```bash
export NEXUS_REGISTRY='192.0.2.10:8085'
export IMAGE_NAME='session45-web'
export IMAGE_TAG='1.0'
export REMOTE_IMAGE="${NEXUS_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"

docker pull "$REMOTE_IMAGE"
```

## 5. Run the deployed container

```bash
docker run -d \
  --name session45-web \
  --restart unless-stopped \
  -p 18045:8000 \
  "$REMOTE_IMAGE"
```

Verify:

```bash
docker ps --filter name=session45-web
docker inspect session45-web --format '{{json .State.Health}}'
curl -fsS http://127.0.0.1:18045/
```

## Key workflow

```text
Source -> Build -> Test -> Tag -> Push -> Nexus -> Pull -> Run
```

The deploy server does not need the source code or Dockerfile. It consumes the tested image from the Registry.

## Security note

The original training lab uses an HTTP Nexus Docker connector. Use TLS, least-privilege Registry accounts, and organization-approved secrets handling for production environments.

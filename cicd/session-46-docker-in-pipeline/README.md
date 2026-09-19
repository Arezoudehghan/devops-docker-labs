# Session 46 — Docker in the CI/CD Pipeline

Chapter 8: Docker in CI/CD

This lab demonstrates the role of Docker in a CI/CD workflow: source code is built into an image, the image is tested, pushed to a Registry, pulled by the deploy server, and then run as the deployable application artifact.

```text
GitLab / Runner on DEV-1
        |
        | docker build
        v
Docker Image
        |
        | test container
        v
Nexus Docker Registry :8085
        |
        | docker pull
        v
DEV-2 (Deploy Server)
        |
        | docker run
        v
Session 46 Web App :18046
```

## Lab environment

| Host | Documentation address | Role |
|---|---|---|
| `DEV-1` | `192.0.2.10` | GitLab Runner, Docker build host, and Nexus Registry host |
| `DEV-2` | `192.0.2.11` | Docker deploy host |
| Nexus Docker connector | `192.0.2.10:8085` | Docker hosted Registry endpoint |

> The repository documentation uses example addresses from `192.0.2.0/24`. Replace them with the addresses assigned to your own lab VMs.

## Files

- `Dockerfile` — builds the Session 46 Nginx image and defines its health check.
- `index.html` — static test application served by Nginx.
- `docs/DevOps_Docker_in_Pipeline_Session_46_Commands_CheatSheet.txt` — complete command Cheat Sheet extracted from this lesson.

## 1. Prepare the lab on DEV-1

```bash
mkdir -p /opt/docker-labs/session46
cd /opt/docker-labs/session46
```

Place `Dockerfile` and `index.html` from this repository in that directory.

## 2. Build the application image

```bash
docker build -t cicd-session46-app:local .
docker image ls cicd-session46-app
```

At this point, Docker has converted the source files and Dockerfile into a deployable image artifact.

## 3. Test the same image before publishing

```bash
docker run -d \
  --name s46-test \
  -p 18046:80 \
  cicd-session46-app:local

sleep 7

docker inspect \
  --format='{{.State.Health.Status}}' \
  s46-test

curl -f http://127.0.0.1:18046/
```

Remove only the temporary test container:

```bash
docker rm -f s46-test
```

The image remains available for tagging and publishing.

## 4. Tag the image for Nexus

Set the Registry variables for your own environment:

```bash
export REGISTRY=192.0.2.10:8085
export IMAGE=cicd-session46-app
export TAG=s46-v1
```

Tag the exact image that was tested:

```bash
docker tag \
  ${IMAGE}:local \
  ${REGISTRY}/${IMAGE}:${TAG}
```

## 5. Push the tested image to Nexus

Authenticate to your Registry first if required, then push:

```bash
docker push \
  ${REGISTRY}/${IMAGE}:${TAG}
```

This makes the tested image available to the deploy server without copying the source code.

## 6. Pull the image on DEV-2

```bash
docker pull \
  192.0.2.10:8085/cicd-session46-app:s46-v1
```

DEV-2 does not need the source code or Dockerfile. It consumes the already built image from the Registry.

## 7. Deploy the image

Remove an old container with the same name if it exists:

```bash
docker rm -f cicd-session46-app 2>/dev/null || true
```

Run the published image:

```bash
docker run -d \
  --name cicd-session46-app \
  --restart unless-stopped \
  -p 18046:80 \
  192.0.2.10:8085/cicd-session46-app:s46-v1
```

Verify:

```bash
docker ps \
  --filter name=cicd-session46-app

curl -f http://127.0.0.1:18046/
```

## CI/CD role of Docker

The workflow demonstrated by this lab is:

```text
Source Code
   |
   v
Docker Build
   |
   v
Versioned Image
   |
   v
Test the Image
   |
   v
Push to Registry
   |
   v
Pull on Deploy Server
   |
   v
Run the Same Image
```

The important principle is to build the artifact once, test that artifact, store it in the Registry, and deploy the same artifact.

## GitLab Runner note

In the current learning environment, GitLab Runner uses the Shell executor on DEV-1. A CI job that runs `docker build` therefore uses the Docker CLI and Docker Engine installed on DEV-1.

Later CI/CD sessions can automate the same manual flow demonstrated here inside `.gitlab-ci.yml`.

## Security note

Do not commit Registry passwords, GitLab tokens, or other secrets to the repository. Use CI/CD variables or an approved secrets-management mechanism, and use TLS for production Registry traffic.

# Session 33 — Docker Compose `service`, `image`, `build`, and `ports`

Chapter 6 of the DevOps course continues Docker Compose with the core service definition fields used to select or build images and publish container ports.

## Lab environment

- Host: `DEV-1`
- IP: `192.168.94.90`
- Compose project: `session33`
- Service 1: `web-image`
- Service 2: `web-build`
- Host ports: `18033`, `18034`
- Container port: `80`

## Project structure

```text
session-33-service-image-build-ports/
├── app/
│   ├── Dockerfile
│   └── index.html
├── compose.yaml
├── README.md
└── docs/
    └── DevOps_Docker_Compose_Service_Image_Build_Ports_Session_33_Commands_CheatSheet.txt
```

## Compose file

```yaml
name: session33

services:

  web-image:
    image: nginx:alpine
    ports:
      - "18033:80"

  web-build:
    build:
      context: ./app
      dockerfile: Dockerfile
    ports:
      - "18034:80"
```

## Application Dockerfile

```dockerfile
FROM nginx:alpine

COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80
```

## Run the lab

Check Docker and Compose:

```bash
docker --version
docker compose version
```

Check whether the host ports are already in use:

```bash
sudo ss -lntp | grep -E ':(18033|18034)\b' || true
```

Validate the Compose file:

```bash
docker compose config --quiet
```

Display the resolved Compose configuration:

```bash
docker compose config
```

List the defined services:

```bash
docker compose config --services
```

Pull the image used by `web-image`:

```bash
docker compose pull web-image
```

Build the image used by `web-build`:

```bash
docker compose build web-build
```

Start both services in detached mode:

```bash
docker compose up -d
```

Check the Compose project containers:

```bash
docker compose ps
```

Test the image-based service:

```bash
curl -I http://127.0.0.1:18033
curl http://127.0.0.1:18033
```

Test the locally built service:

```bash
curl http://127.0.0.1:18034
```

Test from another host such as `DEV-2`:

```bash
curl http://192.168.94.90:18033
curl http://192.168.94.90:18034
```

View service logs:

```bash
docker compose logs web-image
docker compose logs web-build
docker compose logs -f web-build
```

After changing `app/index.html`, rebuild and recreate only `web-build`:

```bash
docker compose up -d --build web-build
```

Stop and remove the Compose project containers and default network:

```bash
docker compose down
```

## Key concepts

- `services` defines the logical application services managed by Compose.
- `image` selects a prebuilt container image.
- `build` tells Compose how to build an image from source and a Dockerfile.
- `ports` publishes a host port to a container port using `HOST_PORT:CONTAINER_PORT`.
- `EXPOSE` documents a container port but does not publish it on the Docker host.

## Commands cheat sheet

The complete commands cheat sheet for this lesson is stored at:

`docs/DevOps_Docker_Compose_Service_Image_Build_Ports_Session_33_Commands_CheatSheet.txt`

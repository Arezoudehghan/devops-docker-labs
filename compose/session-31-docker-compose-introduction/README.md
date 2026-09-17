# Session 31 — Docker Compose Introduction

Chapter 6 of the DevOps course introduces Docker Compose and the basic lifecycle of a Compose project.

## Lab environment

- Host: `DEV-1`
- IP: `192.168.94.90`
- Service: Nginx
- Host port: `18031`
- Container port: `80`

## Project structure

```text
session-31-docker-compose-introduction/
├── compose.yaml
├── README.md
└── docs/
    └── DevOps_Docker_Compose_Introduction_Session_31_Commands_CheatSheet.txt
```

## Compose file

```yaml
services:
  web:
    image: nginx:alpine
    ports:
      - "18031:80"
```

## Run the lab

Check Docker and Compose:

```bash
docker --version
docker compose version
```

Check whether port `18031` is already in use:

```bash
sudo ss -lntp | grep ':18031' || true
```

Validate the Compose file:

```bash
docker compose config -q
```

Start the service:

```bash
docker compose up -d
```

Check the project containers:

```bash
docker compose ps
```

Test Nginx locally:

```bash
curl -I http://127.0.0.1:18031
```

Test from another system in the lab network:

```bash
curl -I http://192.168.94.90:18031
```

View logs:

```bash
docker compose logs --tail=20
```

Stop and remove the Compose project containers and network:

```bash
docker compose down
```

## Commands cheat sheet

The complete commands cheat sheet for this lesson is stored at:

`docs/DevOps_Docker_Compose_Introduction_Session_31_Commands_CheatSheet.txt`

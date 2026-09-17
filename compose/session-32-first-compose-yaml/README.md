# Session 32 — First `compose.yaml`

Chapter 6 of the DevOps course introduces the first practical Docker Compose file and the basic workflow for validating, starting, checking, troubleshooting, and removing a Compose project.

## Lab environment

- Host: `DEV-1`
- IP: `192.168.94.90`
- Service: Nginx
- Host port: `8080`
- Container port: `80`
- Restart policy: `unless-stopped`

## Project structure

```text
session-32-first-compose-yaml/
├── compose.yaml
├── README.md
└── docs/
    └── DevOps_First_compose_yaml_Session_32_Commands_CheatSheet.txt
```

## Compose file

```yaml
services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    restart: unless-stopped
```

## Run the lab

Check Docker and Compose:

```bash
docker version
docker compose version
```

Check whether host port `8080` is already in use:

```bash
ss -lntp | grep ':8080 ' || true
```

Validate the Compose file:

```bash
docker compose config -q
```

Display the resolved Compose configuration:

```bash
docker compose config
```

Start the service in detached mode:

```bash
docker compose up -d
```

Check the Compose project containers:

```bash
docker compose ps
```

Test Nginx locally:

```bash
curl -I http://localhost:8080
```

View service logs:

```bash
docker compose logs web
```

Follow live logs:

```bash
docker compose logs -f web
```

Open a shell inside the running `web` service:

```bash
docker compose exec web sh
```

Inspect the Compose-created network:

```bash
docker network ls
docker network inspect compose-session32_default
```

Stop the project without removing its containers:

```bash
docker compose stop
```

Start the existing stopped containers again:

```bash
docker compose start
```

Stop and remove the Compose project containers and default network:

```bash
docker compose down
```

## Troubleshooting

Validate YAML and Compose syntax before starting the project:

```bash
docker compose config
```

Check whether port `8080` is already allocated:

```bash
ss -lntp | grep ':8080 '
docker ps --format 'table {{.Names}}\t{{.Ports}}'
```

Run Compose explicitly with this file when needed:

```bash
docker compose -f compose.yaml up -d
```

## Commands cheat sheet

The complete commands cheat sheet for this lesson is stored at:

`docs/DevOps_First_compose_yaml_Session_32_Commands_CheatSheet.txt`

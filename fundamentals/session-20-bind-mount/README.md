# Session 20 — Docker Bind Mount

Chapter 4 — Volume and Data Persistence

This lab demonstrates how a host path can be mounted directly into a Docker container with a bind mount.

## Project structure

```text
session-20-bind-mount/
├── README.md
├── compose.yaml
├── html/
│   └── index.html
└── DevOps_Bind_Mount_Session_20_Commands_CheatSheet.txt
```

## Run the lab with Docker Compose

```bash
docker compose up -d
```

Verify the page:

```bash
curl http://localhost:8080
```

The Nginx container serves `./html/index.html` through this read-only bind mount:

```text
./html  --->  /usr/share/nginx/html:ro
```

Edit `html/index.html` on the host and run the curl command again. The container sees the change immediately without rebuilding the image.

## Inspect the mount

```bash
docker compose ps
docker inspect $(docker compose ps -q web) --format '{{json .Mounts}}'
```

## Cleanup

```bash
docker compose down
```

## Commands Cheat Sheet

See `DevOps_Bind_Mount_Session_20_Commands_CheatSheet.txt` for the commands used in Session 20 with beginner-friendly English explanations of options and shell operators.

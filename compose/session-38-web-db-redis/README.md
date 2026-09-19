# Session 38 — Web + PostgreSQL + Redis

A Docker Compose lab with three services:

- `web`: Flask application served by Gunicorn
- `db`: PostgreSQL with a persistent named volume
- `redis`: Redis used as a disposable cache/counter

Only the web service publishes a host port. PostgreSQL and Redis are reachable only through the Compose network.

## Project structure

```text
.
├── .env.example
├── compose.yaml
├── db/
│   └── init.sql
└── web/
    ├── app.py
    ├── Dockerfile
    └── requirements.txt
```

## Run on DEV-1

Create the local environment file first:

```bash
cp .env.example .env
```

Edit `.env` and set a strong local PostgreSQL password. Do not commit the real `.env` file.

Validate the Compose configuration:

```bash
docker compose config -q
```

Build and start the stack:

```bash
docker compose up -d --build
```

Check service health:

```bash
docker compose ps
curl -i http://127.0.0.1:18038/health
```

Test the application:

```bash
curl -s http://127.0.0.1:18038/
```

## Persistence

PostgreSQL data is stored in the named volume `postgres_data`.

`docker compose down` keeps the named volume.

`docker compose down -v` removes the named volume and deletes the lab database data.

## Internal service discovery

The web service connects to:

- `db:5432`
- `redis:6379`

Use Compose service names instead of container IP addresses.

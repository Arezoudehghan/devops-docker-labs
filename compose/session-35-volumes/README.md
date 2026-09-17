# Session 35 — Volumes in Docker Compose

Chapter 6 of the DevOps course continues Docker Compose with persistent storage. This lab runs PostgreSQL with a named volume, writes test data, recreates the container, and verifies that the database data survives because it is stored outside the container lifecycle.

## Lab environment

- Host: `DEV-1`
- Documentation IP: `192.0.2.10`
- Compose project: `session35`
- Service: `db`
- Image: `postgres:16-alpine`
- Host port: `5433`
- Container port: `5432`
- PostgreSQL data path: `/var/lib/postgresql/data`
- Named volume: `compose-volumes-postgres-data`

## Project structure

```text
session-35-volumes/
├── .env.example
├── compose.yaml
├── README.md
└── docs/
    └── DevOps_Volumes_in_Compose_Session_35_Commands_CheatSheet.txt
```

## Compose file

```yaml
name: session35

services:
  db:
    image: postgres:16-alpine
    restart: unless-stopped

    environment:
      POSTGRES_DB: ${POSTGRES_DB:?POSTGRES_DB is required}
      POSTGRES_USER: ${POSTGRES_USER:?POSTGRES_USER is required}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is required}

    ports:
      - "${POSTGRES_HOST_PORT:-5433}:5432"

    volumes:
      - postgres_data:/var/lib/postgresql/data

    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $${POSTGRES_USER} -d $${POSTGRES_DB}"]
      interval: 5s
      timeout: 3s
      retries: 10
      start_period: 10s

volumes:
  postgres_data:
    name: compose-volumes-postgres-data
```

## Prepare the environment

Copy the safe template to a local `.env` file:

```bash
cp .env.example .env
```

Edit the local password before starting the lab:

```bash
nano .env
```

Restrict access to the local environment file:

```bash
chmod 600 .env
```

The repository `.gitignore` excludes `.env`, so the local password is not committed.

## Run the lab

Validate the Compose model first:

```bash
docker compose config --quiet
```

Pull the PostgreSQL image:

```bash
docker compose pull
```

Start the database in detached mode:

```bash
docker compose up -d
```

Check service status and health:

```bash
docker compose ps
```

Check PostgreSQL readiness from inside the service:

```bash
docker compose exec db sh -c 'pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"'
```

## Create test data

Create the test table:

```bash
docker compose exec db psql -U appuser -d appdb -c "CREATE TABLE IF NOT EXISTS students (id SERIAL PRIMARY KEY, name TEXT NOT NULL);"
```

Insert a row:

```bash
docker compose exec db psql -U appuser -d appdb -c "INSERT INTO students (name) VALUES ('student-01');"
```

Verify the stored data:

```bash
docker compose exec db psql -U appuser -d appdb -c "SELECT * FROM students;"
```

## Prove volume persistence

Remove the Compose containers and default network without deleting the named volume:

```bash
docker compose down
```

Confirm that the volume still exists:

```bash
docker volume inspect compose-volumes-postgres-data
```

Recreate the service:

```bash
docker compose up -d
```

Query the same table again:

```bash
docker compose exec db psql -U appuser -d appdb -c "SELECT * FROM students;"
```

The `student-01` row should still exist because the PostgreSQL data directory is mounted from the named volume.

## Inspect the mount

```bash
docker inspect "$(docker compose ps -q db)" --format '{{range .Mounts}}{{println .Type .Name .Source "->" .Destination}}{{end}}'
```

The destination should be `/var/lib/postgresql/data` and the volume name should be `compose-volumes-postgres-data`.

## Destructive cleanup

`docker compose down -v` removes the named volume as well as the Compose containers and network. Use it only when you intentionally want to delete the lab database data.

```bash
docker compose down -v
```

## Key concepts

- A named volume separates persistent data from the lifecycle of a container.
- The top-level `volumes` section defines the Compose volume.
- The service-level `volumes` entry mounts the volume into the container.
- `docker compose down` keeps named volumes by default.
- `docker compose down -v` removes named volumes managed by the project.
- A local named volume belongs to one Docker host and is not automatically shared with another VM.
- `external: true` is used when the volume lifecycle is managed outside the Compose project.

## Commands cheat sheet

The complete commands cheat sheet for this lesson is stored at:

`docs/DevOps_Volumes_in_Compose_Session_35_Commands_CheatSheet.txt`

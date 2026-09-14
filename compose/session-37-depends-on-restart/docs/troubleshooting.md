# Troubleshooting Guide

## Compose rejects `depends_on.restart`

### Cause

Docker Compose is older than `2.17.0`.

### Verification

```bash
docker compose version
```

### Resolution

Update the Docker Compose v2 plugin, then run configuration validation again.

## Database remains unhealthy

```bash
docker compose ps
docker compose logs --tail=100 db
docker inspect --format '{{.State.Health.Status}}' "$(docker compose ps -q db)"
```

Check environment values, disk capacity, volume permissions, and PostgreSQL startup errors. Increase `start_period` or `retries` only when the logs show that initialization legitimately needs more time.

## Adminer does not start

Adminer waits for the database because its dependency condition is `service_healthy`.

```bash
docker compose ps -a
docker compose logs db
docker compose logs adminer
```

Fix the database health failure first.

## Port 8086 is already in use

```bash
sudo ss -lntp | grep ':8086'
```

Change `ADMINER_PORT` in `.env`, validate, and recreate Adminer:

```bash
docker compose config --quiet
docker compose up -d
```

## Adminer cannot connect to PostgreSQL

Use `db` as the Server value. Do not use `localhost` or a container IP.

Verify PostgreSQL from inside the Compose network:

```bash
docker compose exec db sh -c 'pg_isready -h db -U "$POSTGRES_USER" -d "$POSTGRES_DB"'
```

## Password changed in `.env` but login still fails

PostgreSQL initialization variables are applied only when the data directory is empty. An existing `db_data` volume keeps the previously initialized credentials.

For a real system, change the password with PostgreSQL administration commands. For a disposable lab reset only, the following command deletes all database data:

```bash
docker compose down -v
docker compose up -d
```

## Adminer does not restart after `docker kill db`

This is expected. Runtime restarts controlled by Docker Engine do not trigger `depends_on.restart`. Use `docker compose restart db` to test the explicit Compose restart behavior.

## Configuration changes are not applied by `restart`

The `docker compose restart` command does not apply new environment, port, or image configuration. Reconcile and recreate the service instead:

```bash
docker compose up -d
```

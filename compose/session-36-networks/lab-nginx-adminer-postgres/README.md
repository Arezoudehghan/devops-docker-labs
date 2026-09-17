# Session 36 — Docker Compose Networks

This lab demonstrates Docker Compose network segmentation with three services:

- `proxy`: Nginx, connected only to `frontend_net`
- `adminer`: connected to both `frontend_net` and `backend_net`
- `db`: PostgreSQL, connected only to `backend_net`

## Architecture

Browser -> `DEV-2:8086` -> `proxy:80` -> `adminer:8080` -> `db:5432`

The `proxy` service cannot directly resolve or reach `db` because they do not share a network.

## Files

- `compose.yaml` — services, networks, healthchecks, volume, dependencies
- `.env.example` — safe environment-variable template
- `.gitignore` — prevents committing the real `.env`
- `nginx/default.conf` — reverse-proxy and health endpoint configuration

## Run

Copy `.env.example` to `.env`, replace `POSTGRES_PASSWORD=CHANGE_ME` with a local lab password, then validate and start the stack:

```bash
cp .env.example .env
docker compose config
docker compose pull
docker compose up -d
docker compose ps
```

Open:

`http://192.168.94.91:8086`

Adminer connection values:

- System: PostgreSQL
- Server: `db`
- Username: `labuser`
- Database: `labdb`
- Password: the value you placed in `.env`

## Network verification

```bash
docker network inspect session36-networks_frontend_net
docker network inspect session36-networks_backend_net
docker compose exec proxy wget -qO- http://adminer:8080 | head -n 5
docker compose exec proxy ping -c 1 db
docker compose exec adminer php -r 'echo "db=", gethostbyname("db"), PHP_EOL; echo "alias=", gethostbyname("postgres-db"), PHP_EOL;'
```

The `proxy -> db` test is expected to fail because the services do not share a Docker network.

## Cleanup

```bash
docker compose down
```

Use `docker compose down -v` only when you intentionally want to remove the PostgreSQL volume and its lab data.

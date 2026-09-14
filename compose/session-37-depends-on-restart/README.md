# Docker Compose `depends_on` and Restart Policy Lab

A focused lab that demonstrates health-aware startup, Docker Engine restart policies, and dependency-triggered restarts in Docker Compose.

## Architecture

```mermaid
flowchart LR
    Client["DEV-1 / 192.0.2.10"] -->|"HTTP :8086"| Adminer["Adminer / :8080"]
    Adminer -->|"backend / db:5432"| DB["PostgreSQL 17"]
    DB --> Volume["db_data"]
```

| Service | Image | Published port | Restart behavior |
|---|---|---|---|
| `db` | `postgres:17.11-alpine` | None | `unless-stopped` |
| `adminer` | `adminer:6.0.1` | `8086:8080` | `unless-stopped` |

## Lab environment

- Run the Compose project on `DEV-2` (`192.0.2.11`).
- Test Adminer from `DEV-1` (`192.0.2.10`).
- The course path is `/opt/docker-labs/session37`; the files also work from any cloned directory.
- Docker Compose `2.17.0` or newer is required for `depends_on.restart`.
- The addresses `192.0.2.10` and `192.0.2.11` are documentation examples; replace them with the addresses assigned to your own VMs.

## Learning objectives

- Compare short and long `depends_on` syntax.
- Wait for PostgreSQL to become healthy before starting Adminer.
- Compare service-level `restart: unless-stopped` with `depends_on.restart: true`.
- Verify the difference between a runtime crash and an explicit Compose restart.
- Keep PostgreSQL internal to the Docker network.

## Repository structure

```text
session-37-depends-on-restart/
├── .env.example
├── compose.yaml
├── README.md
├── SECURITY.md
├── docs/
│   ├── README.fa.md
│   ├── interview-questions.md
│   └── troubleshooting.md
└── scripts/
    ├── test-restart-behavior.sh
    └── verify.sh
```

No Dockerfile is required because the lab uses pinned official images.

## Quick start on DEV-2

Clone the course repository and enter this session:

```bash
git clone https://github.com/Arezoudehghan/docker-compose-labs.git
cd docker-compose-labs/session-37-depends-on-restart
```

Create the local environment file and protect it:

```bash
cp .env.example .env
chmod 600 .env
```

Change the example password in `.env`, then validate the configuration:

```bash
docker compose config --quiet
```

Pull and start the services:

```bash
docker compose pull
docker compose up -d
```

Verify the complete lab:

```bash
./scripts/verify.sh
```

## Access Adminer

Open the following address from `DEV-1`:

```text
http://192.0.2.11:8086
```

Use these values:

| Field | Value |
|---|---|
| System | `PostgreSQL` |
| Server | `db` |
| Username | Value of `POSTGRES_USER` |
| Password | Value of `POSTGRES_PASSWORD` |
| Database | Value of `POSTGRES_DB` |

Use the service name `db`, not `localhost` or a container IP address.

## Restart behavior test

Run the controlled test after both services are healthy:

```bash
./scripts/test-restart-behavior.sh
```

The script verifies two different behaviors:

1. `docker compose restart db` also restarts Adminer because `depends_on.restart` is `true`.
2. `docker kill` triggers the database runtime restart policy, but does not restart Adminer.

## Cleanup

Remove containers and the project network while preserving database data:

```bash
docker compose down
```

To permanently delete the PostgreSQL volume as well:

```bash
docker compose down -v
```

> **Warning:** The `-v` option permanently deletes the lab database data.

## Documentation

- [راهنمای فارسی سناریو](docs/README.fa.md)
- [Troubleshooting guide](docs/troubleshooting.md)
- [Interview questions](docs/interview-questions.md)
- [Security notes](SECURITY.md)

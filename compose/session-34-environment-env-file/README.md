# Session 34 — Docker Compose `environment` and `env_file`

Chapter 6 of the DevOps course continues Docker Compose with environment variables, `env_file`, `.env` interpolation, precedence, health checks, and environment-specific configuration.

## Lab environment

- `DEV-1`: `192.168.94.90` — development configuration — host port `18080`
- `DEV-2`: `192.168.94.91` — production-like configuration — host port `18081`
- Container application port: `8000`
- Compose project name: `compose-env-lab`

## Project structure

```text
session-34-environment-env-file/
├── app.py
├── compose.yaml
├── .env.example
├── env/
│   ├── common.env
│   ├── dev.env
│   └── prod.env
├── README.md
└── docs/
    └── DevOps_Docker_Compose_environment_env_file_Session_34_Commands_CheatSheet.txt
```

The repository ignores real `.env` files. Copy the safe template before running the lab:

```bash
cp .env.example .env
```

## DEV-1 configuration

The included `.env.example` represents the development configuration:

```text
APP_ENV=dev
APP_NAME=compose-env-dev
HOST_PORT=18080
```

Validate the resolved Compose configuration before starting containers:

```bash
docker compose config
docker compose config --environment
```

Start the lab:

```bash
docker compose up -d
```

Check container status and health:

```bash
docker compose ps
```

Test the application and health endpoint:

```bash
curl http://127.0.0.1:18080/
curl http://127.0.0.1:18080/health
```

Inspect the environment inside the container:

```bash
docker compose exec app env | sort
docker compose exec app env | grep -E 'APP_|LOG_LEVEL|FEATURE_X|COMPANY'
```

Expected DEV-1 application values include:

```text
APP_NAME=compose-env-dev
APP_ENVIRONMENT=development
LOG_LEVEL=DEBUG
FEATURE_X=true
COMPANY=DevOps-Lab
APP_PORT=8000
```

## DEV-2 configuration

On `DEV-2`, create the local `.env` file with:

```text
APP_ENV=prod
APP_NAME=compose-env-prod
HOST_PORT=18081
```

Then validate and start the same `compose.yaml`:

```bash
docker compose config
docker compose config --environment
docker compose up -d
```

Test the production-like configuration:

```bash
curl http://127.0.0.1:18081/
```

Expected DEV-2 application values include:

```text
APP_NAME=compose-env-prod
APP_ENVIRONMENT=production
LOG_LEVEL=WARNING
FEATURE_X=false
COMPANY=DevOps-Lab
APP_PORT=8000
```

## Environment precedence demonstrated by the lab

- `env/common.env` provides shared defaults.
- `env/dev.env` or `env/prod.env` overrides duplicate values from `common.env` because it is loaded later.
- The Compose `environment` section overrides values supplied by `env_file`.
- `.env` supplies values used for Compose interpolation such as `${APP_ENV}`, `${APP_NAME}`, and `${HOST_PORT}`.

## Health check

The health check runs inside the container against the internal application port:

```text
http://127.0.0.1:8000/health
```

View the current Compose service state:

```bash
docker compose ps
```

Inspect the health object directly:

```bash
docker inspect --format='{{json .State.Health}}' compose-env-lab-app-1
```

## Cleanup

Stop containers without removing them:

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

## Commands cheat sheet

The complete commands cheat sheet for this lesson is stored at:

`docs/DevOps_Docker_Compose_environment_env_file_Session_34_Commands_CheatSheet.txt`

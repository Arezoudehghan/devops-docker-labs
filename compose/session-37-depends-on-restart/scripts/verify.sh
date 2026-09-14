#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

if [[ ! -f .env ]]; then
  echo "ERROR: .env not found. Run: cp .env.example .env" >&2
  exit 1
fi

echo "[1/6] Validating Compose configuration"
docker compose config --quiet

echo "[2/6] Checking service status"
docker compose ps

db_id="$(docker compose ps -q db)"
adminer_id="$(docker compose ps -q adminer)"

if [[ -z "${db_id}" || -z "${adminer_id}" ]]; then
  echo "ERROR: db or adminer container is missing." >&2
  exit 1
fi

echo "[3/6] Waiting for PostgreSQL health"
for attempt in {1..30}; do
  db_health="$(docker inspect --format '{{.State.Health.Status}}' "${db_id}")"
  if [[ "${db_health}" == "healthy" ]]; then
    break
  fi
  if [[ "${attempt}" -eq 30 ]]; then
    echo "ERROR: PostgreSQL did not become healthy." >&2
    exit 1
  fi
  sleep 2
done

echo "[4/6] Verifying PostgreSQL readiness and Docker DNS"
docker compose exec -T db sh -c \
  'pg_isready -h db -U "$POSTGRES_USER" -d "$POSTGRES_DB"' >/dev/null

echo "[5/6] Verifying that PostgreSQL is not published on the host"
published_db_port="$(docker compose port db 5432 2>/dev/null || true)"
if [[ -n "${published_db_port}" ]]; then
  echo "ERROR: PostgreSQL port 5432 is unexpectedly published." >&2
  exit 1
fi

echo "[6/6] Verifying the Adminer HTTP endpoint"
adminer_port="$(sed -n 's/^ADMINER_PORT=//p' .env | tail -n 1)"
adminer_port="${adminer_port:-8086}"
for attempt in {1..30}; do
  if curl --fail --silent --show-error "http://127.0.0.1:${adminer_port}/" >/dev/null; then
    break
  fi
  if [[ "${attempt}" -eq 30 ]]; then
    echo "ERROR: Adminer HTTP endpoint did not become ready." >&2
    exit 1
  fi
  sleep 2
done

echo "PASS: Dependency health, database isolation, and Adminer access are correct."

#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

db_id="$(docker compose ps -q db)"
adminer_id="$(docker compose ps -q adminer)"

if [[ -z "${db_id}" || -z "${adminer_id}" ]]; then
  echo "ERROR: Start the lab first with: docker compose up -d" >&2
  exit 1
fi

wait_for_db_health() {
  local current_db_id
  current_db_id="$(docker compose ps -q db)"
  for attempt in {1..30}; do
    if [[ "$(docker inspect --format '{{.State.Health.Status}}' "${current_db_id}")" == "healthy" ]]; then
      return 0
    fi
    sleep 2
  done
  echo "ERROR: PostgreSQL did not return to healthy state." >&2
  return 1
}

echo "[1/4] Testing explicit Compose restart propagation"
adminer_started_before="$(docker inspect --format '{{.State.StartedAt}}' "${adminer_id}")"
docker compose restart db
adminer_id="$(docker compose ps -q adminer)"
adminer_started_after="$(docker inspect --format '{{.State.StartedAt}}' "${adminer_id}")"

if [[ "${adminer_started_before}" == "${adminer_started_after}" ]]; then
  echo "ERROR: Adminer was not restarted after the explicit Compose restart." >&2
  exit 1
fi

echo "[2/4] Waiting for PostgreSQL to become healthy"
wait_for_db_health

echo "[3/4] Testing Docker runtime restart behavior"
adminer_started_before="$(docker inspect --format '{{.State.StartedAt}}' "${adminer_id}")"
docker kill "$(docker compose ps -q db)" >/dev/null
wait_for_db_health
adminer_started_after="$(docker inspect --format '{{.State.StartedAt}}' "${adminer_id}")"

if [[ "${adminer_started_before}" != "${adminer_started_after}" ]]; then
  echo "ERROR: Adminer unexpectedly restarted after a Docker runtime restart." >&2
  exit 1
fi

echo "[4/4] Restart behavior is correct"
echo "PASS: Compose restart propagated to Adminer; runtime restart did not."

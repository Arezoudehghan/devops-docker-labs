#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

if [[ ! -f .env ]]; then
  echo "ERROR: .env not found. Run: cp .env.example .env" >&2
  exit 1
fi

host_port="$(sed -n 's/^HOST_PORT=//p' .env | tail -n 1)"
host_port="${host_port:-8086}"
base_url="http://127.0.0.1:${host_port}"

echo "[1/7] Validating Compose configuration"
docker compose --env-file .env config --quiet

echo "[2/7] Checking container status"
docker compose ps

echo "[3/7] Testing Nginx health endpoint"
test "$(curl --fail --silent "${base_url}/health")" = "OK"

echo "[4/7] Testing Frontend -> API -> Redis path"
api_response="$(curl --fail --silent "${base_url}/api/info")"
grep --quiet '"redis_response": "PONG"' <<<"${api_response}"

echo "[5/7] Verifying Frontend can resolve API"
docker compose exec -T frontend nslookup api >/dev/null

echo "[6/7] Verifying API can resolve Redis"
docker compose exec -T api python -c \
  "import socket; print(socket.gethostbyname('redis'))" >/dev/null

echo "[7/7] Verifying Frontend cannot resolve Redis"
if docker compose exec -T frontend nslookup redis >/dev/null 2>&1; then
  echo "ERROR: Frontend unexpectedly resolved Redis." >&2
  exit 1
fi

echo "PASS: Application connectivity and network isolation are correct."

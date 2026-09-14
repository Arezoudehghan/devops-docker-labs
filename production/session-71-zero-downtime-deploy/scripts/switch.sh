#!/usr/bin/env bash

set -Eeuo pipefail

TARGET="${1:-}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
CONF="${PROJECT_DIR}/nginx/default.conf"
BACKUP="${PROJECT_DIR}/nginx/default.conf.bak"

case "${TARGET}" in
  app-blue|app-green)
    ;;
  *)
    echo "Usage: $0 app-blue|app-green"
    exit 2
    ;;
esac

if ! docker inspect "${TARGET}" >/dev/null 2>&1; then
  echo "ERROR: container ${TARGET} does not exist"
  exit 1
fi

HEALTH="$(docker inspect --format='{{.State.Health.Status}}' "${TARGET}" 2>/dev/null || true)"

if [[ "${HEALTH}" != "healthy" ]]; then
  echo "ERROR: ${TARGET} is not healthy. Current status: ${HEALTH:-unknown}"
  exit 1
fi

if ! docker exec app-proxy wget -q -O /dev/null "http://${TARGET}/health"; then
  echo "ERROR: ${TARGET} is not reachable from app-proxy"
  exit 1
fi

CURRENT="$(grep -oE 'app-(blue|green)' "${CONF}" | head -n1 || true)"

if [[ "${CURRENT}" == "${TARGET}" ]]; then
  echo "INFO: ${TARGET} is already active"
  exit 0
fi

cp "${CONF}" "${BACKUP}"
sed -E -i "s/app-(blue|green)/${TARGET}/g" "${CONF}"

if ! docker exec app-proxy nginx -t; then
  echo "ERROR: nginx configuration test failed"
  cp "${BACKUP}" "${CONF}"
  exit 1
fi

docker exec app-proxy nginx -s reload

if ! curl -fsS --retry 5 --retry-delay 1 http://127.0.0.1:8088/ >/dev/null; then
  echo "ERROR: post-deployment verification failed"
  echo "ROLLBACK: restoring previous nginx configuration"
  cp "${BACKUP}" "${CONF}"
  docker exec app-proxy nginx -t
  docker exec app-proxy nginx -s reload
  exit 1
fi

echo "SUCCESS: traffic switched to ${TARGET}"

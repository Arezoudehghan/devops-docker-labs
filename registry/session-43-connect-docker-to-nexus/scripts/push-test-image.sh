#!/usr/bin/env bash
set -euo pipefail

REGISTRY="${REGISTRY:-192.168.94.90:8085}"
SOURCE_IMAGE="${SOURCE_IMAGE:-alpine:3.20}"
TARGET_IMAGE="${TARGET_IMAGE:-${REGISTRY}/lab/alpine:3.20}"

: "${NEXUS_USERNAME:?Set NEXUS_USERNAME before running this script}"
: "${NEXUS_PASSWORD:?Set NEXUS_PASSWORD before running this script}"

printf '%s\n' "${NEXUS_PASSWORD}" | docker login "${REGISTRY}" \
  -u "${NEXUS_USERNAME}" \
  --password-stdin

docker pull "${SOURCE_IMAGE}"
docker tag "${SOURCE_IMAGE}" "${TARGET_IMAGE}"
docker push "${TARGET_IMAGE}"

echo "Pushed: ${TARGET_IMAGE}"

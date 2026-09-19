#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-}"
REGISTRY="${REGISTRY:-192.168.94.90:8085}"
IMAGE_NAME="${IMAGE_NAME:-devops/versioning-demo}"

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Usage: $0 <MAJOR.MINOR.PATCH>" >&2
  exit 1
fi

GIT_SHA="$(git rev-parse --short=12 HEAD)"
VERSION_IMAGE="${REGISTRY}/${IMAGE_NAME}:${VERSION}"
SHA_IMAGE="${REGISTRY}/${IMAGE_NAME}:git-${GIT_SHA}"

docker build \
  --build-arg APP_VERSION="$VERSION" \
  -t "$VERSION_IMAGE" \
  -t "$SHA_IMAGE" \
  .

docker push "$VERSION_IMAGE"
docker push "$SHA_IMAGE"

printf 'Published:\n  %s\n  %s\n' "$VERSION_IMAGE" "$SHA_IMAGE"

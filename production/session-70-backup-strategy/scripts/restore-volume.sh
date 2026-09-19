#!/usr/bin/env bash
set -euo pipefail

ARCHIVE_PATH="${1:-}"
TARGET_VOLUME="${2:-}"

if [[ -z "$ARCHIVE_PATH" || -z "$TARGET_VOLUME" ]]; then
  echo "Usage: $0 <archive-path> <target-volume>" >&2
  exit 1
fi

if [[ ! -f "$ARCHIVE_PATH" ]]; then
  echo "Archive not found: $ARCHIVE_PATH" >&2
  exit 1
fi

BACKUP_DIR="$(cd "$(dirname "$ARCHIVE_PATH")" && pwd)"
ARCHIVE_NAME="$(basename "$ARCHIVE_PATH")"

docker volume create "$TARGET_VOLUME" >/dev/null

docker run --rm \
  -v "$TARGET_VOLUME:/data" \
  -v "$BACKUP_DIR:/backup:ro" \
  alpine \
  sh -c "tar xzf /backup/$ARCHIVE_NAME -C /data"

echo "Restored $ARCHIVE_PATH into Docker volume $TARGET_VOLUME"

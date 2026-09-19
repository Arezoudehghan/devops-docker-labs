#!/usr/bin/env bash
set -euo pipefail

VOLUME_NAME="${1:-}"
BACKUP_DIR="${2:-/backup/docker}"

if [[ -z "$VOLUME_NAME" ]]; then
  echo "Usage: $0 <volume-name> [backup-directory]" >&2
  exit 1
fi

mkdir -p "$BACKUP_DIR"

ARCHIVE_NAME="${VOLUME_NAME}_$(date +%F_%H%M).tar.gz"

docker run --rm \
  -v "$VOLUME_NAME:/data:ro" \
  -v "$BACKUP_DIR:/backup" \
  alpine \
  sh -c "tar czf /backup/$ARCHIVE_NAME -C /data ."

echo "$BACKUP_DIR/$ARCHIVE_NAME"

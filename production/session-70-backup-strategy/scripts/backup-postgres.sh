#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="${1:-/backup/postgres}"

mkdir -p "$BACKUP_DIR"

DUMP_FILE="$BACKUP_DIR/appdb_$(date +%F_%H%M).dump"

docker compose exec -T db \
  pg_dump -U appuser -Fc appdb \
  > "$DUMP_FILE"

echo "$DUMP_FILE"

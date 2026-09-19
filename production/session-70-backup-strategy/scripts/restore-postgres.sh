#!/usr/bin/env bash
set -euo pipefail

DUMP_FILE="${1:-}"

if [[ -z "$DUMP_FILE" ]]; then
  echo "Usage: $0 <dump-file>" >&2
  exit 1
fi

if [[ ! -f "$DUMP_FILE" ]]; then
  echo "Dump file not found: $DUMP_FILE" >&2
  exit 1
fi

docker compose exec -T db \
  pg_restore \
  -U appuser \
  -d appdb \
  --clean \
  --if-exists \
  < "$DUMP_FILE"

echo "Restored $DUMP_FILE into appdb"

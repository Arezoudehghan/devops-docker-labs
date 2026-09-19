#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-baseline}"
BENCH_DIR="/opt/docker-labs/session59/docker-bench-security"
OUT_DIR="/opt/docker-labs/session59"

case "$MODE" in
  baseline)
    OUT_FILE="$OUT_DIR/baseline.txt"
    ;;
  after-hardening)
    OUT_FILE="$OUT_DIR/after-hardening.txt"
    ;;
  *)
    echo "Usage: $0 {baseline|after-hardening}" >&2
    exit 2
    ;;
esac

cd "$BENCH_DIR"

sh docker-bench-security.sh \
  -b \
  -p \
  > "$OUT_FILE"

printf 'Saved Docker Bench report: %s\n' "$OUT_FILE"
grep -c '\[WARN\]' log/docker-bench-security.log || true

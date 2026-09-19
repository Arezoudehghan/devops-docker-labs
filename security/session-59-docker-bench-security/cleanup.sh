#!/usr/bin/env bash
set -euo pipefail

docker rm -f bench-demo 2>/dev/null || true

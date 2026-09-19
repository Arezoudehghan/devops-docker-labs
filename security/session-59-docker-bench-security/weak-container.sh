#!/usr/bin/env bash
set -euo pipefail

docker rm -f bench-demo 2>/dev/null || true
docker pull nginx:alpine

docker run -d \
  --name bench-demo \
  -p 18059:80 \
  nginx:alpine

docker ps --filter name=bench-demo
curl http://127.0.0.1:18059

#!/usr/bin/env bash
set -euo pipefail

docker rm -f bench-demo 2>/dev/null || true

docker run -d \
  --name bench-demo \
  --memory=128m \
  --cpus=0.50 \
  --pids-limit=100 \
  --read-only \
  --tmpfs /var/cache/nginx:rw,noexec,nosuid,size=16m \
  --tmpfs /var/run:rw,noexec,nosuid,size=4m \
  --security-opt no-new-privileges:true \
  --restart=on-failure:5 \
  -p 127.0.0.1:18059:80 \
  nginx:alpine

docker ps --filter name=bench-demo
curl -I http://127.0.0.1:18059
docker port bench-demo

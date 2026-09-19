# Session 71 — Zero-Downtime Deploy Command Cheat Sheet

This cheat sheet contains the executable commands used in Session 71 only.

Lab target: `DEV-2`  
Scenario: Docker Blue/Green deployment with Nginx reverse proxy  
Project path used in the lesson: `/opt/zero-downtime`  
Published production port: `8088`

---

## 1. Pre-checks

```bash
hostname
docker --version
docker ps
ss -lntp | grep 8088 || true
```

Remove old lab resources if they exist:

```bash
docker rm -f app-proxy app-blue app-green 2>/dev/null || true
docker network rm prod-net 2>/dev/null || true
```

---

## 2. Create project directories

```bash
mkdir -p /opt/zero-downtime/releases/v1
mkdir -p /opt/zero-downtime/releases/v2
mkdir -p /opt/zero-downtime/nginx
mkdir -p /opt/zero-downtime/scripts
cd /opt/zero-downtime
```

---

## 3. Create Version 1 files

```bash
cat > /opt/zero-downtime/releases/v1/index.html <<'EOF'
VERSION=v1 SLOT=BLUE
EOF
```

```bash
cat > /opt/zero-downtime/releases/v1/health <<'EOF'
OK
EOF
```

```bash
cat > /opt/zero-downtime/releases/v1/Dockerfile <<'EOF'
FROM nginx:alpine

COPY index.html /usr/share/nginx/html/index.html
COPY health /usr/share/nginx/html/health

HEALTHCHECK --interval=5s --timeout=2s --start-period=3s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1/health || exit 1
EOF
```

---

## 4. Build Version 1

```bash
docker build -t zero-app:v1 /opt/zero-downtime/releases/v1
docker image ls zero-app
```

---

## 5. Create production network

```bash
docker network create prod-net
docker network inspect prod-net
```

---

## 6. Start and verify Blue

```bash
docker run -d \
  --name app-blue \
  --network prod-net \
  --restart unless-stopped \
  zero-app:v1
```

```bash
docker ps
docker inspect --format='{{.State.Health.Status}}' app-blue
```

```bash
for i in $(seq 1 30); do
  STATUS=$(docker inspect --format='{{.State.Health.Status}}' app-blue)
  echo "$STATUS"
  [ "$STATUS" = "healthy" ] && break
  sleep 1
done
```

```bash
test "$(docker inspect --format='{{.State.Health.Status}}' app-blue)" = "healthy"
docker exec app-blue wget -qO- http://127.0.0.1/
docker exec app-blue wget -qO- http://127.0.0.1/health
```

---

## 7. Create Nginx configuration

```bash
cat > /opt/zero-downtime/nginx/default.conf <<'EOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://app-blue:80;

        proxy_http_version 1.1;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
```

---

## 8. Start and verify Nginx proxy

```bash
docker run -d \
  --name app-proxy \
  --network prod-net \
  -p 8088:80 \
  --restart unless-stopped \
  -v /opt/zero-downtime/nginx:/etc/nginx/conf.d:ro \
  nginx:alpine
```

```bash
docker ps
docker exec app-proxy nginx -t
docker exec app-proxy wget -qO- http://app-blue/
curl -fsS http://127.0.0.1:8088/
curl -fsS http://192.168.94.91:8088/
```

---

## 9. Create and build Version 2

```bash
cp /opt/zero-downtime/releases/v1/Dockerfile /opt/zero-downtime/releases/v2/Dockerfile
```

```bash
cat > /opt/zero-downtime/releases/v2/index.html <<'EOF'
VERSION=v2 SLOT=GREEN
EOF
```

```bash
cat > /opt/zero-downtime/releases/v2/health <<'EOF'
OK
EOF
```

```bash
docker build -t zero-app:v2 /opt/zero-downtime/releases/v2
docker image ls zero-app
```

---

## 10. Start and verify Green

```bash
docker run -d \
  --name app-green \
  --network prod-net \
  --restart unless-stopped \
  zero-app:v2
```

```bash
docker ps
docker inspect --format='{{.State.Health.Status}}' app-green
```

```bash
for i in $(seq 1 30); do
  STATUS=$(docker inspect --format='{{.State.Health.Status}}' app-green)
  echo "$STATUS"
  [ "$STATUS" = "healthy" ] && break
  sleep 1
done
```

```bash
test "$(docker inspect --format='{{.State.Health.Status}}' app-green)" = "healthy"
docker exec app-proxy wget -qO- http://app-green/
docker exec app-proxy wget -qO- http://app-green/health
curl -fsS http://127.0.0.1:8088/
```

---

## 11. Manual Blue to Green cutover

```bash
cp /opt/zero-downtime/nginx/default.conf /opt/zero-downtime/nginx/default.conf.bak
sed -i 's/app-blue/app-green/g' /opt/zero-downtime/nginx/default.conf
docker exec app-proxy nginx -t
docker exec app-proxy nginx -s reload
curl -fsS http://127.0.0.1:8088/
```

---

## 12. Manual rollback to Blue

```bash
docker inspect --format='{{.State.Health.Status}}' app-blue
sed -i 's/app-green/app-blue/g' /opt/zero-downtime/nginx/default.conf
docker exec app-proxy nginx -t
docker exec app-proxy nginx -s reload
curl -fsS http://127.0.0.1:8088/
```

---

## 13. Zero-downtime verification test

Return traffic to Blue first:

```bash
sed -i 's/app-green/app-blue/g' /opt/zero-downtime/nginx/default.conf
docker exec app-proxy nginx -t
docker exec app-proxy nginx -s reload
curl -fsS http://127.0.0.1:8088/
```

Start repeated requests:

```bash
rm -f /tmp/zero-downtime-test.log
```

```bash
(
  for i in $(seq 1 100); do
    if BODY=$(curl -fsS --max-time 2 http://127.0.0.1:8088/); then
      printf '%s OK %s\n' "$(date '+%H:%M:%S.%3N')" "$BODY"
    else
      printf '%s FAILED\n' "$(date '+%H:%M:%S.%3N')"
    fi
    sleep 0.1
  done
) | tee /tmp/zero-downtime-test.log &
MON_PID=$!
```

Cut over during the request loop:

```bash
sed -i 's/app-blue/app-green/g' /opt/zero-downtime/nginx/default.conf
docker exec app-proxy nginx -t
docker exec app-proxy nginx -s reload
wait "$MON_PID"
```

Check the result:

```bash
grep -c 'FAILED' /tmp/zero-downtime-test.log
head /tmp/zero-downtime-test.log
tail /tmp/zero-downtime-test.log
```

Target failed-request count:

```text
0
```

---

## 14. Automated switch script

The complete script is stored at `scripts/switch.sh`.

```bash
chmod +x /opt/zero-downtime/scripts/switch.sh
bash -n /opt/zero-downtime/scripts/switch.sh
```

Switch to Green:

```bash
/opt/zero-downtime/scripts/switch.sh app-green
curl -fsS http://127.0.0.1:8088/
```

Roll back to Blue:

```bash
/opt/zero-downtime/scripts/switch.sh app-blue
curl -fsS http://127.0.0.1:8088/
```

---

## 15. Commands used inside switch.sh

Read target health:

```bash
docker inspect --format='{{.State.Health.Status}}' "${TARGET}" 2>/dev/null || true
```

Verify target from the proxy:

```bash
docker exec app-proxy wget -q -O /dev/null "http://${TARGET}/health"
```

Detect active slot:

```bash
grep -oE 'app-(blue|green)' "${CONF}" | head -n1 || true
```

Back up and replace the configured slot:

```bash
cp "${CONF}" "${BACKUP}"
sed -E -i "s/app-(blue|green)/${TARGET}/g" "${CONF}"
```

Validate and reload Nginx:

```bash
docker exec app-proxy nginx -t
docker exec app-proxy nginx -s reload
```

Post-deployment verification:

```bash
curl -fsS \
  --retry 5 \
  --retry-delay 1 \
  http://127.0.0.1:8088/ \
  >/dev/null
```

Restore the backup during rollback:

```bash
cp "${BACKUP}" "${CONF}"
docker exec app-proxy nginx -t
docker exec app-proxy nginx -s reload
```

---

## 16. Confirm the active slot and clean up old Blue

```bash
grep proxy_pass /opt/zero-downtime/nginx/default.conf
curl -fsS http://127.0.0.1:8088/
docker rm -f app-blue
docker image ls zero-app
```

---

## 17. Verify restart policy

```bash
docker inspect --format='{{.HostConfig.RestartPolicy.Name}}' app-proxy
docker inspect --format='{{.HostConfig.RestartPolicy.Name}}' app-green
```

Expected:

```text
unless-stopped
```

---

## 18. Troubleshooting — proxy and port

```bash
docker ps -a --filter name=app-proxy
docker logs --tail 100 app-proxy
docker exec app-proxy nginx -t
ss -lntp | grep 8088
curl -v http://127.0.0.1:8088/
```

---

## 19. Troubleshooting — Docker network

```bash
docker network inspect prod-net
docker exec app-proxy wget -qO- http://app-blue/
docker exec app-proxy wget -qO- http://app-green/
docker ps -a --filter name=app-green
docker inspect --format='{{json .NetworkSettings.Networks}}' app-green
docker inspect --format='{{json .NetworkSettings.Networks}}' app-proxy
```

---

## 20. Troubleshooting — unhealthy Green

```bash
docker inspect --format='{{json .State.Health}}' app-green
docker logs --tail 100 app-green
docker exec app-green wget -qO- http://127.0.0.1/health
```

---

## 21. Restore Nginx configuration backup

```bash
cp /opt/zero-downtime/nginx/default.conf.bak /opt/zero-downtime/nginx/default.conf
docker exec app-proxy nginx -t
```

---

## Core deployment flow

```text
Build V2
  ↓
Start Green
  ↓
Healthcheck
  ↓
Test from Proxy
  ↓
Keep Blue Running
  ↓
nginx -t
  ↓
Graceful Reload
  ↓
Traffic → Green
  ↓
Post-deploy Test
  ↓
Keep Blue for Rollback
```

## Core rollback flow

```text
Problem
  ↓
Check Blue
  ↓
Switch Proxy
  ↓
nginx -t
  ↓
Graceful Reload
  ↓
Traffic → Blue
```

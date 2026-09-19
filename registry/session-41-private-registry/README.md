# Session 41 — Private Registry

Chapter 7: Registry and Nexus

This lab demonstrates the basic private-registry workflow:

```text
DEV-1 (registry/build host)
        |
        | docker push
        v
Private Registry :5005
        ^
        | docker pull
        |
DEV-2 (deploy/client host)
```

## Lab environment

| Host | Documentation address | Role |
|---|---|---|
| `DEV-1` | `192.0.2.10` | Docker build host and private Registry |
| `DEV-2` | `192.0.2.11` | Docker client/deploy host |

> The repository uses documentation-only IP addresses. Replace them with the addresses assigned to your own lab VMs.

## Goal

By the end of this lab you will:

- run a local Docker Registry;
- verify the Registry V2 API;
- configure Docker to allow the HTTP-only lab Registry;
- tag and push an image from `DEV-1`;
- pull and run the same image on `DEV-2`;
- understand where a private Registry fits between CI build and deployment.

## 1. Check port 5005 on DEV-1

```bash
sudo ss -lntp | grep ':5005' || true
```

## 2. Create persistent storage

```bash
sudo mkdir -p /opt/docker-labs/session41/registry-data
```

## 3. Run the Registry on DEV-1

```bash
docker run -d \
  --name session41-registry \
  --restart unless-stopped \
  -p 5005:5000 \
  -v /opt/docker-labs/session41/registry-data:/var/lib/registry \
  registry:3
```

Verify:

```bash
docker ps --filter name=session41-registry
curl -i http://127.0.0.1:5005/v2/
```

## 4. Configure the lab Registry on both Docker hosts

This lab Registry uses HTTP and therefore must be explicitly configured as an insecure Registry on both Docker hosts.

Back up the current Docker daemon configuration:

```bash
sudo cp -a /etc/docker/daemon.json \
  /etc/docker/daemon.json.backup-session41 2>/dev/null || true
```

Safely add the Registry without replacing unrelated Docker settings. Replace `192.0.2.10:5005` with the actual address of your DEV-1 Registry host.

```bash
sudo python3 - <<'PY'
import json
from pathlib import Path

path = Path("/etc/docker/daemon.json")

if path.exists() and path.read_text().strip():
    data = json.loads(path.read_text())
else:
    data = {}

registry = "192.0.2.10:5005"

registries = data.get("insecure-registries", [])

if registry not in registries:
    registries.append(registry)

data["insecure-registries"] = registries

path.write_text(json.dumps(data, indent=2) + "\n")
PY
```

Validate before restarting Docker:

```bash
sudo dockerd --validate --config-file=/etc/docker/daemon.json
```

Restart Docker and verify:

```bash
sudo systemctl restart docker
sudo systemctl --no-pager --full status docker
docker info | sed -n '/Insecure Registries/,+8p'
```

## 5. Push an image from DEV-1

```bash
docker pull busybox:1.36.1
docker tag \
  busybox:1.36.1 \
  192.0.2.10:5005/session41-busybox:1.0
docker push 192.0.2.10:5005/session41-busybox:1.0
```

Inspect Registry storage:

```bash
sudo du -sh /opt/docker-labs/session41/registry-data
sudo find /opt/docker-labs/session41/registry-data \
  -maxdepth 3 \
  -type d \
  | head -30
```

## 6. Pull and run from DEV-2

```bash
docker pull 192.0.2.10:5005/session41-busybox:1.0
docker run --rm \
  192.0.2.10:5005/session41-busybox:1.0 \
  echo "Private Registry Works"
```

Expected application output:

```text
Private Registry Works
```

## CI/CD flow

The key deployment flow introduced in this session is:

```text
Build -> Tag -> Push -> Private Registry -> Pull -> Run
```

A later Nexus lab can replace this simple Registry endpoint with a managed Docker hosted repository.

## Files

- `README.md` — runnable Session 41 lab.
- `SECURITY.md` — security notes for the intentionally insecure lab Registry.
- `DevOps_Private_Registry_Session_41_Commands_CheatSheet.txt` — command reference extracted from the lesson.

## Important

This Registry configuration intentionally has no TLS, authentication, or authorization. It is for an isolated learning lab only and is not production-ready.

#!/usr/bin/env bash
set -euo pipefail

REGISTRY="${REGISTRY:-192.168.94.90:8085}"
DAEMON_JSON="/etc/docker/daemon.json"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this script as root, for example: sudo bash $0" >&2
  exit 1
fi

if [[ -s "${DAEMON_JSON}" ]]; then
  backup="${DAEMON_JSON}.bak.$(date +%F-%H%M%S)"
  cp "${DAEMON_JSON}" "${backup}"
  echo "Backup created: ${backup}"
fi

REGISTRY="${REGISTRY}" python3 - <<'PY'
import json
import os
from pathlib import Path

p = Path("/etc/docker/daemon.json")
registry = os.environ["REGISTRY"]

data = {}
if p.exists() and p.stat().st_size:
    data = json.loads(p.read_text())

registries = set(data.get("insecure-registries", []))
registries.add(registry)
data["insecure-registries"] = sorted(registries)

p.write_text(json.dumps(data, indent=2) + "\n")
PY

python3 -m json.tool "${DAEMON_JSON}" >/dev/null
systemctl restart docker
systemctl is-active --quiet docker

echo "Docker is active. Configured registry: ${REGISTRY}"
docker info | grep -A 10 'Insecure Registries' || true

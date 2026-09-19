# Session 43 — Connect Docker to Nexus

Hands-on lab for connecting Docker clients on DEV-1 and DEV-2 to the Nexus Docker hosted repository.

## Lab environment

- DEV-1: `192.168.94.90`
  - Nexus Repository
  - Docker Engine
  - Docker registry connector: `192.168.94.90:8085`
- DEV-2: `192.168.94.91`
  - Docker Engine
- Nexus UI: `http://192.168.94.90:8081`
- Docker hosted registry: `192.168.94.90:8085`

## Project structure

```text
session-43-connect-docker-to-nexus/
├── README.md
├── scripts/
│   ├── configure-insecure-registry.sh
│   ├── push-test-image.sh
│   └── pull-test-image.sh
└── docs/
    └── DevOps_Connecting_Docker_to_Nexus_Session_43_Commands_CheatSheet.txt
```

## Nexus checks

Before using the scripts, confirm in Nexus:

- A `docker (hosted)` repository exists.
- Its Docker HTTP connector is listening on port `8085`.
- `Docker Bearer Token Realm` is active.

Test the registry endpoint:

```bash
curl -i http://192.168.94.90:8085/v2/
```

A `401 Unauthorized` response with Docker registry authentication headers is expected when authentication is enabled.

## Configure Docker client

Run on both DEV-1 and DEV-2:

```bash
sudo bash scripts/configure-insecure-registry.sh
```

The script:

- Backs up `/etc/docker/daemon.json` when it exists.
- Preserves existing Docker daemon settings.
- Adds `192.168.94.90:8085` to `insecure-registries`.
- Validates the JSON.
- Restarts Docker.
- Verifies the registry appears in `docker info`.

## Push test image from DEV-1

Export the Nexus credentials without putting the password directly in the command line:

```bash
export NEXUS_USERNAME='your-user'
export NEXUS_PASSWORD='your-password'
```

Then run:

```bash
bash scripts/push-test-image.sh
```

The script logs in with `--password-stdin`, pulls `alpine:3.20`, tags it as `192.168.94.90:8085/lab/alpine:3.20`, and pushes it to Nexus.

## Pull and run from DEV-2

Set the same credential variables on DEV-2:

```bash
export NEXUS_USERNAME='your-user'
export NEXUS_PASSWORD='your-password'
```

Then run:

```bash
bash scripts/pull-test-image.sh
```

The script logs in, pulls the image from Nexus, and runs `cat /etc/alpine-release` inside a temporary container.

## Manual verification

```bash
docker info | grep -A 10 'Insecure Registries'
```

```bash
docker login 192.168.94.90:8085
```

```bash
docker push 192.168.94.90:8085/lab/alpine:3.20
```

```bash
docker pull 192.168.94.90:8085/lab/alpine:3.20
```

## Commands cheat sheet

The full command cheat sheet for this session is stored in:

`docs/DevOps_Connecting_Docker_to_Nexus_Session_43_Commands_CheatSheet.txt`

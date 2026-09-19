# Session 44 — Login to Nexus Docker Registry

Chapter 7 of the DevOps Docker course covers Registry and Nexus workflows. This lab focuses on authenticating a Docker client against a Nexus Docker Registry.

## Learning objectives

- Understand what `docker login` does.
- Use the Nexus Docker connector address in `host:port` format.
- Enable and verify Docker Bearer Token authentication in Nexus.
- Configure an HTTP Nexus registry as an insecure registry in Docker for a lab environment.
- Validate Docker daemon JSON before restarting Docker.
- Log in interactively and with `--password-stdin`.
- Understand where Docker credentials are stored.
- Troubleshoot common Nexus Registry login errors.

## Lab environment

- `DEV-1`: `192.168.94.90` — Nexus Repository and Docker Hosted Registry.
- Nexus Docker Registry connector: `192.168.94.90:8085`.
- `DEV-2`: `192.168.94.91` — Docker client used to test login.

> These are private lab addresses from the course environment. Replace them with the addresses assigned to your own lab.

## Project structure

```text
session-44-nexus-login/
├── README.md
└── docs/
    └── DevOps_Nexus_Registry_Login_Session_44_Commands_CheatSheet.txt
```

## Nexus authentication requirement

In Nexus, make sure **Docker Bearer Token Realm** is active:

```text
Settings
└── Security
    └── Realms
        └── Docker Bearer Token Realm
```

The Nexus user used for Docker login must also have the required privileges for the Docker repository.

## Verify the Nexus Docker connector

On the Nexus host:

```bash
sudo ss -lntp | grep ':8085'
```

From the Docker client:

```bash
nc -vz 192.168.94.90 8085
```

Check the Docker Registry v2 endpoint:

```bash
curl -i http://192.168.94.90:8085/v2/
```

A `401 Unauthorized` response can be normal before authentication because it shows that the registry endpoint is reachable and requires credentials.

## HTTP lab registry configuration

Docker normally expects registries to use HTTPS. For this lab, the Nexus Docker connector uses HTTP, so add the registry to Docker's insecure registry list on `DEV-2`.

Open:

```bash
sudo nano /etc/docker/daemon.json
```

Example configuration:

```json
{
  "insecure-registries": [
    "192.168.94.90:8085"
  ]
}
```

If `daemon.json` already contains other settings, merge this key into the existing JSON instead of replacing the file.

Validate the JSON:

```bash
python3 -m json.tool /etc/docker/daemon.json
```

Restart Docker:

```bash
sudo systemctl restart docker
sudo systemctl status docker --no-pager
```

Verify Docker recognizes the registry:

```bash
docker info | grep -A5 "Insecure Registries"
```

## Login to Nexus

The registry address must contain only the host or IP and the Docker connector port.

Correct:

```bash
docker login 192.168.94.90:8085
```

With a username:

```bash
docker login 192.168.94.90:8085 -u "$NEXUS_USER"
```

Do not add `http://`, `https://`, or a Nexus repository path such as `/repository/docker-hosted` to the `docker login` target.

## Safer non-interactive login

For automation and CI/CD, pass the password through standard input:

```bash
printf '%s' "$NEXUS_PASSWORD" | docker login 192.168.94.90:8085 -u "$NEXUS_USER" --password-stdin
```

Avoid putting passwords directly in command-line arguments.

## Docker credential location

For the current Linux user, Docker client configuration is normally stored under:

```text
~/.docker/config.json
```

Inspect it with:

```bash
cat ~/.docker/config.json
ls -l ~/.docker/config.json
```

Using `sudo docker login` authenticates as root and therefore uses root's Docker configuration rather than the current user's configuration.

## Logout

```bash
docker logout 192.168.94.90:8085
```

## Troubleshooting

### HTTP response to HTTPS client

If Docker reports:

```text
server gave HTTP response to HTTPS client
```

Check that `192.168.94.90:8085` is present in `insecure-registries`, restart Docker, and verify with:

```bash
docker info | grep -A5 "Insecure Registries"
```

### Unauthorized

If Docker reports:

```text
unauthorized: authentication required
```

Check:

- Nexus username and password.
- Docker Bearer Token Realm.
- Repository privileges assigned to the Nexus user.
- Docker connector port.
- The registry address format.

### Network connection failure

Test basic reachability and the registry port:

```bash
ping -c 4 192.168.94.90
nc -vz 192.168.94.90 8085
curl -i http://192.168.94.90:8085/v2/
```

## Authentication vs authorization

Authentication answers:

```text
Who are you?
```

Authorization answers:

```text
What are you allowed to do?
```

A user may authenticate successfully but still lack permission to push to a specific repository.

## Commands cheat sheet

The complete command cheat sheet for this lesson is stored at:

`docs/DevOps_Nexus_Registry_Login_Session_44_Commands_CheatSheet.txt`

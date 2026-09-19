# Session 42 — Push and Pull Images with Nexus

Chapter 7 of the DevOps course introduces Docker Registry workflows with Nexus Repository Manager. This lab demonstrates the complete flow from tagging a local image on `DEV-1`, authenticating to Nexus, pushing the image, pulling it on `DEV-2`, and running a container from the private registry.

## Lab environment

- `DEV-1`: `192.168.94.90` — Docker build host and Nexus
- `DEV-2`: `192.168.94.91` — Docker deployment host
- Nexus Docker Registry: `192.168.94.90:8085`
- Test image: `nginx:alpine`
- Registry image: `192.168.94.90:8085/labs/session42-nginx:1.0`

## Workflow

```text
DEV-1
  |
  | docker pull
  v
nginx:alpine
  |
  | docker tag
  v
192.168.94.90:8085/labs/session42-nginx:1.0
  |
  | docker login
  | docker push
  v
Nexus Registry
  |
  | docker login
  | docker pull
  v
DEV-2
  |
  | docker run
  v
Container
```

## 1. Verify the Nexus Docker Registry

Run on `DEV-1`:

```bash
curl -i http://192.168.94.90:8085/v2/
```

A response such as `200 OK` or `401 Unauthorized` confirms that the registry endpoint is reachable. A `401` response can be expected when authentication is enabled.

## 2. Prepare the source image on DEV-1

```bash
docker image ls
docker pull nginx:alpine
docker image ls nginx
```

## 3. Authenticate to Nexus

```bash
docker login 192.168.94.90:8085
```

For CI/CD jobs, use standard input for the password instead of placing the password directly in the command line:

```bash
printf '%s\n' "$NEXUS_PASSWORD" | docker login 192.168.94.90:8085 \
  --username "$NEXUS_USERNAME" \
  --password-stdin
```

## 4. Tag the image for Nexus

```bash
docker tag nginx:alpine \
  192.168.94.90:8085/labs/session42-nginx:1.0
```

## 5. Push the image to Nexus

```bash
docker push 192.168.94.90:8085/labs/session42-nginx:1.0
```

## 6. Verify connectivity from DEV-2

```bash
curl -i http://192.168.94.90:8085/v2/
docker login 192.168.94.90:8085
```

## 7. Pull the image from Nexus

```bash
docker image ls \
  192.168.94.90:8085/labs/session42-nginx
```

```bash
docker pull \
  192.168.94.90:8085/labs/session42-nginx:1.0
```

```bash
docker image ls \
  192.168.94.90:8085/labs/session42-nginx
```

## 8. Run the image on DEV-2

```bash
docker run -d \
  --name session42-nginx \
  -p 8042:80 \
  192.168.94.90:8085/labs/session42-nginx:1.0
```

```bash
docker ps \
  --filter name=session42-nginx
```

```bash
curl -I http://127.0.0.1:8042
```

## 9. Push and pull a second tag

On `DEV-1`:

```bash
docker tag nginx:alpine \
  192.168.94.90:8085/labs/session42-nginx:2.0
```

```bash
docker push \
  192.168.94.90:8085/labs/session42-nginx:2.0
```

On `DEV-2`:

```bash
docker pull \
  192.168.94.90:8085/labs/session42-nginx:2.0
```

```bash
docker image ls \
  192.168.94.90:8085/labs/session42-nginx
```

## Troubleshooting

```bash
docker info
```

```bash
ss -lntp | grep 8085
```

```bash
curl -i http://192.168.94.90:8085/v2/
```

Common problems in this lab include:

- `unauthorized: authentication required` — verify Nexus credentials and permissions.
- `connection refused` — verify the Nexus Docker connector, firewall, and network path.
- `manifest unknown` — verify the image name and tag.
- `http: server gave HTTP response to HTTPS client` — verify the Docker daemon configuration when the lab registry uses HTTP.

## Commands cheat sheet

See [`DevOps_Push_Pull_Image_Session_42_Commands_CheatSheet.txt`](DevOps_Push_Pull_Image_Session_42_Commands_CheatSheet.txt).

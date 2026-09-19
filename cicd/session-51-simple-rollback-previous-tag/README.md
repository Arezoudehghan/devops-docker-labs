# Session 51 — Simple Rollback with a Previous Tag

Chapter 8: Docker in CI/CD

This lab demonstrates a simple Docker rollback by redeploying a previously built and known-good image tag from Nexus instead of rebuilding the application.

```text
New image deployed
       |
       v
Application problem
       |
       v
Select previous good tag
       |
       v
Pull image from Nexus
       |
       v
Replace current container
       |
       v
Health check
```

## Lab environment

| Host | Documentation address | Role |
|---|---|---|
| `DEV-1` | `192.0.2.10` | GitLab CE, GitLab Runner, Docker, and Nexus |
| `DEV-2` | `192.0.2.20` | Docker deployment server |
| Nexus Docker connector | `192.0.2.10:8085` | Docker hosted Registry endpoint |

> The repository uses documentation-only addresses from `192.0.2.0/24`. Replace them with the addresses used in your own lab.

## Files

- `.gitlab-ci.yml` — manual GitLab CI/CD rollback job.
- `docs/DevOps_Docker_Simple_Rollback_Previous_Tag_Session_51_Commands_CheatSheet.txt` — command Cheat Sheet extracted from Session 51.

## Rollback concept

A rollback should normally reuse the exact artifact that was already built and tested:

```text
Previous good image
       |
       v
Registry
       |
       v
docker pull
       |
       v
Replace container
       |
       v
Verify
```

The lab uses an explicit image tag such as a Git commit short SHA. It does not use `latest` for rollback selection.

## Required GitLab CI/CD variables

Configure these variables under **Settings → CI/CD → Variables**:

```text
NEXUS_USER
NEXUS_PASSWORD
ROLLBACK_TAG
SSH_PRIVATE_KEY
SSH_KNOWN_HOSTS
```

For this lab, `SSH_PRIVATE_KEY` and `SSH_KNOWN_HOSTS` are intended to be GitLab **File** variables.

Keep credentials masked and never commit passwords or private keys to the repository.

## Manual rollback flow

Before replacing the running container, pull the rollback image first:

```bash
docker pull "${NEXUS_REGISTRY}/${IMAGE_NAME}:${ROLLBACK_TAG}"
```

This reduces the risk of taking the application down before confirming that the old image is available.

The basic manual flow is:

```bash
docker pull "${NEXUS_REGISTRY}/${IMAGE_NAME}:${ROLLBACK_TAG}"

docker rm -f "${CONTAINER_NAME}"

docker run -d   --name "${CONTAINER_NAME}"   --restart unless-stopped   -p "${DEPLOY_PORT}:8000"   "${NEXUS_REGISTRY}/${IMAGE_NAME}:${ROLLBACK_TAG}"
```

Then verify the application:

```bash
curl -fsS "http://127.0.0.1:${DEPLOY_PORT}/"
```

## GitLab rollback job

The pipeline contains a manual job:

```text
rollback_production
```

When the job is run, provide a known-good tag through:

```text
ROLLBACK_TAG
```

Example:

```text
ROLLBACK_TAG=b72de91
```

The job validates the tag, authenticates the deployment host to Nexus, pulls the requested image, replaces the current container, and performs an HTTP health check.

## Important limitation

Rolling back a Docker image does not automatically roll back application state.

If the newer release changed a database schema or persistent volume data, an older application image may not be compatible with the changed state. Database migration and state rollback strategies must therefore be designed separately.

## Security notes

- Never commit Nexus passwords or SSH private keys.
- Use masked/protected GitLab CI/CD variables.
- Keep strict SSH host-key checking enabled.
- Prefer TLS for production Registry traffic.
- Use a least-privilege Nexus CI user.
- Keep previous known-good images available long enough to support rollback.

# Session 50 — Deploy on Server with SSH

Chapter 8: Docker in CI/CD

This lab extends the previous CI/CD sessions by adding remote deployment from a GitLab Shell Runner on DEV-1 to a Docker deploy server on DEV-2 over SSH.

```text
GitLab Pipeline
      |
      v
Shell Runner on DEV-1
      |
      +--> SSH to DEV-2
              |
              +--> docker login Nexus
              +--> docker pull <commit-sha>
              +--> stop/remove old container
              +--> docker run new container
              +--> health verification
```

## Lab environment

| Host | Documentation address | Role |
|---|---|---|
| `DEV-1` | `192.0.2.10` | GitLab Runner and Nexus Registry host |
| Nexus Docker connector | `192.0.2.10:8085` | Docker hosted Registry endpoint |
| `DEV-2` | `192.0.2.11` | Remote Docker deploy server |

> The repository uses documentation-only addresses from `192.0.2.0/24`. Replace them with the addresses assigned to your own lab VMs.

## Files

- `.gitlab-ci.yml` — deploy stage for pulling a commit-tagged image from Nexus and replacing the remote container over SSH.
- `docs/DevOps_Docker_Deploy_with_SSH_Session_50_Commands_CheatSheet.txt` — command Cheat Sheet extracted from Session 50.

## Session scope

This session focuses only on the deploy stage.

The image is expected to have already been built and pushed to Nexus by an earlier pipeline stage, using the current GitLab short commit SHA as the tag:

```text
${NEXUS_REGISTRY}/${IMAGE_NAME}:${CI_COMMIT_SHORT_SHA}
```

## Required GitLab CI/CD variables

Create these variables in the GitLab project under **Settings → CI/CD → Variables**:

```text
SSH_PRIVATE_KEY
SSH_KNOWN_HOSTS
NEXUS_USER
NEXUS_PASSWORD
```

Use **File** type variables for `SSH_PRIVATE_KEY` and `SSH_KNOWN_HOSTS`.

Do not commit private keys, passwords, or other secrets to this repository.

## SSH model

The deployment uses key-based authentication:

```text
Private key -> GitLab CI/CD variable
Public key  -> DEV-2 deploy user's authorized_keys
```

The pipeline enables strict host-key checking and copies the trusted host-key file into `~/.ssh/known_hosts`.

## Deployment flow

The deploy job performs these steps:

```text
1. Prepare SSH key and known_hosts
2. Build the exact image reference from CI_COMMIT_SHORT_SHA
3. SSH to DEV-2
4. Login to Nexus from DEV-2
5. Pull the new image before stopping the old container
6. Stop and remove the previous container if it exists
7. Start the new container
8. Verify container status
9. Check the application endpoint
```

Pulling the new image before stopping the currently running container reduces avoidable downtime when a Registry or network problem prevents the new image from being downloaded.

## Pipeline variables

The example file contains:

```yaml
NEXUS_REGISTRY: "192.0.2.10:8085"
IMAGE_NAME: "cicd-session50-app"
DEPLOY_HOST: "192.0.2.11"
DEPLOY_USER: "deploy"
CONTAINER_NAME: "cicd-session50-app"
DEPLOY_PORT: "8088"
APP_PORT: "8000"
```

Replace the documentation addresses and ports with the values used by your own lab.

## Technical correction

The lesson material showed `docker stop --time 20` in some examples.

The executable project uses:

```bash
docker stop --timeout 20 "$CONTAINER_NAME"
```

This is the documented Docker CLI option name used by the final project.

## Security notes

- Keep SSH private keys and Registry credentials in GitLab CI/CD variables.
- Keep `StrictHostKeyChecking=yes`.
- Verify the DEV-2 SSH host key before storing it in `SSH_KNOWN_HOSTS`.
- Do not print `SSH_PRIVATE_KEY` in job logs.
- Treat membership in the Docker group as privileged host access.
- Prefer TLS and least-privilege Registry credentials in production.

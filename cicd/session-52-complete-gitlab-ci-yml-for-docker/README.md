# Session 52 — Complete `.gitlab-ci.yml` for Docker

Chapter 8: Docker in CI/CD

This lab combines the Docker CI/CD workflow from the previous sessions into one GitLab pipeline:

```text
Validate
   |
   v
Build image
   |
   v
Smoke test
   |
   v
Push to Nexus
   |
   v
Deploy over SSH
   |
   v
Verify production
   |
   v
Manual rollback when needed
```

## Lab environment

| Host | Documentation address | Role |
|---|---|---|
| `DEV-1` | `192.0.2.10` | GitLab CE, GitLab Runner, Docker, and Nexus |
| `DEV-2` | `192.0.2.11` | Docker deployment server |
| Nexus Docker connector | `192.0.2.10:8085` | Docker hosted Registry endpoint |

> The repository uses documentation-only addresses from `192.0.2.0/24`. Replace them with the addresses used in your own lab.

## Files

- `.gitlab-ci.yml` — complete Session 52 GitLab pipeline.
- `docs/DevOps_Docker_CICD_Session_52_Commands_CheatSheet.txt` — command Cheat Sheet extracted from this lesson.

## Pipeline stages

```text
validate
build
test
push
deploy
verify
rollback
```

The pipeline uses the `dev-shell` GitLab Runner tag and is designed for a Shell executor with Docker installed on the runner host.

## Image tagging

The main deployment artifact is tagged with:

```text
CI_COMMIT_SHORT_SHA
```

Example:

```text
192.0.2.10:8085/cicd-session52-app:93cf71ae
```

On the `main` branch, the same image also receives the `latest` alias. Git tags are also published as release image tags.

Production deployment uses the immutable commit or release tag rather than depending on `latest`.

## Artifact transfer

The build job exports the image as:

```text
image.tar.gz
```

Later jobs load that artifact with `docker load`. This avoids depending on the next job running on the exact same runner host.

## Smoke test

The test job runs the built image as a temporary container and lets Docker allocate an available loopback host port:

```text
127.0.0.1::<APP_PORT>
```

The job then discovers that port with `docker port` and verifies the HTTP endpoint with `curl`.

The temporary test container is removed automatically through a shell `trap`.

## Required GitLab CI/CD variables

Configure these under **Settings → CI/CD → Variables**:

```text
NEXUS_USERNAME
NEXUS_PASSWORD
SSH_PRIVATE_KEY
SSH_KNOWN_HOSTS
```

For this lab, `SSH_PRIVATE_KEY` and `SSH_KNOWN_HOSTS` are intended to be GitLab **File** variables.

Keep passwords and private keys out of the repository.

## Proxy variables

The repository version leaves these defaults empty:

```text
HTTP_PROXY
HTTPS_PROXY
```

If the build environment requires an HTTP proxy, set the correct values as GitLab CI/CD variables for your environment.

## Deployment

For a normal push to `main`, the pipeline deploys the image tagged with `CI_COMMIT_SHORT_SHA`.

For a Git tag pipeline, it deploys the image tagged with `CI_COMMIT_TAG`.

The deployment host:

1. logs in to Nexus,
2. pulls the requested image,
3. replaces the existing application container,
4. starts the new container on host port `8088`,
5. logs out of Nexus.

## Production verification

After deployment, the pipeline checks:

```text
http://192.0.2.11:8088/
```

It retries the request before declaring the deployment unhealthy.

## Manual rollback

The `rollback_production` job is manual.

Run it with a known-good value such as:

```text
ROLLBACK_TAG=74ae82c1
```

The job pulls that exact image tag and replaces the current production container with it.

## Important limitation

Image rollback only restores the application container image. It does not automatically reverse database migrations, persistent-volume changes, or other application state.

## Security notes

- Never commit Nexus passwords or SSH private keys.
- Use masked/protected GitLab CI/CD variables where appropriate.
- Keep trusted SSH host keys in `SSH_KNOWN_HOSTS`.
- Prefer TLS for production Registry traffic.
- Use a least-privilege Nexus CI user.
- Use Shell runners only for trusted projects and workloads.

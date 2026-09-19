# Session 49 — Push to Nexus from Pipeline

Chapter 8: Docker in CI/CD

This lab automates Docker image publishing from a GitLab CI/CD pipeline to a Nexus Docker hosted Registry.

```text
Git push
   |
   v
GitLab Pipeline
   |
   v
Shell Runner on DEV-1
   |
   +--> docker build
   |
   +--> docker login
   |
   +--> docker push <commit-sha>
   |
   +--> docker push latest
            |
            v
      Nexus Registry :8085
```

## Lab environment

| Host | Documentation address | Role |
|---|---|---|
| `DEV-1` | `192.0.2.10` | GitLab Runner, Docker build host, and Nexus Registry host |
| Nexus Docker connector | `192.0.2.10:8085` | Docker hosted Registry endpoint |

> The repository uses documentation-only addresses from `192.0.2.0/24`. Replace `192.0.2.10:8085` with the Nexus Docker connector address used in your own lab.

## Files

- `.gitlab-ci.yml` — builds the image and pushes commit-specific and `latest` tags to Nexus.
- `Dockerfile` — builds the Session 49 test application image.
- `index.html` — static application content used by the Docker image.
- `docs/DevOps_Push_to_Nexus_from_Pipeline_Session_49_Commands_CheatSheet.txt` — command Cheat Sheet extracted from Session 49.

## GitLab Runner requirements

The learning environment uses a GitLab Shell Runner tagged:

```text
dev-shell
```

The runner user must be able to access the Docker Engine installed on DEV-1.

Verify on the runner host:

```bash
sudo -u gitlab-runner docker version
sudo -u gitlab-runner docker info
```

## Required GitLab CI/CD variables

Create these variables in the GitLab project under **Settings → CI/CD → Variables**:

```text
NEXUS_USERNAME
NEXUS_PASSWORD
```

Keep the password masked and do not commit Registry credentials to this repository.

## Registry address

The example pipeline contains:

```yaml
NEXUS_REGISTRY: "192.0.2.10:8085"
```

Replace it with the Docker connector address for your own Nexus hosted repository.

## Pipeline stages

The pipeline contains two stages:

```text
build
  |
  v
push
```

`build_image` builds an image tagged with `CI_COMMIT_SHORT_SHA` and verifies that the local image exists.

`push_to_nexus` authenticates with `--password-stdin`, pushes the commit-specific tag, creates the `latest` tag, pushes it, logs out, and removes the temporary Docker CLI configuration directory.

## Image naming

The pipeline constructs the image name from:

```text
${NEXUS_REGISTRY}/${CI_PROJECT_PATH_SLUG}:${CI_COMMIT_SHORT_SHA}
```

Example:

```text
192.0.2.10:8085/root-docker-demo:a82b6d91
```

## Verify the Registry endpoint

From DEV-1:

```bash
curl --noproxy '*' -i http://192.0.2.10:8085/v2/
```

A `401 Unauthorized` response can be normal when authentication is required. It still confirms that the Docker Registry endpoint is responding.

## Verify the pushed image

After a successful pipeline, browse the Nexus Docker hosted repository and confirm that the project image has both:

```text
<commit-short-sha>
latest
```

You can also test a pull after replacing the example image name and tag:

```bash
docker pull 192.0.2.10:8085/root-docker-demo:a82b6d91
```

## Important Shell Runner behavior

This lesson intentionally separates build and push into two jobs. That works in the current lab because both jobs use the same Shell Runner host and therefore the same Docker daemon.

With multiple independent runners, the push job might run on a different host and the locally built image would not exist there. In that design, build and push should be handled in the same job or by a builder workflow that publishes directly to the Registry.

## Security note

- Never commit Nexus passwords or other secrets.
- Prefer masked/protected GitLab CI/CD variables.
- Use TLS for production Registry traffic.
- Use a dedicated least-privilege Nexus CI user instead of the administrator account.

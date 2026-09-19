# Session 48 — Docker Image Tag Strategy in CI/CD

Chapter 8: Docker in CI/CD

This lab demonstrates a practical Docker image tagging strategy for GitLab CI/CD. Each build receives a traceable tag based on `CI_COMMIT_SHORT_SHA`, while a second moving tag is created from `CI_COMMIT_REF_SLUG` for branch-level convenience.

```text
Git commit
    |
    v
GitLab CI/CD
    |
    | docker build
    v
IMAGE:CI_COMMIT_SHORT_SHA
    |
    | docker tag
    v
IMAGE:CI_COMMIT_REF_SLUG
```

## Lab environment

| Host | Documentation address | Role |
|---|---|---|
| `DEV-1` | `192.0.2.10` | GitLab Runner, Docker build host, and Nexus Registry host |
| Nexus Docker connector | `192.0.2.10:8085` | Docker hosted Registry endpoint |
| `DEV-2` | `192.0.2.11` | Docker deploy host |

> The repository uses documentation-only addresses from `192.0.2.0/24`. Replace them with the addresses assigned to your own lab VMs.

## Files

- `.gitlab-ci.yml` — builds one image with a unique commit tag and adds a branch/ref tag.
- `Dockerfile` — builds the small Session 48 demo web application.
- `index.html` — static page served by the demo image.
- `docs/DevOps_Docker_Image_Tagging_Session_48_Commands_CheatSheet.txt` — command Cheat Sheet extracted from the lesson.

## Tag strategy

The unique build tag uses:

```text
CI_COMMIT_SHORT_SHA
```

Example:

```text
cicd-session48-app:82a44c91
```

The branch/ref convenience tag uses:

```text
CI_COMMIT_REF_SLUG
```

Example:

```text
cicd-session48-app:main
```

The SHA tag should be kept for traceability and rollback. Branch tags such as `main` or `develop` are moving references and may point to a newer image after another pipeline run.

## GitLab pipeline

The pipeline creates two references for the same built image:

```bash
IMAGE_SHA="${NEXUS_REGISTRY}/${IMAGE_NAME}:${CI_COMMIT_SHORT_SHA}"
IMAGE_BRANCH="${NEXUS_REGISTRY}/${IMAGE_NAME}:${CI_COMMIT_REF_SLUG}"

docker build -t "${IMAGE_SHA}" .
docker tag "${IMAGE_SHA}" "${IMAGE_BRANCH}"
docker image ls "${NEXUS_REGISTRY}/${IMAGE_NAME}"
```

For a commit such as `82a44c91` on branch `main`, the resulting image references are similar to:

```text
192.0.2.10:8085/cicd-session48-app:82a44c91
192.0.2.10:8085/cicd-session48-app:main
```

Both tags can point to the same image ID.

## Run the image manually

After building the image, run the unique SHA-tagged version by replacing the example SHA with the build you want to test:

```bash
docker run -d \
  --name cicd-session48-app \
  -p 8088:8000 \
  192.0.2.10:8085/cicd-session48-app:3308ad76
```

Open the application on host port `8088`.

## Key rule

```text
Every build -> unique tag
```

Use the commit SHA tag for traceability and reliable rollback. Use branch tags as convenient aliases, not as the only production identifier.

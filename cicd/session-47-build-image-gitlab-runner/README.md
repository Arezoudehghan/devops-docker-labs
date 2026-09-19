# Session 47 — Build Image in GitLab Runner

Chapter 8: Docker in CI/CD

This lab demonstrates how a GitLab Runner using the Shell executor builds a Docker image on DEV-1, tags the image with the current Git commit short SHA, verifies the image, and tests the Nginx configuration before a later Registry push stage.

```text
Developer
   |
   | git push
   v
GitLab on DEV-1
   |
   | pipeline job
   v
GitLab Runner (Shell executor)
   |
   | docker build
   v
Docker Engine on DEV-1
   |
   v
session47-app:<commit-short-sha>
```

## Lab environment

| Host | Documentation address | Role |
|---|---|---|
| `DEV-1` | `192.0.2.10` | GitLab, Shell Runner, Docker build host, and Nexus host |
| Runner tag | `dev-shell` | Selects the Shell Runner used by this lab |

> The repository documentation uses example addresses from `192.0.2.0/24`. Replace them with the addresses assigned to your own lab VMs.

## Files

- `.gitlab-ci.yml` — GitLab CI pipeline that builds and verifies the Docker image.
- `session47/Dockerfile` — builds the Session 47 Nginx image.
- `session47/index.html` — static page copied into the image.
- `session47/.dockerignore` — excludes unnecessary files from the Docker build context.
- `docs/DevOps_Build_Image_in_GitLab_Runner_Session_47_Commands_CheatSheet.txt` — complete command Cheat Sheet extracted from this lesson.

## Project layout

```text
.
├── .gitlab-ci.yml
├── session47/
│   ├── .dockerignore
│   ├── Dockerfile
│   └── index.html
└── docs/
    └── DevOps_Build_Image_in_GitLab_Runner_Session_47_Commands_CheatSheet.txt
```

This directory mirrors the project layout used in the lesson. To run it as a standalone GitLab lab, use this Session 47 directory as the GitLab project root or configure GitLab to use this nested CI configuration explicitly.

## 1. Verify Docker access for the Runner

Run on DEV-1:

```bash
id gitlab-runner
sudo -u gitlab-runner -H docker info
```

The Shell Runner must be able to access the Docker Engine on DEV-1.

## 2. Manual build verification

From this lab directory:

```bash
docker build -t session47-app:manual session47
docker image ls session47-app
```

## 3. Manual container test

```bash
docker run -d \
  --name session47-manual \
  -p 18047:80 \
  session47-app:manual

curl -fsS http://127.0.0.1:18047/
docker rm -f session47-manual
```

## 4. GitLab CI build job

The pipeline uses:

```yaml
IMAGE_NAME: "session47-app"
IMAGE_TAG: "$CI_COMMIT_SHORT_SHA"
BUILD_CONTEXT: "session47"
```

The build command is:

```bash
docker build --tag "${IMAGE_NAME}:${IMAGE_TAG}" "${BUILD_CONTEXT}"
```

The image is then verified with `docker image inspect`, and a temporary container runs `nginx -t` to validate the Nginx configuration.

## 5. Image location after the job

With the Shell executor used in this learning environment, the image is created in the Docker Engine on DEV-1. The build step alone does not push the image to Nexus or another Registry.

Verify on DEV-1:

```bash
docker image ls session47-app
git rev-parse --short=8 HEAD
```

The image tag should match the GitLab short commit SHA for the pipeline commit.

## Key workflow

```text
Git Push
   |
   v
GitLab Pipeline
   |
   v
Shell Runner on DEV-1
   |
   v
docker build
   |
   v
session47-app:<commit-short-sha>
```

The next Registry stage can authenticate, tag the image with the Registry address, and push the tested image to Nexus.

## Security note

Membership in the Docker group provides highly privileged access to the Docker host. Use trusted runners and repositories, protect CI/CD variables, and use organization-approved secrets management and TLS for production environments.

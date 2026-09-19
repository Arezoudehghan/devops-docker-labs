# DevOps Docker Labs

[![Validate DevOps Docker Labs](https://github.com/Arezoudehghan/devops-docker-labs/actions/workflows/validate.yml/badge.svg)](https://github.com/Arezoudehghan/devops-docker-labs/actions/workflows/validate.yml)

A structured collection of hands-on Docker labs covering Docker fundamentals, persistent storage, Docker Compose, networking, registry and Nexus workflows, security practices, container monitoring, production practices, Docker Swarm, and deployment scenarios in a two-VM DevOps learning environment.

## Lab environment

| Host | Address | Primary role |
|---|---|---|
| `DEV-1` | `192.0.2.10` | Build, GitLab, Runner, Nexus, and client tests |
| `DEV-2` | `192.0.2.11` | Deploy, Docker, Swarm worker, and monitoring |

> `192.0.2.10` and `192.0.2.11` are documentation-only example addresses. Replace them with the addresses assigned to your own lab VMs.

## Repository structure

```text
.
├── fundamentals/
│   ├── session-01-docker-basics/
│   ├── session-02-vm-vs-container/
│   ├── session-03-docker-architecture/
│   ├── session-04-install-docker-ubuntu/
│   ├── session-05-first-nginx-container/
│   ├── session-06-docker-run/
│   ├── session-07-foreground-detached-mode/
│   ├── session-08-port-mapping/
│   ├── session-09-container-lifecycle/
│   ├── session-10-logs-exec-inspect-troubleshooting/
│   ├── session-11-image-layers/
│   ├── session-12-first-dockerfile/
│   └── session-13-dockerfile-from-run-copy-cmd-entrypoint/
├── volumes/
│   └── session-21-volume-vs-bind-mount/
├── networking/
│   ├── session-24-network-basics/
│   ├── session-25-bridge-network/
│   ├── session-26-host-network/
│   ├── session-27-container-to-container-communication/
│   ├── session-28-docker-internal-dns/
│   ├── session-29-user-defined-bridge-network/
│   └── session-30-app-database-network/
├── compose/
│   ├── session-32-first-compose-yaml/
│   ├── session-33-service-image-build-ports/
│   ├── session-34-environment-env-file/
│   ├── session-35-volumes/
│   ├── session-36-networks/
│   ├── session-37-depends-on-restart/
│   └── session-38-web-db-redis/
├── registry/
│   ├── session-39-registry-basics/
│   ├── session-40-docker-hub/
│   ├── session-41-private-registry/
│   ├── session-42-push-pull-image/
│   ├── session-43-connect-docker-to-nexus/
│   ├── session-44-nexus-login/
│   └── session-45-build-server-nexus-deploy-server/
├── cicd/
│   ├── session-46-docker-in-pipeline/
│   ├── session-47-build-image-gitlab-runner/
│   ├── session-48-image-tag-strategy/
│   ├── session-49-push-to-nexus-from-pipeline/
│   ├── session-50-deploy-with-ssh/
│   ├── session-51-simple-rollback-previous-tag/
│   └── session-52-complete-gitlab-ci-yml-for-docker/
├── security/
│   ├── session-53-container-vs-vm-security/
│   ├── session-54-non-root-container-user/
│   ├── session-55-limiting-privilege/
│   ├── session-56-secrets-environment-variables/
│   ├── session-57-image-scanning-trivy/
│   ├── session-58-gitleaks-secret-scanning/
│   └── session-59-docker-bench-security/
├── monitoring/
│   ├── session-60-docker-logging/
│   └── session-62-cadvisor/
├── production/
│   └── session-71-zero-downtime-deploy/
├── swarm/
│   ├── session-75-swarm-rolling-update/
│   └── session-76-compose-vs-swarm/
├── .github/workflows/
├── README.md
├── SECURITY.md
└── LICENSE
```

## Available labs

### Docker Fundamentals

| Session | Topic | Lab directory | Execution host |
|---|---|---|---|
| 01 | Docker installation and Engine verification | [`fundamentals/session-01-docker-basics`](fundamentals/session-01-docker-basics/) | Docker host |
| 02 | VM vs Container | [`fundamentals/session-02-vm-vs-container`](fundamentals/session-02-vm-vs-container/) | Docker host |
| 03 | Docker architecture | [`fundamentals/session-03-docker-architecture`](fundamentals/session-03-docker-architecture/) | Docker host |
| 04 | Install Docker on Ubuntu | [`fundamentals/session-04-install-docker-ubuntu`](fundamentals/session-04-install-docker-ubuntu/) | Docker host |
| 05 | First real container with Nginx | [`fundamentals/session-05-first-nginx-container`](fundamentals/session-05-first-nginx-container/) | Docker host |
| 06 | Running containers with `docker run` | [`fundamentals/session-06-docker-run`](fundamentals/session-06-docker-run/) | Docker host |
| 07 | Foreground vs Detached mode | [`fundamentals/session-07-foreground-detached-mode`](fundamentals/session-07-foreground-detached-mode/) | Docker host |
| 08 | Docker port mapping | [`fundamentals/session-08-port-mapping`](fundamentals/session-08-port-mapping/) | Docker host |
| 09 | Container lifecycle: list, stop, start, restart, remove | [`fundamentals/session-09-container-lifecycle`](fundamentals/session-09-container-lifecycle/) | Docker host |
| 10 | Logs, exec, inspect, and container troubleshooting | [`fundamentals/session-10-logs-exec-inspect-troubleshooting`](fundamentals/session-10-logs-exec-inspect-troubleshooting/) | Docker host |
| 11 | Docker images and layers | [`fundamentals/session-11-image-layers`](fundamentals/session-11-image-layers/) | Docker host |
| 12 | Build your first Dockerfile | [`fundamentals/session-12-first-dockerfile`](fundamentals/session-12-first-dockerfile/) | Docker host |
| 13 | Dockerfile instructions: FROM, RUN, COPY, CMD, ENTRYPOINT | [`fundamentals/session-13-dockerfile-from-run-copy-cmd-entrypoint`](fundamentals/session-13-dockerfile-from-run-copy-cmd-entrypoint/) | Docker host |

### Docker Volumes and Data Persistence

| Session | Topic | Lab directory | Execution host |
|---|---|---|---|
| 21 | Volume vs Bind Mount | [`volumes/session-21-volume-vs-bind-mount`](volumes/session-21-volume-vs-bind-mount/) | Docker host |

### Docker Networking

| Session | Topic | Lab directory | Execution host |
|---|---|---|---|
| 24 | Docker networking basics | [`networking/session-24-network-basics`](networking/session-24-network-basics/) | Docker host |
| 25 | Bridge Network | [`networking/session-25-bridge-network`](networking/session-25-bridge-network/) | Docker host |
| 26 | Docker host network | [`networking/session-26-host-network`](networking/session-26-host-network/) | Docker host |
| 27 | Container-to-container communication | [`networking/session-27-container-to-container-communication`](networking/session-27-container-to-container-communication/) | Docker host |
| 28 | Docker internal DNS | [`networking/session-28-docker-internal-dns`](networking/session-28-docker-internal-dns/) | Docker host |
| 29 | User-defined bridge network | [`networking/session-29-user-defined-bridge-network`](networking/session-29-user-defined-bridge-network/) | `DEV-1` |
| 30 | App + Database on a separate network | [`networking/session-30-app-database-network`](networking/session-30-app-database-network/) | Docker host |

### Docker Compose

| Session | Topic | Lab directory | Execution host |
|---|---|---|---|
| 32 | First `compose.yaml` | [`compose/session-32-first-compose-yaml`](compose/session-32-first-compose-yaml/) | `DEV-1` |
| 33 | `service`, `image`, `build`, and `ports` | [`compose/session-33-service-image-build-ports`](compose/session-33-service-image-build-ports/) | `DEV-1` |
| 34 | `environment`, `env_file`, and `.env` interpolation | [`compose/session-34-environment-env-file`](compose/session-34-environment-env-file/) | `DEV-1` + `DEV-2` |
| 35 | Volumes and PostgreSQL data persistence | [`compose/session-35-volumes`](compose/session-35-volumes/) | `DEV-1` |
| 36 | Docker Compose networks | [`compose/session-36-networks`](compose/session-36-networks/) | `DEV-1` |
| 37 | `depends_on` and restart policy | [`compose/session-37-depends-on-restart`](compose/session-37-depends-on-restart/) | `DEV-2` |
| 38 | Real Web + PostgreSQL + Redis stack | [`compose/session-38-web-db-redis`](compose/session-38-web-db-redis/) | `DEV-1` |

### Registry and Nexus

| Session | Topic | Lab directory | Execution host |
|---|---|---|---|
| 39 | Docker Registry fundamentals: registry, repository, tag, digest, push, and pull | [`registry/session-39-registry-basics`](registry/session-39-registry-basics/) | `DEV-1` + `DEV-2` |
| 40 | Docker Hub: build, tag, push, pull, and run | [`registry/session-40-docker-hub`](registry/session-40-docker-hub/) | `DEV-1` + `DEV-2` |
| 41 | Private Registry fundamentals and push/pull lab | [`registry/session-41-private-registry`](registry/session-41-private-registry/) | `DEV-1` + `DEV-2` |
| 42 | Push and pull images with Nexus | [`registry/session-42-push-pull-image`](registry/session-42-push-pull-image/) | `DEV-1` + `DEV-2` |
| 43 | Connect Docker to Nexus | [`registry/session-43-connect-docker-to-nexus`](registry/session-43-connect-docker-to-nexus/) | `DEV-1` + `DEV-2` |
| 44 | Login to Nexus Docker Registry and authentication troubleshooting | [`registry/session-44-nexus-login`](registry/session-44-nexus-login/) | `DEV-1` + `DEV-2` |
| 45 | Build Server → Nexus → Deploy Server | [`registry/session-45-build-server-nexus-deploy-server`](registry/session-45-build-server-nexus-deploy-server/) | `DEV-1` + `DEV-2` |

### Docker in CI/CD

| Session | Topic | Lab directory | Execution host |
|---|---|---|---|
| 46 | Docker's role in the CI/CD pipeline: build, test, push, pull, and deploy | [`cicd/session-46-docker-in-pipeline`](cicd/session-46-docker-in-pipeline/) | `DEV-1` + `DEV-2` |
| 47 | Build a Docker image in GitLab Runner with a Shell executor and commit-SHA tagging | [`cicd/session-47-build-image-gitlab-runner`](cicd/session-47-build-image-gitlab-runner/) | `DEV-1` |
| 48 | Docker image tag strategy with commit SHA and branch/ref tags | [`cicd/session-48-image-tag-strategy`](cicd/session-48-image-tag-strategy/) | `DEV-1` |
| 49 | Push Docker images to Nexus from a GitLab pipeline | [`cicd/session-49-push-to-nexus-from-pipeline`](cicd/session-49-push-to-nexus-from-pipeline/) | `DEV-1` |
| 50 | Deploy a commit-tagged Docker image to a remote server over SSH | [`cicd/session-50-deploy-with-ssh`](cicd/session-50-deploy-with-ssh/) | `DEV-1` + `DEV-2` |
| 51 | Roll back to a previous known-good Docker image tag | [`cicd/session-51-simple-rollback-previous-tag`](cicd/session-51-simple-rollback-previous-tag/) | `DEV-1` + `DEV-2` |
| 52 | Complete GitLab CI/CD pipeline for Docker build, test, push, deploy, verify, and rollback | [`cicd/session-52-complete-gitlab-ci-yml-for-docker`](cicd/session-52-complete-gitlab-ci-yml-for-docker/) | `DEV-1` + `DEV-2` |

### Docker Security

| Session | Topic | Lab directory | Execution host |
|---|---|---|---|
| 53 | Why a container is not safer than a VM | [`security/session-53-container-vs-vm-security`](security/session-53-container-vs-vm-security/) | `DEV-1` |
| 54 | Run containers as a non-root user with fixed UID/GID and bind-mount permission checks | [`security/session-54-non-root-container-user`](security/session-54-non-root-container-user/) | `DEV-1` |
| 55 | Limiting container privileges with Linux capabilities and no-new-privileges | [`security/session-55-limiting-privilege`](security/session-55-limiting-privilege/) | `DEV-1` |
| 56 | Secrets, environment variables, Compose secrets, and BuildKit secret mounts | [`security/session-56-secrets-environment-variables`](security/session-56-secrets-environment-variables/) | `DEV-1` |
| 57 | Image scanning with Trivy, severity filtering, JSON reports, and CI/CD security gates | [`security/session-57-image-scanning-trivy`](security/session-57-image-scanning-trivy/) | `DEV-1` |
| 58 | Secret scanning with Gitleaks: current files, Git history, reports, and GitLab CI security gate | [`security/session-58-gitleaks-secret-scanning`](security/session-58-gitleaks-secret-scanning/) | `DEV-1` |
| 59 | Docker Bench Security: host/runtime audit, WARN review, hardening, and before/after evidence | [`security/session-59-docker-bench-security`](security/session-59-docker-bench-security/) | `DEV-1` |

### Docker Logging and Monitoring

| Session | Topic | Lab directory | Execution host |
|---|---|---|---|
| 60 | Docker logs, stdout/stderr, logging drivers, log rotation, and daemon logs | [`monitoring/session-60-docker-logging`](monitoring/session-60-docker-logging/) | `DEV-1` |
| 62 | Monitor Docker containers with cAdvisor and inspect Prometheus metrics | [`monitoring/session-62-cadvisor`](monitoring/session-62-cadvisor/) | `DEV-2` |

### Docker in Production

| Session | Topic | Lab directory | Execution host |
|---|---|---|---|
| 71 | Simple zero-downtime Blue/Green deployment with Nginx | [`production/session-71-zero-downtime-deploy`](production/session-71-zero-downtime-deploy/) | `DEV-2` |

### Docker Swarm

| Session | Topic | Lab directory | Execution host |
|---|---|---|---|
| 75 | Swarm rolling update and rollback | [`swarm/session-75-swarm-rolling-update`](swarm/session-75-swarm-rolling-update/) | `DEV-1` + `DEV-2` |
| 76 | Docker Compose vs Docker Swarm | [`swarm/session-76-compose-vs-swarm`](swarm/session-76-compose-vs-swarm/) | `DEV-1` + `DEV-2` |

Each lab is isolated in its own directory and contains the files and documentation needed for that scenario.

## Clone the repository

```bash
git clone https://github.com/Arezoudehghan/devops-docker-labs.git
cd devops-docker-labs
```

Then enter the directory for the lab you want to run and follow its `README.md`.

## Repository rules

- Never commit real secrets or a real `.env` file.
- Use `.env.example` only as a safe template.
- Validate Compose files with `docker compose config --quiet` before starting a lab.
- Validate Swarm stack files with `docker stack config` before deployment.
- Validate deployment scripts with `bash -n` before running them.
- Do not run labs on the same host when they publish conflicting host ports.
- Read cleanup warnings before removing volumes or other persistent data.

## Automated validation

GitHub Actions validates the Compose configurations, shell-script syntax, Docker image builds, Python syntax, and the Swarm stack configuration on pushes to `main` and on pull requests.

## Portfolio organization

This repository is for Docker-focused learning labs. Independent end-to-end portfolio projects should live in their own repositories, while Kubernetes, Ansible, GitLab CI/CD, and monitoring labs can each have dedicated lab repositories.

## License

This repository is licensed under the [MIT License](LICENSE).

## Scope

These projects are educational labs. Production deployments also require organization-specific secrets management, TLS, access control, monitoring, backup, resource limits, and change-management procedures.

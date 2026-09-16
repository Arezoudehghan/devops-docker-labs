# DevOps Docker Labs

[![Validate DevOps Docker Labs](https://github.com/Arezoudehghan/devops-docker-labs/actions/workflows/validate.yml/badge.svg)](https://github.com/Arezoudehghan/devops-docker-labs/actions/workflows/validate.yml)

A structured collection of hands-on Docker labs covering Docker fundamentals, persistent storage, Docker Compose, networking, production practices, Docker Swarm, and deployment scenarios in a two-VM DevOps learning environment.

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
│   └── session-24-network-basics/
├── compose/
│   ├── session-36-networks/
│   └── session-37-depends-on-restart/
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

### Docker Compose

| Session | Topic | Lab directory | Execution host |
|---|---|---|---|
| 36 | Docker Compose networks | [`compose/session-36-networks`](compose/session-36-networks/) | `DEV-1` |
| 37 | `depends_on` and restart policy | [`compose/session-37-depends-on-restart`](compose/session-37-depends-on-restart/) | `DEV-2` |

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

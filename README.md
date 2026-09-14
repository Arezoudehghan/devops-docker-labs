# DevOps Docker Labs

[![Validate DevOps Docker Labs](https://github.com/Arezoudehghan/docker-compose-labs/actions/workflows/validate.yml/badge.svg)](https://github.com/Arezoudehghan/docker-compose-labs/actions/workflows/validate.yml)

A structured collection of hands-on Docker labs covering Docker Compose, networking, production practices, Docker Swarm, and deployment scenarios in a two-VM DevOps learning environment.

## Lab environment

| Host | Address | Primary role |
|---|---|---|
| `DEV-1` | `192.0.2.10` | Build, GitLab, Runner, Nexus, and client tests |
| `DEV-2` | `192.0.2.11` | Deploy, Docker, Swarm worker, and monitoring |

> `192.0.2.10` and `192.0.2.11` are documentation-only example addresses. Replace them with the addresses assigned to your own lab VMs.

## Repository structure

```text
.
├── compose/
│   ├── session-36-networks/
│   └── session-37-depends-on-restart/
├── swarm/
│   └── session-75-swarm-rolling-update/
├── .github/workflows/
├── README.md
├── SECURITY.md
└── LICENSE
```

## Available labs

### Docker Compose

| Session | Topic | Lab directory | Execution host |
|---|---|---|---|
| 36 | Docker Compose networks | [`compose/session-36-networks`](compose/session-36-networks/) | `DEV-1` |
| 37 | `depends_on` and restart policy | [`compose/session-37-depends-on-restart`](compose/session-37-depends-on-restart/) | `DEV-2` |

### Docker Swarm

| Session | Topic | Lab directory | Execution host |
|---|---|---|---|
| 75 | Swarm rolling update and rollback | [`swarm/session-75-swarm-rolling-update`](swarm/session-75-swarm-rolling-update/) | `DEV-1` + `DEV-2` |

Each lab is isolated in its own directory and contains the files and documentation needed for that scenario.

## Clone the repository

```bash
git clone https://github.com/Arezoudehghan/docker-compose-labs.git
cd docker-compose-labs
```

Then enter the directory for the lab you want to run and follow its `README.md`.

## Repository rules

- Never commit real secrets or a real `.env` file.
- Use `.env.example` only as a safe template.
- Validate Compose files with `docker compose config --quiet` before starting a lab.
- Validate Swarm stack files with `docker stack config` before deployment.
- Do not run labs on the same host when they publish conflicting host ports.
- Read cleanup warnings before removing volumes or other persistent data.

## Automated validation

GitHub Actions validates the Compose configurations, shell-script syntax, Python syntax, Docker image builds, and the Swarm stack configuration on pushes to `main` and on pull requests.

## Portfolio organization

This repository is for Docker-focused learning labs. Independent end-to-end portfolio projects should live in their own repositories, while Kubernetes, Ansible, GitLab CI/CD, and monitoring labs can each have dedicated lab repositories.

## License

This repository is licensed under the [MIT License](LICENSE).

## Scope

These projects are educational labs. Production deployments also require organization-specific secrets management, TLS, access control, monitoring, backup, resource limits, and change-management procedures.

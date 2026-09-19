# Session 39 — What Is a Docker Registry?

Chapter 7 of the DevOps Docker course introduces container registries and the role of Nexus in a Docker image delivery workflow.

## Learning objectives

- Explain what a Docker Registry is.
- Distinguish a registry, repository, image, tag, and digest.
- Understand the `build -> tag -> push -> pull -> run` workflow.
- Compare public and private registries.
- Understand why registries are important in CI/CD and Kubernetes.
- Understand where Nexus Repository fits as a private Docker registry and repository manager.

## Lab environment

The course architecture uses:

- `DEV-1`: build host, GitLab Runner, Docker, and Nexus/registry services.
- `DEV-2`: deployment host that pulls and runs images.
- The examples in this session are conceptual. A Nexus Docker registry is configured in later sessions.

## Project structure

```text
session-39-registry-basics/
├── README.md
└── docs/
    └── DevOps_Registry_What_Is_Registry_Session_39_Commands_CheatSheet.txt
```

## Core concept

A Docker Registry is a centralized service used to store, manage, and distribute container images.

The basic flow is:

```text
Developer / CI
      |
      | docker build
      v
Local Docker Image
      |
      | docker push
      v
Docker Registry
      |
      | docker pull
      v
Deployment Host
      |
      | docker run
      v
Container
```

## Registry, repository, tag, and digest

A full image reference can look like:

```text
registry.company.local/devops/payment-api:1.5
```

Its parts are:

- Registry: `registry.company.local`
- Namespace/project: `devops`
- Repository: `payment-api`
- Tag: `1.5`

A digest such as `sha256:...` identifies image content more precisely than a mutable tag.

## Public and private registries

Public registries provide images for general use. Docker Hub is a common example.

Private registries are used by organizations to store internal application images, control access, integrate with CI/CD, and reduce direct dependency on public registries.

## Build, tag, and push

Build a local image:

```bash
docker build -t myapp:1.0 .
```

Create a registry-qualified image reference:

```bash
docker tag myapp:1.0 registry.company.local/myapp:1.0
```

Push the image to the registry:

```bash
docker push registry.company.local/myapp:1.0
```

On another Docker host, pull the image:

```bash
docker pull registry.company.local/myapp:1.0
```

Then run it:

```bash
docker run -d registry.company.local/myapp:1.0
```

## Pull and digest practice

Pull a public image:

```bash
docker pull nginx:alpine
```

List local images:

```bash
docker image ls
```

Show image digests:

```bash
docker image ls --digests
```

Pulling the same image again demonstrates Docker's layer reuse behavior:

```bash
docker pull nginx:alpine
```

## Authentication

A private registry commonly requires authentication:

```bash
docker login registry.company.local
```

Log out when needed:

```bash
docker logout registry.company.local
```

Production registries should use properly configured TLS/HTTPS.

## Why registries matter in CI/CD

A typical delivery workflow is:

```text
git push
   |
   v
GitLab
   |
   v
Pipeline
   |
   | docker build
   v
Docker Image
   |
   | docker push
   v
Private Registry / Nexus
   |
   | docker pull
   v
DEV-2 / Production
   |
   | docker run
   v
Application
```

This is more scalable and reproducible than moving image archives manually between servers.

## Nexus Repository

Nexus Repository is a repository manager that can host Docker repositories in addition to package formats such as Maven, npm, PyPI, NuGet, and raw files.

For Docker, the three important Nexus repository types are:

- Hosted: stores the organization's own images.
- Proxy: caches images from an upstream registry.
- Group: exposes multiple repositories through one endpoint.

Nexus configuration and hands-on registry setup are covered in later sessions.

## Commands cheat sheet

The complete command cheat sheet for this lesson is stored at:

`docs/DevOps_Registry_What_Is_Registry_Session_39_Commands_CheatSheet.txt`

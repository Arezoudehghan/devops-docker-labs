# Session 56 — Secrets and Environment Variables

Chapter 9 — Docker Security

This lab demonstrates why passwords, tokens, API keys, and private credentials should not be hardcoded in Dockerfiles or passed as normal container environment variables when a safer secret mechanism is available.

## Execution host

Run the lab on DEV-1.

## Repository files

- compose-env-demo.yaml: demonstrates a sensitive value exposed as a container environment variable.
- compose.yaml: demonstrates Docker Compose secrets mounted under /run/secrets.
- .env.example: safe non-secret configuration template.
- build-secret-demo/Dockerfile: demonstrates BuildKit secret mounts during image build.
- docs/DevOps_Docker_Secrets_Environment_Variables_Session_56_Commands_CheatSheet.txt: command cheat sheet for this lesson.

## 1. Environment-variable exposure demo

Set temporary demo values in your shell:

~~~bash
export APP_MODE=production
export DB_PASSWORD='demo-only-secret-56'
~~~

Validate the demonstration Compose file:

~~~bash
docker compose -f compose-env-demo.yaml config
~~~

Start the container:

~~~bash
docker compose -f compose-env-demo.yaml up -d
~~~

Inspect its environment:

~~~bash
docker inspect session56-env-app \
  --format '{{range .Config.Env}}{{println .}}{{end}}'
~~~

The DB_PASSWORD value is visible in the container configuration because it was passed as a normal environment variable.

Clean up the demonstration container:

~~~bash
docker compose -f compose-env-demo.yaml down
~~~

## 2. Docker Compose secret

Create the local secret directory. This directory is intentionally excluded from Git:

~~~bash
mkdir -p secrets
~~~

Create a local demo password file:

~~~bash
printf '%s' 'change-me-locally-56' > secrets/db_password.txt
chmod 600 secrets/db_password.txt
~~~

Validate the secure Compose file:

~~~bash
docker compose config
~~~

Start the service:

~~~bash
docker compose up -d
~~~

Verify that the secret is mounted:

~~~bash
docker exec session56-secret-app ls -l /run/secrets
~~~

Verify that DB_PASSWORD was not added to the container environment:

~~~bash
docker inspect session56-secret-app \
  --format '{{range .Config.Env}}{{println .}}{{end}}' \
  | grep DB_PASSWORD || echo "DB_PASSWORD is NOT in container environment"
~~~

Clean up:

~~~bash
docker compose down
~~~

## 3. BuildKit build secret

Enter the BuildKit demo directory:

~~~bash
cd build-secret-demo
~~~

Create a local build secret. The file is ignored by Git:

~~~bash
printf '%s' 'change-me-build-secret-56' > build-token.txt
chmod 600 build-token.txt
~~~

Build the image with a temporary secret mount:

~~~bash
docker build \
  --secret id=build_token,src=./build-token.txt \
  -t session56-build-secret:1.0 \
  .
~~~

Verify that the build secret is not present at runtime:

~~~bash
docker run --rm \
  session56-build-secret:1.0 \
  sh -c 'if [ -e /run/secrets/build_token ]; then echo "SECRET FOUND"; else echo "SECRET NOT FOUND"; fi'
~~~

Remove the test image when finished:

~~~bash
docker image rm session56-build-secret:1.0
~~~

## Security rules demonstrated

- Use environment variables for non-sensitive configuration such as ports, hosts, modes, and log levels.
- Do not treat a .env file as a secret manager.
- Do not hardcode passwords, API keys, tokens, or private keys in Dockerfiles or Compose files.
- Keep real secret files out of Git.
- Grant a secret only to the service that needs it.
- Use BuildKit secret mounts for credentials required only during image build.
- Docker Compose secrets and Docker Swarm secrets are related concepts but are not the same implementation.

## Commands cheat sheet

See:

docs/DevOps_Docker_Secrets_Environment_Variables_Session_56_Commands_CheatSheet.txt

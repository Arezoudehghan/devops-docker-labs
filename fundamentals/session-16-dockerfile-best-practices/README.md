# Session 16 — Dockerfile Best Practices

This lab demonstrates a small production-oriented Dockerfile with cache-friendly instruction ordering, a slim base image, `.dockerignore`, pip cache cleanup, and a non-root runtime user.

## Files

- `Dockerfile` — optimized Python image build
- `.dockerignore` — removes unnecessary files from the build context
- `app.py` — minimal HTTP application listening on port `5000`
- `requirements.txt` — dependency file copied before application source to preserve build cache
- `DevOps_Dockerfile_Best_Practices_Session_16_Commands_CheatSheet.txt` — commands used in this lesson with English explanations

## Build

```bash
docker build -t best-app:v1 .
```

## Run

```bash
docker run -d \
  --name best-app \
  -p 8080:5000 \
  best-app:v1
```

Open `http://127.0.0.1:8080` or verify with curl:

```bash
curl http://127.0.0.1:8080
```

Expected application response:

```text
Dockerfile best practices lab
```

## Verify non-root execution

```bash
docker exec best-app whoami
```

Expected user:

```text
appuser
```

## Inspect image layers

```bash
docker history best-app:v1
```

## Best-practice points demonstrated

- Use a suitable slim base image.
- Copy dependency files before frequently changing application files to improve build-cache reuse.
- Use `pip install --no-cache-dir` to avoid keeping pip download cache in the image.
- Keep unnecessary files out of the build context with `.dockerignore`.
- Run the application as a dedicated non-root user.
- Use exec-form `CMD`.
- Do not store passwords, tokens, or other secrets in the Dockerfile.

## Cleanup

```bash
docker rm -f best-app
```

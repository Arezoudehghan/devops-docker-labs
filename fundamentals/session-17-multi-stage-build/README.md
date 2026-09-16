# Session 17 — Multi-stage Build

This lab demonstrates Docker multi-stage builds by compiling a Go application in a builder stage and copying only the compiled binary into a smaller Alpine runtime image.

## Files

- `Dockerfile` — multi-stage build with separate builder and runtime stages
- `main.go` — minimal HTTP application listening on port `8080`
- `go.mod` — Go module definition
- `DevOps_Multi-stage_Build_Session_17_Commands_CheatSheet.txt` — commands used in this lesson with English explanations

## Build

```bash
docker build -t multistage-demo:v1 .
```

## Run

```bash
docker run \
  -d \
  --name multistage-demo \
  -p 8080:8080 \
  multistage-demo:v1
```

## Verify

```bash
curl http://localhost:8080
```

Expected response:

```text
Multi-stage Build works!
```

Check the container logs:

```bash
docker logs multistage-demo
```

Check that the Go compiler is not present in the runtime image:

```bash
docker exec multistage-demo go version
```

The command should fail because the final image is based on Alpine and only receives the compiled application binary from the builder stage.

## Inspect the runtime image

```bash
docker exec -it multistage-demo sh
ls -lah /app
```

## Build the builder stage separately

```bash
docker build \
  --target builder \
  -t multistage-demo:builder \
  .
```

Compare image sizes:

```bash
docker image ls \
  --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}'
```

## Key concept

The builder stage contains the compiler, source code, and build tools. The runtime stage receives only the compiled artifact, producing a cleaner and smaller production image.

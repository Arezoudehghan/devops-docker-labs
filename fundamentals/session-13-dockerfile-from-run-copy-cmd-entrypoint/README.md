# Session 13 — Dockerfile: FROM, RUN, COPY, CMD, ENTRYPOINT

This lab demonstrates the core Dockerfile instructions used to build an image and define a container's runtime process.

## Files

- `Dockerfile` — builds the Session 13 image.
- `hello.sh` — simple executable used as the image `ENTRYPOINT`.
- `DevOps_Dockerfile_FROM_RUN_COPY_CMD_ENTRYPOINT_Session_13_Commands_CheatSheet.txt` — commands used in this lesson with beginner-friendly English explanations.

## Build the image

```bash
docker build -t lesson13:v1 .
```

## List local images

```bash
docker image ls
```

## Run with the default CMD

```bash
docker run --rm lesson13:v1
```

The Dockerfile combines:

```dockerfile
ENTRYPOINT ["/app/hello.sh"]
CMD ["Docker"]
```

so the container runs:

```text
/app/hello.sh Docker
```

## Override the default CMD

```bash
docker run --rm lesson13:v1 Arezou
```

This keeps the `ENTRYPOINT` and replaces the default `CMD` argument.

## Inspect ENTRYPOINT and CMD

```bash
docker image inspect lesson13:v1 --format '{{json .Config.Entrypoint}}'
docker image inspect lesson13:v1 --format '{{json .Config.Cmd}}'
```

## Inspect image history

```bash
docker history lesson13:v1
```

## Override ENTRYPOINT for troubleshooting

```bash
docker run --rm --entrypoint /bin/sh hello:v1
```

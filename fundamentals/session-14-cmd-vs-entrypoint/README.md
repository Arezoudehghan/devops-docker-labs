# Session 14 — CMD vs ENTRYPOINT

This lab demonstrates how Docker `CMD` and `ENTRYPOINT` behave when a container starts and when runtime arguments are supplied.

## Files

- `Dockerfile.cmd` — demonstrates a default command that can be replaced at runtime.
- `Dockerfile.entrypoint` — demonstrates a fixed executable with default arguments.
- `DevOps_CMD_vs_ENTRYPOINT_Session_14_Commands_CheatSheet.txt` — command reference for this lesson.

## Lab 1 — CMD

Build the CMD image:

```bash
docker build -f Dockerfile.cmd -t cmd-demo .
```

Run the default CMD:

```bash
docker run --rm cmd-demo
```

Override the CMD at runtime:

```bash
docker run --rm cmd-demo echo "CMD replaced"
```

Inspect the image CMD:

```bash
docker image inspect cmd-demo --format '{{json .Config.Cmd}}'
```

## Lab 2 — ENTRYPOINT + CMD

Build the ENTRYPOINT image:

```bash
docker build -f Dockerfile.entrypoint -t entrypoint-demo .
```

Run it with the default CMD argument:

```bash
docker run --rm entrypoint-demo
```

Replace the default CMD argument while keeping the ENTRYPOINT:

```bash
docker run --rm entrypoint-demo "Hello Arezou"
```

Inspect both ENTRYPOINT and CMD:

```bash
docker image inspect entrypoint-demo --format 'ENTRYPOINT={{json .Config.Entrypoint}} CMD={{json .Config.Cmd}}'
```

## Key behavior demonstrated

- `CMD` provides a default command or default arguments and is replaced by arguments supplied after the image name.
- `ENTRYPOINT` defines the main executable.
- When both are present, `CMD` normally supplies default arguments to `ENTRYPOINT`.

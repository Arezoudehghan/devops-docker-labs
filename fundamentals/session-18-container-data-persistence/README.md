# Session 18 — Why Container Data Disappears

This lab demonstrates why data written only to a container's writable layer is not persistent after the container is removed.

The key idea is simple:

- `docker stop` keeps the container and its writable layer.
- `docker start` starts the same container again, so its existing data is still available.
- `docker rm` removes the container and its writable layer.
- A new container created from the same image gets a new writable layer and does not contain runtime data from the removed container.

## Files

- `README.md` — lab instructions and learning notes
- `DevOps_Docker_Data_Persistence_Session_18_Commands_CheatSheet.txt` — commands used in this lesson with beginner-friendly English explanations

## Lab 1 — Create runtime data inside a container

Start an Ubuntu container and keep it running:

```bash
docker run -d --name data-test ubuntu sleep infinity
```

Create a file inside the container:

```bash
docker exec data-test sh -c 'echo "My Important Data" > /data.txt'
```

Read the file:

```bash
docker exec data-test cat /data.txt
```

Expected content:

```text
My Important Data
```

## Lab 2 — Stop and start the same container

Stop the container:

```bash
docker stop data-test
```

Start the same container again:

```bash
docker start data-test
```

Verify the file still exists:

```bash
docker exec data-test cat /data.txt
```

The file remains because the original container and its writable layer still exist.

## Lab 3 — Remove and recreate the container

Remove the container:

```bash
docker rm -f data-test
```

Create a new container from the same image:

```bash
docker run -d --name data-test ubuntu sleep infinity
```

Check for the old file:

```bash
docker exec data-test cat /data.txt
```

The new container does not contain `/data.txt` because the old writable layer was deleted with the old container.

## Lab 4 — Inspect writable-layer changes

Create another runtime file:

```bash
docker exec data-test sh -c 'echo "Docker Test" > /test.txt'
```

Inspect filesystem changes compared with the original image:

```bash
docker diff data-test
```

A result such as the following shows that the file was added to the container's writable layer:

```text
A /test.txt
```

## Temporary container behavior

Run a container with automatic removal:

```bash
docker run --rm ubuntu echo "hello"
```

The `--rm` option removes the container automatically when its process exits, so data stored only in that container's writable layer should be treated as temporary.

## Key lesson

```text
Image + Writable Layer = Container

Remove Container = Remove Writable Layer

Remove Container != Remove Volume
```

Persistent application data should be stored outside the container writable layer, for example in a Docker volume or another suitable persistent storage system.

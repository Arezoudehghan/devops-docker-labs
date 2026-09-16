# Session 11 — Docker Images and Layers

## Pull and list images

```bash
docker pull nginx
docker images
docker image ls
```

## Run multiple containers from the same image

```bash
docker run -d --name web1 nginx
docker run -d --name web2 nginx
docker run -d --name web3 nginx
docker ps
```

Inspect the image configured for a container:

```bash
docker inspect web1
docker inspect web1 --format '{{.Config.Image}}'
```

## Inspect image metadata and layer history

```bash
docker history nginx
docker image inspect nginx
```

You can also inspect an image by its image ID. Replace the sample ID with an ID shown by `docker image ls`:

```bash
docker inspect 123456abcdef
```

## Dockerfile layer and cache example

The following Dockerfile layout keeps dependency installation before application source code so that dependency layers can be reused when only application code changes:

```dockerfile
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install -r requirements.txt

COPY . .

CMD ["python", "app.py"]
```

A less cache-friendly order is:

```dockerfile
FROM python:3.12-slim

COPY . /app

RUN pip install -r /app/requirements.txt
```

## Combining related package-manager operations

Separate Dockerfile instructions:

```dockerfile
RUN apt-get update
RUN apt-get install -y curl
```

Combined in one `RUN` instruction:

```dockerfile
RUN apt-get update && \
    apt-get install -y curl
```

## Container writable layer example

Changes created inside a running container are written to the container's writable layer rather than back into the image. For example, when run inside a container shell:

```bash
touch /tmp/test.txt
```

## Session lab

Pull the image and inspect its history:

```bash
docker pull nginx
docker image ls
docker history nginx
```

Create a test container:

```bash
docker run -d --name layer-test nginx
docker ps
```

Verify which image the container uses:

```bash
docker inspect layer-test --format '{{.Config.Image}}'
```

## Cleanup

```bash
docker rm -f layer-test
```

# Session 15 — Build Docker Image and Tag

## Lab files

This session builds a simple Nginx image from a Dockerfile and practices Docker image tagging.

Project files:

- `Dockerfile`
- `index.html`
- `DevOps_Docker_Build_Image_and_Tag_Session_15_Commands_CheatSheet.txt`

## Build the first image

```bash
docker build -t session15-web:1.0 .
```

List the image:

```bash
docker image ls session15-web
```

## Add tags to the existing image

```bash
docker image tag session15-web:1.0 session15-web:stable
docker image tag session15-web:1.0 session15-web:latest
```

Verify that the tags point to the same image ID:

```bash
docker image inspect session15-web:1.0 --format '{{.Id}}'
docker image inspect session15-web:stable --format '{{.Id}}'
docker image inspect session15-web:latest --format '{{.Id}}'
```

## Run the image

```bash
docker run -d --name session15-test -p 8085:80 session15-web:1.0
docker ps
curl http://localhost:8085
```

## Build a new version

Update `index.html` and build version 2.0:

```bash
printf '<h1>Hello from Docker Version 2</h1>\n' > index.html
docker build -t session15-web:2.0 .
docker image ls session15-web
```

## Multiple tags during one build

```bash
docker build \
  -t session15-web:1.0 \
  -t session15-web:latest \
  .
```

## Alternative Dockerfile

```bash
docker build -f Dockerfile.dev -t myapp:dev .
```

## Build without cache

```bash
docker build --no-cache -t myapp:1.0 .
```

## Registry tagging example

```bash
docker image tag myapp:1.0 nexus.example.local:5000/myapp:1.0
docker push nexus.example.local:5000/myapp:1.0
```

## Key concept

`docker build` creates an image from a Dockerfile and build context. `docker image tag` creates another reference to an existing image without rebuilding it.

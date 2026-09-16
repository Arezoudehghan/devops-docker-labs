# Session 12 — Build Your First Dockerfile

This lab builds a custom Nginx image from a simple Dockerfile and serves a static `index.html` page.

## Files

```text
session-12-first-dockerfile/
├── Dockerfile
├── index.html
├── README.md
└── DevOps_Dockerfile_Session_12_Commands_CheatSheet.txt
```

## Dockerfile

```dockerfile
FROM nginx:alpine

COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80
```

## Build the image

From this directory:

```bash
docker build -t my-web:v1 .
```

Verify the image:

```bash
docker image ls
docker history my-web:v1
docker image inspect my-web:v1
```

## Run the container

```bash
docker run -d --name my-web-container -p 8080:80 my-web:v1
```

Verify the container and web page:

```bash
docker ps
curl http://localhost:8080
docker exec my-web-container cat /usr/share/nginx/html/index.html
```

## Build version 2

Change the page content:

```bash
sed -i 's/Docker is working./Docker Image Version 2/' index.html
```

Build the next image version:

```bash
docker build -t my-web:v2 .
```

Run it on a different host port:

```bash
docker run -d --name my-web-v2 -p 8081:80 my-web:v2
curl http://localhost:8081
```

## Troubleshooting

Check whether host port 8080 is already in use:

```bash
ss -ltnp | grep 8080
docker ps
```

Check all containers if a container name already exists:

```bash
docker ps -a
```

## Cleanup

```bash
docker stop my-web-container my-web-v2
docker rm my-web-container my-web-v2
docker rmi my-web:v1 my-web:v2
```

## Learning objective

The main workflow demonstrated by this lab is:

```text
Dockerfile -> docker build -> Image -> docker run -> Container
```

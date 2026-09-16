# Session 08 — Port Mapping

## Basic port mapping

```bash
docker run -d -p 8080:80 nginx
```

## Named container with published port

```bash
docker run -d --name web1 -p 8080:80 nginx
docker ps
docker port web1
curl http://127.0.0.1:8080
```

## Use a different host port

```bash
docker run -d --name web2 -p 9090:80 nginx
```

## Run multiple Nginx containers on different host ports

```bash
docker run -d --name web1 -p 8081:80 nginx
docker run -d --name web2 -p 8082:80 nginx
docker run -d --name web3 -p 8083:80 nginx
```

## Port conflict example and fix

```bash
docker run -d --name web1 -p 8080:80 nginx
docker run -d --name web2 -p 8080:80 nginx
docker run -d --name web2 -p 8081:80 nginx
```

## Publish multiple ports

```bash
docker run -d \
  --name web \
  -p 8080:80 \
  -p 8443:443 \
  nginx
```

## TCP and UDP publishing

```bash
docker run -p 8080:80/tcp nginx
docker run -p 5353:53/udp IMAGE_NAME
```

## Bind only to localhost

```bash
docker run -d --name private-web -p 127.0.0.1:8080:80 nginx
```

## Publish all exposed ports

```bash
docker run -d -P nginx
docker ps
docker port CONTAINER_NAME
```

## Dockerfile EXPOSE example

```dockerfile
EXPOSE 80
```

## Application port mapping example

```bash
docker run -d \
  --name myapp \
  -p 8088:5000 \
  myapp:1.0
```

## Session lab

```bash
docker rm -f web1 web2 web3 private-web

docker run -d --name lab-web -p 8080:80 nginx
docker ps
docker port lab-web
curl http://127.0.0.1:8080

docker rm -f lab-web

docker run -d --name lab-web -p 9090:80 nginx
curl http://127.0.0.1:9090
```

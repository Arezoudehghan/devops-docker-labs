# Session 05 — First Real Container with Nginx

## Docker checks

```bash
docker --version
sudo systemctl status docker
docker ps
docker ps -a
docker images
docker image ls
```

## Pull and first Nginx container

```bash
docker pull nginx
docker run nginx
```

In another terminal:

```bash
docker ps
```

## Named container in detached mode

```bash
docker run -d --name my-nginx nginx
docker ps
docker stop my-nginx
docker rm my-nginx
```

## Nginx with port mapping

```bash
docker run -d --name my-nginx -p 8080:80 nginx
docker ps
curl http://localhost:8080
docker port my-nginx
docker logs my-nginx
docker logs -f my-nginx
```

## Enter the running container

```bash
docker exec -it my-nginx /bin/bash
hostname
pwd
ls
ps aux
cat /usr/share/nginx/html/index.html
exit
```

## Inspect and monitor

```bash
docker inspect my-nginx
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' my-nginx
docker stats my-nginx
```

## Container lifecycle

```bash
docker stop my-nginx
docker ps
docker ps -a
docker start my-nginx
docker ps
curl http://localhost:8080
```

## Multiple containers from one image

```bash
docker run -d --name nginx-2 -p 8081:80 nginx
docker ps
curl http://localhost:8080
curl http://localhost:8081
```

## Port conflict test

```bash
docker run -d --name nginx-3 -p 8080:80 nginx
```

## Lab challenge

```bash
docker run -d --name web01 -p 8081:80 nginx
docker run -d --name web02 -p 8082:80 nginx
docker run -d --name web03 -p 8083:80 nginx
docker ps
curl http://localhost:8081
curl http://localhost:8082
curl http://localhost:8083
```

## Nginx check inside container

```bash
docker exec web01 nginx -v
```

## Troubleshooting commands

```bash
docker ps
docker logs my-nginx
docker port my-nginx
curl http://localhost:8080
ss -lntp
```

## Cleanup

```bash
docker stop my-nginx
docker stop nginx-2
docker rm -f nginx-3
docker rm my-nginx nginx-2
docker ps -a
docker images
```

## Temporary container

```bash
docker run --rm nginx
```

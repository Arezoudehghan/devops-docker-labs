# Session 06 — Running Containers with `docker run`

## Basic container run

```bash
docker run hello-world
docker ps
docker ps -a
```

## Run Nginx in the foreground and background

```bash
docker run nginx
docker run -d nginx
docker ps
```

## Named container lifecycle

```bash
docker run -d --name web01 nginx
docker ps
docker stop web01
docker ps -a
docker start web01
docker ps
docker stop web01
docker rm web01
```

## Nginx with port mapping

```bash
docker run -d --name web01 -p 8080:80 nginx
docker ps
curl http://localhost:8080
docker port web01
ss -ltnp | grep 8080
```

## Logs, processes, and inspection

```bash
docker logs web01
curl http://localhost:8080
docker logs web01
docker logs -f web01
docker top web01
docker inspect web01
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' web01
```

## Multiple containers from one image

```bash
docker rm -f web01
docker run -d --name web01 -p 8081:80 nginx
docker run -d --name web02 -p 8082:80 nginx
docker run -d --name web03 -p 8083:80 nginx
docker ps
curl http://localhost:8081
curl http://localhost:8082
curl http://localhost:8083
```

## Port conflict test

```bash
docker run -d --name web-conflict -p 8081:80 nginx
docker ps -a
```

Remove the failed test container before continuing:

```bash
docker rm -f web-conflict
```

## Interactive Ubuntu container

```bash
docker run -it --name ubuntu-test ubuntu bash
hostname
cat /etc/os-release
ps aux
exit
docker ps -a
```

## Temporary containers with `--rm`

```bash
docker run --rm hello-world
docker run --rm alpine echo "Docker Test"
docker run --rm alpine hostname
docker run --rm alpine ls /
```

## Environment variables

```bash
docker run --rm -e APP_ENV=production alpine env

docker run --rm \
  -e APP_ENV=production \
  -e APP_PORT=8080 \
  -e APP_NAME=myapp \
  alpine env
```

## Custom hostname

```bash
docker run --rm --hostname app01 alpine hostname
```

## `docker run` versus `docker start`

```bash
docker run --name test01 alpine echo hello
docker ps -a
docker start test01
docker rm test01
```

## `docker create` followed by `docker start`

```bash
docker create --name test01 nginx
docker ps -a
docker start test01
docker ps
docker stop test01
docker rm test01
```

## Full `docker run` example

```bash
docker run -d \
  --name myapp \
  -p 8080:80 \
  -e APP_ENV=production \
  nginx

docker ps
curl http://localhost:8080
docker logs myapp
```

## Troubleshooting commands

```bash
docker ps -a
docker logs web01
docker inspect web01
ss -ltnp
docker images
```

## Lab challenge

Run three Nginx containers from the same image on different host ports:

```bash
docker rm -f web01 web02 web03

docker run -d --name web01 -p 8081:80 nginx
docker run -d --name web02 -p 8082:80 nginx
docker run -d --name web03 -p 8083:80 nginx

docker ps
curl http://localhost:8081
curl http://localhost:8082
curl http://localhost:8083
```

## Environment variable challenge

```bash
docker run --rm \
  -e ENVIRONMENT=dev \
  -e SERVER=dev-1 \
  alpine env
```

## Cleanup

```bash
docker rm -f web01 web02 web03 myapp ubuntu-test
docker ps -a
```

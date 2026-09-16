# Session 07 — Foreground vs Detached Mode

## Foreground mode

```bash
docker run nginx
```

## Detached mode

```bash
docker run -d nginx
docker ps
```

## Named detached container

```bash
docker run -d --name web1 nginx
docker ps
```

## View container logs

```bash
docker logs web1
docker logs -f web1
```

## Foreground container test

```bash
docker run --name fg-test nginx
docker ps
docker ps -a
docker rm fg-test
```

## Detached container test

```bash
docker run -d --name bg-test nginx
docker ps
docker logs bg-test
docker logs -f bg-test
```

## Attach to the main container process

```bash
docker attach bg-test
```

## Run a new shell inside a running container

```bash
docker exec -it bg-test /bin/bash
docker exec -it bg-test /bin/sh
```

## Inspect the container from inside

```bash
hostname
ps
exit
```

## Container lifecycle

```bash
docker stop web1
docker start web1
docker ps
docker ps -a
```

## Detached application example

```bash
docker run myapp
docker run -d --name myapp myapp:1.0
docker logs myapp
docker logs -f myapp
docker exec -it myapp /bin/sh
docker stop myapp
```

## Short-lived process example

```bash
docker run alpine echo "Hello Docker"
docker run -d alpine echo "Hello Docker"
docker ps
docker ps -a
```

## Interactive container example

```bash
docker run -it ubuntu bash
```

## Session lab

```bash
docker run --name test-fg nginx
docker ps
docker ps -a
docker rm test-fg

docker run -d --name test-bg nginx
docker ps
docker logs test-bg
docker logs -f test-bg
docker exec -it test-bg /bin/sh
hostname
ps
exit
docker ps
docker stop test-bg
docker ps -a
docker rm test-bg
```

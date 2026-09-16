# Session 19 — Docker Volumes and Data Persistence

## Create and inspect a named volume

```bash
docker volume create lesson19-data
docker volume ls
docker volume inspect lesson19-data
```

## Start a container with the volume mounted

```bash
docker run -d \
  --name lesson19-container \
  -v lesson19-data:/data \
  alpine \
  sleep infinity

docker ps
```

## Write data into the mounted volume

```bash
docker exec lesson19-container \
  sh -c 'echo "Docker Volume Persistence Test" > /data/test.txt'

docker exec lesson19-container cat /data/test.txt
```

## Remove the container and verify persistence

```bash
docker rm -f lesson19-container
docker ps -a
docker volume ls
```

Create a temporary container and read the file from the same volume:

```bash
docker run --rm \
  -v lesson19-data:/data \
  alpine \
  cat /data/test.txt
```

The expected file content is:

```text
Docker Volume Persistence Test
```

## Shared named volume example

```bash
docker run -d \
  --name app1 \
  -v shared-data:/data \
  alpine \
  sleep infinity

docker run -d \
  --name app2 \
  -v shared-data:/data \
  alpine \
  sleep infinity

docker exec app1 sh -c 'echo hello > /data/file.txt'
docker exec app2 cat /data/file.txt
```

## MySQL named volume example

```bash
docker volume create mysql-data
docker run -d \
  --name mysql-db \
  -e MYSQL_ROOT_PASSWORD=StrongPassword \
  -v mysql-data:/var/lib/mysql \
  mysql:8
```

Remove the MySQL container while keeping the named volume:

```bash
docker rm -f mysql-db
docker volume ls
```

## `--mount` syntax

```bash
docker run -d \
  --name test \
  --mount type=volume,source=mydata,target=/data \
  alpine \
  sleep infinity
```

## Find containers using a volume

```bash
docker ps -a --filter volume=lesson19-data
```

## Remove the lab volume

```bash
docker volume rm lesson19-data
```

> `docker volume rm` works only when the volume is not in use. Review persistent data carefully before deleting a volume.

## Unused-volume cleanup command from the lesson

```bash
docker volume prune
```

> This command removes unused local volumes. Do not run it on an important Docker host without checking which data is no longer attached to containers.

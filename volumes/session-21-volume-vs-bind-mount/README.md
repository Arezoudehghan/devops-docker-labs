# Session 21 — Docker Volume vs Bind Mount

This lab compares Docker-managed named volumes with host-managed bind mounts and demonstrates how both methods keep data outside the lifecycle of a container.

## Named volume

Create a Docker-managed volume:

```bash
docker volume create lesson21-data
docker volume ls
```

Write a file into the volume from a temporary Alpine container:

```bash
docker run --rm \
  -v lesson21-data:/data \
  alpine \
  sh -c 'echo "Created with Volume" > /data/test.txt'
```

Start another temporary container and read the same file:

```bash
docker run --rm \
  -v lesson21-data:/data \
  alpine \
  cat /data/test.txt
```

The container is removed after each run, but the file remains in the named volume.

## Bind mount

Create a host directory:

```bash
mkdir -p ~/lesson21-bind
```

Bind-mount the directory into a temporary Alpine container and create a file:

```bash
docker run --rm \
  -v ~/lesson21-bind:/data \
  alpine \
  sh -c 'echo "Created with Bind Mount" > /data/test.txt'
```

Read the file directly from the host:

```bash
cat ~/lesson21-bind/test.txt
```

With a bind mount, the data lives in a path selected and managed on the host.

## Inspect a Docker volume

```bash
docker volume create app-data
docker volume inspect app-data
```

Docker manages the storage location for a named volume.

## Bind-mount an application directory

```bash
mkdir -p /srv/myapp/data

docker run -d \
  --name myapp \
  -v /srv/myapp/data:/app/data \
  myimage

ls -lah /srv/myapp/data
```

## `--mount` syntax

Named volume:

```bash
docker run -d \
  --name nginx \
  --mount type=volume,source=nginx-data,target=/usr/share/nginx/html \
  nginx
```

Bind mount:

```bash
docker run -d \
  --name nginx \
  --mount type=bind,source=/opt/website,target=/usr/share/nginx/html \
  nginx
```

## Read-only mounts

Bind mount:

```bash
docker run -d \
  -v /opt/config:/app/config:ro \
  myimage
```

Named volume:

```bash
docker run -d \
  -v app-config:/app/config:ro \
  myimage
```

## Database volume examples

MySQL:

```bash
docker volume create mysql-data

docker run -d \
  --name mysql \
  -e MYSQL_ROOT_PASSWORD=StrongPassword \
  -v mysql-data:/var/lib/mysql \
  mysql:8
```

PostgreSQL:

```bash
docker volume create postgres-data

docker run -d \
  --name postgres \
  -e POSTGRES_PASSWORD=StrongPassword \
  -v postgres-data:/var/lib/postgresql/data \
  postgres
```

## Nginx configuration with a bind mount

```bash
docker run -d \
  --name nginx \
  -p 80:80 \
  -v /opt/nginx/nginx.conf:/etc/nginx/nginx.conf:ro \
  nginx
```

## Compose examples

Named volume:

```yaml
services:
  db:
    image: postgres
    environment:
      POSTGRES_PASSWORD: StrongPassword
    volumes:
      - postgres-data:/var/lib/postgresql/data

volumes:
  postgres-data:
```

Bind mount:

```yaml
services:
  web:
    image: myapp
    volumes:
      - ./src:/app/src
```

Using both mount types in one Compose configuration:

```yaml
services:
  web:
    image: nginx
    ports:
      - "8080:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - web-data:/usr/share/nginx/html

volumes:
  web-data:
```

## Security-sensitive bind mounts

These examples expose powerful host resources to a container and should be treated carefully:

```bash
docker run -v /:/host myimage
```

```bash
docker run \
  -v /var/run/docker.sock:/var/run/docker.sock \
  myimage
```

## Key comparison

- Use a named volume when Docker should manage persistent application data.
- Use a bind mount when a specific host file or directory must be directly available inside the container.
- Typical named-volume use cases include database and application data.
- Typical bind-mount use cases include source code, configuration files, certificates, scripts, and other host-managed files.

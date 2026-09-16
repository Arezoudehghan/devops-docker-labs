# Session 27 — Container-to-Container Communication

Hands-on lab for Docker container-to-container communication, embedded DNS, service discovery, internal ports, and network isolation.

## 1. Create a user-defined network

```bash
docker network create app-network
docker network ls
```

## 2. Run two containers on the same network

```bash
docker run -d \
  --name web \
  --network app-network \
  nginx:alpine
```

```bash
docker run -d \
  --name api \
  --network app-network \
  nginx:alpine
```

Verify the containers:

```bash
docker ps
```

## 3. Test Docker DNS and container-name resolution

Open a shell in `web`:

```bash
docker exec -it web sh
```

Test name resolution to `api`:

```bash
ping api
```

Exit the container shell:

```bash
exit
```

Docker's embedded DNS resolves the container name `api` to its current container IP while both containers share the same user-defined network.

## 4. Test HTTP communication without publishing the API port

```bash
docker run --rm \
  --network app-network \
  curlimages/curl \
  http://api
```

The temporary curl container reaches Nginx directly through the internal Docker network. The `api` container does not need `-p` for this container-to-container request.

## 5. Test Redis by service name

Start Redis:

```bash
docker run -d \
  --name redis \
  --network app-network \
  redis:alpine
```

Open an interactive Redis CLI connected by container name:

```bash
docker run --rm -it \
  --network app-network \
  redis:alpine \
  redis-cli -h redis
```

Inside Redis CLI:

```text
PING
```

For a one-command test:

```bash
docker run --rm \
  --network app-network \
  redis:alpine \
  redis-cli -h redis ping
```

## 6. Internal port vs published port

Publish Nginx port 80 on host port 8080:

```bash
docker run -d \
  --name web \
  --network app-network \
  -p 8080:80 \
  nginx
```

For traffic from another container on the same network, use the container name and container port, such as `web:80`. Port publishing with `-p` is for exposing the container port through the Docker host.

## 7. PostgreSQL internal communication example

A database that must also be reachable from the Docker host can publish port 5432:

```bash
docker run -d \
  --name db \
  --network app-network \
  -p 5432:5432 \
  -e POSTGRES_PASSWORD=example \
  postgres
```

If only containers on `app-network` need database access, the host port does not need to be published:

```bash
docker run -d \
  --name db \
  --network app-network \
  -e POSTGRES_PASSWORD=example \
  postgres
```

> Technical correction: the PostgreSQL image requires initialization credentials, so `POSTGRES_PASSWORD=example` is included in these runnable examples.

Applications on the same network should connect to `db:5432`, not `localhost:5432` and not a hard-coded container IP.

## 8. Inspect network membership

```bash
docker network inspect app-network
```

Connect an existing container to the network:

```bash
docker run -d \
  --name test1 \
  nginx
```

```bash
docker network connect app-network test1
```

Disconnect it:

```bash
docker network disconnect app-network test1
```

## 9. Multi-network isolation lab

Create separate frontend and backend networks:

```bash
docker network create frontend-network
docker network create backend-network
```

Run the frontend container:

```bash
docker run -d \
  --name frontend \
  --network frontend-network \
  nginx:alpine
```

Run `api2` on the frontend network:

```bash
docker run -d \
  --name api2 \
  --network frontend-network \
  nginx:alpine
```

Connect `api2` to the backend network too:

```bash
docker network connect backend-network api2
```

Run a backend container only on the backend network:

```bash
docker run -d \
  --name backend \
  --network backend-network \
  nginx:alpine
```

Test frontend-to-API communication:

```bash
docker exec frontend ping -c 2 api2
```

Test frontend-to-backend isolation:

```bash
docker exec frontend ping -c 2 backend
```

Inspect the dual-network API container:

```bash
docker inspect api2
```

`api2` is attached to both networks, while `frontend` and `backend` do not share a network directly.

## 10. Troubleshooting commands

```bash
docker ps
docker network ls
docker inspect web
docker inspect api
docker inspect db
docker logs api
docker network inspect app-network
```

## 11. Cleanup

```bash
docker rm -f web api redis frontend api2 backend test1 2>/dev/null
```

```bash
docker network rm app-network frontend-network backend-network 2>/dev/null
```

## Commands cheat sheet

See [`DevOps_Container-to-Container_Communication_Session_27_Commands_CheatSheet.txt`](DevOps_Container-to-Container_Communication_Session_27_Commands_CheatSheet.txt).

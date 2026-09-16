# Session 28 — Docker Internal DNS

This lab demonstrates Docker embedded DNS, container-name resolution, network aliases, and DNS troubleshooting on user-defined Docker networks.

## Files

```text
session-28-docker-internal-dns/
├── README.md
└── DevOps_Docker_Internal_DNS_Session_28_Commands_CheatSheet.txt
```

## 1. Create a user-defined network

```bash
docker network create app-net
docker network ls
```

## 2. Start a web container on `app-net`

```bash
docker run -d \
  --name web1 \
  --network app-net \
  nginx
```

Inspect the container if needed:

```bash
docker inspect web1
```

## 3. Start a DNS test client

```bash
docker run -it \
  --name client1 \
  --network app-net \
  busybox sh
```

Inside `client1`, test container-name resolution:

```bash
ping web1
nslookup web1
cat /etc/resolv.conf
```

The resolver configuration should show Docker's embedded DNS server at `127.0.0.11` on a user-defined network.

## 4. Compare the default bridge with a user-defined bridge

Start two containers without a custom network:

```bash
docker run -d --name test1 nginx
docker run -it --name test2 busybox sh
```

Inside `test2`, try resolving `test1`:

```bash
ping test1
```

Remove the test containers:

```bash
docker rm -f test1 test2
```

Create a user-defined network and repeat the test:

```bash
docker network create test-net
```

```bash
docker run -d \
  --name test1 \
  --network test-net \
  nginx
```

```bash
docker run -it \
  --name test2 \
  --network test-net \
  busybox sh
```

Inside `test2`:

```bash
ping test1
```

## 5. Test a network alias

Run MySQL with the network alias `database`:

```bash
docker run -d \
  --name mysql-prod-01 \
  --network app-net \
  --network-alias database \
  mysql:8
```

Inspect the network:

```bash
docker network inspect app-net
```

From another container on `app-net`, test the alias:

```bash
ping database
nslookup database
```

## 6. Troubleshoot Docker DNS

Check running containers and networks:

```bash
docker ps
docker network ls
docker network inspect app-net
```

Inspect application containers:

```bash
docker inspect backend
docker inspect database
```

Open a shell inside the backend container:

```bash
docker exec -it backend sh
```

If Bash exists:

```bash
docker exec -it backend bash
```

Inside the container, inspect DNS and test name resolution:

```bash
cat /etc/resolv.conf
ping database
nslookup database
```

You can also run checks directly with `docker exec`:

```bash
docker exec backend cat /etc/resolv.conf
docker exec backend ping db
docker exec client ping backend
```

## 7. Connect and disconnect containers from a network

Connect an existing container to `app-net`:

```bash
docker network connect app-net db
docker network connect app-net backend
```

Disconnect the backend container:

```bash
docker network disconnect app-net backend
```

## 8. Final hands-on DNS test

Create a web container:

```bash
docker run -d \
  --name web \
  --network app-net \
  nginx
```

Create a client container:

```bash
docker run -it \
  --name client \
  --network app-net \
  busybox sh
```

Inside `client`:

```bash
ping web
nslookup web
cat /etc/resolv.conf
```

## Learning objective

The main DNS path demonstrated by this lab is:

```text
Container name / network alias
        -> Docker embedded DNS (127.0.0.11)
        -> Current container IP
        -> Target container
```

Use container or service names instead of hard-coded container IP addresses when containers communicate on a user-defined Docker network.

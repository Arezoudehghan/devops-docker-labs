# Session 29 — User-defined Bridge Network

Hands-on lab for Docker user-defined bridge networks, internal DNS, container isolation, dynamic network attachment, and custom subnets on a single Docker host.

## Lab architecture

```text
Docker Host
│
├── bridge
│   └── outsider
│
└── app-net
    ├── web
    └── client
```

The main goal is to verify that containers on the same user-defined bridge network can communicate by container name through Docker's internal DNS.

## 1. Inspect existing Docker networks

```bash
docker network ls
```

## 2. Create the user-defined bridge network

```bash
docker network create app-net
```

Verify the network:

```bash
docker network ls
docker network inspect app-net
```

Equivalent explicit bridge-driver form:

```bash
docker network create -d bridge app-net
```

> Run only one `docker network create` command for the same `app-net` name.

## 3. Start the web container on `app-net`

```bash
docker run -d \
  --name web \
  --network app-net \
  nginx:alpine
```

The Nginx port is not published to the Docker host because the client container will access it directly through the shared Docker network.

## 4. Start the client container on `app-net`

```bash
docker run -dit \
  --name client \
  --network app-net \
  alpine \
  sh
```

## 5. Verify Docker DNS and connectivity

Resolve and reach the `web` container by name:

```bash
docker exec client ping -c 3 web
```

Check DNS resolution:

```bash
docker exec client nslookup web
```

Test HTTP communication by container name:

```bash
docker exec client wget -qO- http://web
```

Inspect network membership:

```bash
docker network inspect app-net
```

## 6. Test network isolation

Create an Alpine container without attaching it to `app-net`:

```bash
docker run -dit \
  --name outsider \
  alpine \
  sh
```

Test whether it can resolve and reach `web`:

```bash
docker exec outsider ping -c 2 web
```

Because `outsider` is initially on Docker's default bridge and `web` is on `app-net`, this name-based communication should not work.

## 7. Connect a running container to `app-net`

```bash
docker network connect app-net outsider
```

Verify membership:

```bash
docker network inspect app-net
```

Test again:

```bash
docker exec outsider ping -c 3 web
```

The test should now work because `outsider` and `web` share `app-net`.

## 8. Disconnect the running container

```bash
docker network disconnect app-net outsider
```

Verify the network again:

```bash
docker network inspect app-net
```

Retest isolation:

```bash
docker exec outsider ping -c 2 web
```

## 9. Create a bridge network with a custom subnet

```bash
docker network create \
  --driver bridge \
  --subnet 172.30.0.0/24 \
  --gateway 172.30.0.1 \
  backend-net
```

Start a container with a static address on that network:

```bash
docker run -dit \
  --name db \
  --network backend-net \
  --ip 172.30.0.10 \
  alpine \
  sh
```

For normal application communication, prefer DNS names such as `db` instead of hard-coded container IP addresses.

## 10. Inspect Linux bridge interfaces

```bash
ip link show type bridge
```

This can show the default `docker0` bridge and bridge interfaces created for user-defined Docker bridge networks.

## Troubleshooting sequence

Inspect the available networks:

```bash
docker network ls
```

Inspect `app-net` membership and IPAM data:

```bash
docker network inspect app-net
```

Inspect the client container's network settings:

```bash
docker inspect client
```

Test DNS resolution:

```bash
docker exec client nslookup web
```

Test IP connectivity by name:

```bash
docker exec client ping -c 3 web
```

Test the application layer:

```bash
docker exec client wget -qO- http://web
```

## Commands cheat sheet

See [`DevOps_User-defined_Bridge_Network_Session_29_Commands_CheatSheet.txt`](DevOps_User-defined_Bridge_Network_Session_29_Commands_CheatSheet.txt).

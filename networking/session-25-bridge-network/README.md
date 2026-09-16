# Session 25 — Bridge Network

Hands-on lab for Docker bridge networking on a single Docker host.

## 1. Inspect the default Docker bridge

```bash
docker network ls
docker network inspect bridge
ip addr show docker0
```

## 2. Test the default bridge

Create two Alpine containers on Docker's default bridge:

```bash
docker run -dit --name container1 alpine sh
docker run -dit --name container2 alpine sh
```

Get their container IP addresses:

```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' container1
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' container2
```

Test connectivity by IP address. Replace `172.17.0.3` with the actual IP returned for `container2`:

```bash
docker exec container1 ping -c 3 172.17.0.3
```

Test name resolution on the default bridge:

```bash
docker exec container1 ping -c 3 container2
```

The default bridge does not provide the same automatic container-name DNS resolution as a user-defined bridge network.

Remove the test containers before the next part:

```bash
docker rm -f container1 container2
```

## 3. Create a user-defined bridge network

```bash
docker network create app-network
```

Equivalent explicit forms:

```bash
docker network create --driver bridge app-network
```

```bash
docker network create -d bridge app-network
```

> Run only one of the three `docker network create` commands above for the same network name.

## 4. Run containers on the user-defined bridge

```bash
docker run -dit \
  --name container1 \
  --network app-network \
  alpine sh
```

```bash
docker run -dit \
  --name container2 \
  --network app-network \
  alpine sh
```

Inspect network membership:

```bash
docker network inspect app-network
```

Test Docker DNS and connectivity by container name:

```bash
docker exec container1 ping -c 3 container2
docker exec container2 ping -c 3 container1
```

## 5. Create a bridge network with a custom subnet

```bash
docker network create \
  --driver bridge \
  --subnet 172.30.0.0/24 \
  --gateway 172.30.0.1 \
  production-net
```

Verify it:

```bash
docker network inspect production-net
```

Remove the unused custom network:

```bash
docker network rm production-net
```

## 6. Connect and disconnect an existing container

Create another network:

```bash
docker network create backend-network
```

Connect `container1` to it:

```bash
docker network connect backend-network container1
```

Verify membership:

```bash
docker network inspect backend-network
```

Disconnect the container:

```bash
docker network disconnect backend-network container1
```

Remove the network:

```bash
docker network rm backend-network
```

## 7. Cleanup

```bash
docker rm -f container1 container2
docker network rm app-network
```

## Commands cheat sheet

See [`DevOps_Bridge_Network_Session_25_Commands_CheatSheet.txt`](DevOps_Bridge_Network_Session_25_Commands_CheatSheet.txt).

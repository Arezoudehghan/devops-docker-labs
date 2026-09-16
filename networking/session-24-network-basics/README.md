# Session 24 — Docker Networking Basics

This lab introduces Docker networking fundamentals: container IP addresses, the default bridge network, port publishing, basic connectivity and DNS checks, and a first user-defined network.

## Files

```text
session-24-network-basics/
├── README.md
└── DevOps_Docker_Networking_Session_24_Commands_CheatSheet.txt
```

## 1. Inspect Docker networks

```bash
docker network ls
```

Inspect the default bridge network:

```bash
docker network inspect bridge
```

## 2. Start a container and inspect its network

```bash
docker run -d --name web1 nginx
docker ps
docker inspect web1
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' web1
```

Use Alpine when you want a small interactive container for networking checks:

```bash
docker run -it --rm alpine sh
```

Inside the container:

```bash
ip addr
ip route
```

## 3. Port publishing

Run two Nginx containers. Both listen on container port `80`, while the Docker host uses different published ports:

```bash
docker run -d --name web1 -p 8080:80 nginx
docker run -d --name web2 -p 8081:80 nginx
```

Verify the containers:

```bash
docker ps
```

Test both published ports:

```bash
curl http://localhost:8080
curl http://localhost:8081
```

Check the Nginx request log:

```bash
docker logs web1
```

## 4. Understand a host-port conflict

The following command attempts to publish host port `8080` again and fails when that port is already in use:

```bash
docker run -d --name web2 -p 8080:80 nginx
```

A different host port avoids the conflict:

```bash
docker run -d --name web2 -p 8081:80 nginx
```

## 5. Connectivity and DNS checks

Test IP connectivity from a temporary Alpine container:

```bash
docker run --rm alpine ping -c 4 8.8.8.8
```

Test DNS resolution:

```bash
docker run --rm alpine ping -c 4 google.com
```

Inspect the container resolver configuration:

```bash
docker run --rm alpine cat /etc/resolv.conf
```

For host-side troubleshooting, inspect listening TCP ports:

```bash
ss -lntp
```

## 6. Create a user-defined Docker network

```bash
docker network create my-network
```

Start a container on that network:

```bash
docker run -d --name web --network my-network nginx
```

## 7. Bind a published port only to localhost

```bash
docker run -d -p 127.0.0.1:8080:80 nginx
```

This binds the published port to the host loopback address instead of all host interfaces.

## 8. EXPOSE versus published ports

A Dockerfile can declare the intended application port:

```dockerfile
EXPOSE 80
```

Publishing the port on the Docker host is done when the container is started:

```bash
docker run -p 8080:80 IMAGE
```

## Cleanup

```bash
docker rm -f web1 web2
```

## Learning objective

The main networking path demonstrated by this lab is:

```text
Client -> Docker host port -> Docker networking -> Container IP:port -> Application
```

The session also introduces these core concepts:

```text
Network namespace -> virtual interface -> IP address -> Docker network -> routing/NAT -> port publishing
```

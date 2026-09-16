# Session 09 — Container Lifecycle Management

This lab practices listing, stopping, starting, restarting, and removing Docker containers.

## List running containers

```bash
docker ps
```

## List all containers

```bash
docker ps -a
```

## List container IDs only

```bash
docker ps -q
docker ps -aq
```

## Create the lab container

```bash
docker run -d --name test-nginx nginx
```

## Stop the container

```bash
docker stop test-nginx
docker ps
docker ps -a
```

## Start the stopped container

```bash
docker start test-nginx
docker ps
```

## Restart the container

```bash
docker restart test-nginx
docker ps
```

## Remove the container

```bash
docker stop test-nginx
docker rm test-nginx
docker ps -a
```

## Force remove example

```bash
docker rm -f web1
```

## Remove multiple containers

```bash
docker rm web1 web2 web3
```

## Remove all stopped containers

```bash
docker container prune
```

## Docker container command equivalents

```bash
docker container ls
docker container stop web1
docker container start web1
docker container rm web1
```

## Full session lab

```bash
docker run -d --name test-nginx nginx
docker ps
docker stop test-nginx
docker ps
docker ps -a
docker start test-nginx
docker ps
docker restart test-nginx
docker ps
docker stop test-nginx
docker rm test-nginx
docker ps -a
```

## Commands Cheat Sheet

See [`DevOps_Container_Management_Session_9_Commands_CheatSheet.txt`](DevOps_Container_Management_Session_9_Commands_CheatSheet.txt).

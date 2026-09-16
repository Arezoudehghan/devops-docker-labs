# Session 10 — Container Logs, Exec, Inspect, and Troubleshooting

## Start the lab container

```bash
docker run -d --name debug-web -p 8080:80 nginx:alpine
docker ps
curl -I http://127.0.0.1:8080
```

## Container logs

```bash
docker logs debug-web
docker logs --tail 20 debug-web
docker logs -f debug-web
docker logs --since 5m debug-web
docker logs --timestamps debug-web
docker logs --since 10m --tail 100 --timestamps debug-web
```

Generate a request while following logs:

```bash
curl http://127.0.0.1:8080
```

## Run commands inside the container

```bash
docker exec debug-web nginx -v
docker exec -it debug-web sh
```

Inside the container:

```bash
hostname
ps
cat /etc/os-release
ls -lah /usr/share/nginx/html
cat /etc/nginx/nginx.conf
cat /etc/nginx/conf.d/default.conf
nginx -t
exit
```

Run checks without opening an interactive shell:

```bash
docker exec debug-web nginx -t
docker exec debug-web ps
```

## Inspect container state and configuration

```bash
docker inspect debug-web
docker inspect -f '{{.State.Status}}' debug-web
docker inspect -f '{{.State.Running}}' debug-web
docker inspect -f '{{.State.ExitCode}}' debug-web
docker inspect -f 'status={{.State.Status}} exit={{.State.ExitCode}} oom={{.State.OOMKilled}} error={{.State.Error}}' debug-web
```

## Inspect networking, ports, mounts, environment, and logging

```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' debug-web
docker inspect -f '{{json .NetworkSettings.Ports}}' debug-web
docker port debug-web
docker inspect -f '{{json .Mounts}}' debug-web
docker inspect -f '{{json .Config.Env}}' debug-web
docker inspect -f '{{.HostConfig.LogConfig.Type}}' debug-web
```

## Troubleshoot an exited container

Create a container that exits with an application error:

```bash
docker run -d --name fail-demo alpine sh -c 'echo "Starting application"; sleep 2; echo "ERROR: config file not found" >&2; exit 2'
```

Check its state and logs:

```bash
docker ps -a
docker logs fail-demo
docker inspect -f 'status={{.State.Status}} exit={{.State.ExitCode}} error={{.State.Error}}' fail-demo
```

`docker exec` requires a running container, so this command is expected to fail after `fail-demo` exits:

```bash
docker exec -it fail-demo sh
```

## Troubleshoot port mapping

```bash
docker run -d --name port-demo -p 9090:80 nginx:alpine
docker port port-demo
curl -I http://127.0.0.1:9090
```

Test the service from inside the container:

```bash
docker exec port-demo wget -qO- http://127.0.0.1
```

## Process and resource checks

```bash
docker top debug-web
docker stats debug-web
docker stats --no-stream debug-web
```

## Docker Engine checks

```bash
sudo systemctl status docker
sudo journalctl -xu docker.service
sudo journalctl -xu docker.service --since "10 minutes ago"
```

## Troubleshooting runbook

Replace `CONTAINER_NAME` with the target container name:

```bash
docker ps -a
docker inspect -f '{{.State.Status}}' CONTAINER_NAME
docker inspect -f 'exit={{.State.ExitCode}} oom={{.State.OOMKilled}} error={{.State.Error}}' CONTAINER_NAME
docker logs --tail 100 --timestamps CONTAINER_NAME
docker exec -it CONTAINER_NAME sh
docker top CONTAINER_NAME
docker port CONTAINER_NAME
docker inspect -f '{{json .NetworkSettings.Networks}}' CONTAINER_NAME
docker stats --no-stream CONTAINER_NAME
```

## Session practice

For each running container, collect its recent logs, state, port mapping, IP address, processes, and one resource snapshot:

```bash
docker logs --tail 20 CONTAINER_NAME
docker inspect -f 'status={{.State.Status}} exit={{.State.ExitCode}} oom={{.State.OOMKilled}}' CONTAINER_NAME
docker port CONTAINER_NAME
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' CONTAINER_NAME
docker top CONTAINER_NAME
docker stats --no-stream CONTAINER_NAME
```

## Cleanup

```bash
docker rm -f debug-web port-demo fail-demo
```

# Session 02 — VM vs Container

## Lab goal

Compare the Linux host with Docker containers to verify that Linux containers use the host kernel while keeping their own user space and isolated processes.

## Run

```bash
bash vm-vs-container-lab.sh
```

## Lab commands

```bash
uname -a
docker run --rm ubuntu uname -a

uname -r
docker run --rm ubuntu uname -r

cat /etc/os-release
docker run --rm alpine cat /etc/os-release

docker run -d --name nginx-lab nginx
docker top nginx-lab
ps aux | grep nginx

docker rm -f nginx-lab
docker ps -a
```

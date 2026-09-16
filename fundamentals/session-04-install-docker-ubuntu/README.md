# Session 04 — Install Docker on Ubuntu

## System checks

```bash
cat /etc/os-release
uname -m
whoami
docker --version
dpkg -l | grep -i docker
```

## Remove conflicting packages

```bash
sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc docker-buildx podman-docker containerd runc | cut -f1)
```

## Install Docker Engine from the official repository

```bash
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
```

```bash
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
```

```bash
cat /etc/apt/sources.list.d/docker.sources
sudo apt update
apt-cache policy docker-ce
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

## Verify Docker

```bash
docker --version
docker compose version
docker buildx version
sudo systemctl status docker
sudo systemctl is-enabled docker
sudo systemctl status containerd
sudo docker run hello-world
sudo docker images
sudo docker ps
sudo docker ps -a
sudo docker info
```

## Docker service management

```bash
sudo systemctl start docker
sudo systemctl enable docker
sudo systemctl restart docker
sudo systemctl stop docker
sudo systemctl disable docker
```

## Configure Docker access without sudo

```bash
ls -l /var/run/docker.sock
getent group docker
sudo usermod -aG docker $USER
newgrp docker
groups
docker ps
docker run hello-world
```

## Nginx smoke test

```bash
docker run -d --name test-nginx -p 8080:80 nginx
docker ps
curl http://localhost:8080
docker rm -f test-nginx
docker ps -a
docker images
```

## Troubleshooting checks

```bash
sudo systemctl status docker
sudo journalctl -u docker --no-pager -n 100
cat /etc/apt/sources.list.d/docker.sources
ls -l /etc/apt/keyrings/docker.asc
cat /etc/os-release
dpkg --print-architecture
docker info
systemctl is-active docker
systemctl is-enabled docker
```

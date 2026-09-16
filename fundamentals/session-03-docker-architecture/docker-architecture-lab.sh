#!/usr/bin/env bash

# Session 03 — Docker Architecture Lab

# Docker Client and Server
docker version
docker info

# Docker socket and daemon
ls -l /var/run/docker.sock
systemctl status docker
ps aux | grep dockerd

# Images and Registry
docker images
docker pull alpine
docker pull nginx

# Containers
docker run alpine echo hello
docker run alpine echo "Docker architecture test"
docker run busybox echo hello
docker ps
docker ps -a

# Runtime
ps aux | grep containerd
systemctl status containerd

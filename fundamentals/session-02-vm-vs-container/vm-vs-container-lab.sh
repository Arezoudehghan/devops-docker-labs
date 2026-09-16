#!/usr/bin/env bash
set -euo pipefail

uname -a
docker run --rm ubuntu uname -a

uname -r
docker run --rm ubuntu uname -r

cat /etc/os-release
docker run --rm alpine cat /etc/os-release

docker run -d --name nginx-lab nginx
docker top nginx-lab
ps aux | grep nginx

docker ps -a

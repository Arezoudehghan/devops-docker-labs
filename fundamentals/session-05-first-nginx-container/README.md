# Session 05 — First Real Container with Nginx

```bash
docker --version
sudo systemctl status docker
docker ps
docker ps -a
docker images
docker image ls
docker pull nginx
docker run -d --name my-nginx -p 8080:80 nginx
docker ps
curl http://localhost:8080
docker port my-nginx
docker logs my-nginx
docker logs -f my-nginx
docker exec -it my-nginx /bin/bash
hostname
pwd
ls
ps aux
cat /usr/share/nginx/html/index.html
exit
docker inspect my-nginx
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' my-nginx
docker stats my-nginx
docker stop my-nginx
docker start my-nginx
curl http://localhost:8080
docker run -d --name nginx-2 -p 8081:80 nginx
docker ps
curl http://localhost:8081
ss -lntp
docker stop my-nginx
docker stop nginx-2
docker rm my-nginx nginx-2
docker ps -a
docker images
```

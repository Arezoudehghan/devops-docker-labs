# Session 30 — App + Database on a Separate Docker Network

Hands-on lab for running an application and database on a dedicated user-defined Docker bridge network.

## Goal

Build this flow:

```text
Client
  |
  | host port 8080
  v
WordPress app
  |
  | app-db-net
  v
MySQL database
```

The application publishes a host port, but the database does not. WordPress reaches MySQL through Docker DNS by using the container name `db`.

> The passwords in this lab are example credentials for a local training environment only. Do not reuse them in production.

## 1. Create the application network

```bash
docker network create app-db-net
```

Verify it:

```bash
docker network ls
docker network inspect app-db-net
```

## 2. Create persistent storage for MySQL

```bash
docker volume create mysql_data
docker volume ls
```

## 3. Run the database container

```bash
docker run -d \
  --name db \
  --network app-db-net \
  -e MYSQL_ROOT_PASSWORD=RootPass123 \
  -e MYSQL_DATABASE=appdb \
  -e MYSQL_USER=appuser \
  -e MYSQL_PASSWORD=AppPass123 \
  -v mysql_data:/var/lib/mysql \
  mysql:8.4
```

The MySQL port is intentionally not published to the Docker host.

Check the container and its logs:

```bash
docker ps
docker logs db
```

Follow new database log entries when needed:

```bash
docker logs -f db
```

Press `Ctrl+C` to stop following the logs without stopping the container.

## 4. Run the application container

```bash
docker run -d \
  --name app \
  --network app-db-net \
  -p 8080:80 \
  -e WORDPRESS_DB_HOST=db:3306 \
  -e WORDPRESS_DB_NAME=appdb \
  -e WORDPRESS_DB_USER=appuser \
  -e WORDPRESS_DB_PASSWORD=AppPass123 \
  wordpress:latest
```

WordPress uses `db:3306` instead of a container IP address or `localhost`.

## 5. Verify network membership

```bash
docker ps
docker network inspect app-db-net
```

Both `app` and `db` should be attached to `app-db-net`.

## 6. Verify Docker DNS

Resolve the database container name from inside the application container:

```bash
docker exec app php -r 'echo gethostbyname("db") . PHP_EOL;'
```

## 7. Test the database connection

Run a temporary MySQL client container on the same network:

```bash
docker run --rm \
  --network app-db-net \
  mysql:8.4 \
  mysql \
  -h db \
  -uappuser \
  -pAppPass123 \
  -e "SELECT 1;"
```

## 8. Test network isolation

A temporary container that is not attached to `app-db-net` should not get the same Docker DNS access to `db`:

```bash
docker run --rm alpine ping -c 2 db
```

Now attach the temporary container to the application network:

```bash
docker run --rm \
  --network app-db-net \
  alpine \
  ping -c 2 db
```

## 9. Connect and disconnect an existing container

Disconnect the database from the application network:

```bash
docker network disconnect app-db-net db
```

Reconnect it:

```bash
docker network connect app-db-net db
```

Inspect the network again:

```bash
docker network inspect app-db-net
```

## 10. Troubleshooting checks

Check running containers:

```bash
docker ps
```

Check database logs:

```bash
docker logs db
```

Check application logs:

```bash
docker logs app
```

Inspect the application configuration:

```bash
docker inspect app
```

Verify Docker DNS again:

```bash
docker exec app php -r 'echo gethostbyname("db") . PHP_EOL;'
```

## 11. Optional two-network pattern

Create separate frontend and backend networks:

```bash
docker network create frontend-net
docker network create backend-net
```

Run MySQL only on the backend network:

```bash
docker run -d \
  --name database \
  --network backend-net \
  -e MYSQL_ROOT_PASSWORD=RootPass123 \
  -e MYSQL_DATABASE=appdb \
  -e MYSQL_USER=appuser \
  -e MYSQL_PASSWORD=AppPass123 \
  mysql:8.4
```

Run WordPress on the backend network:

```bash
docker run -d \
  --name webapp \
  --network backend-net \
  -p 8080:80 \
  -e WORDPRESS_DB_HOST=database:3306 \
  -e WORDPRESS_DB_NAME=appdb \
  -e WORDPRESS_DB_USER=appuser \
  -e WORDPRESS_DB_PASSWORD=AppPass123 \
  wordpress:latest
```

Attach the application to the frontend network as well:

```bash
docker network connect frontend-net webapp
```

This gives the application access to both networks while the database remains attached only to `backend-net`.

## 12. Cleanup

Remove the first scenario containers:

```bash
docker rm -f app db
```

If the two-network scenario was also created, remove its containers:

```bash
docker rm -f webapp database
```

Remove the networks:

```bash
docker network rm app-db-net
docker network rm frontend-net backend-net
```

Remove the training database volume only when its stored data is no longer needed:

```bash
docker volume rm mysql_data
```

## Commands cheat sheet

See [`DevOps_Docker_Networking_App_Database_Separate_Network_Session_30_Commands_CheatSheet.txt`](DevOps_Docker_Networking_App_Database_Separate_Network_Session_30_Commands_CheatSheet.txt).

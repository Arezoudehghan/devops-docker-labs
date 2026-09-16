# Session 23 — MySQL and PostgreSQL with Docker Volumes

This lab demonstrates persistent database data with Docker named volumes. The goal is to prove that MySQL and PostgreSQL data survives container removal and recreation when the same named volume is mounted again.

## Files

- `compose.yaml` — MySQL and PostgreSQL services with named volumes.
- `.env.example` — safe example variables; do not commit a real `.env` file.
- `DevOps_MySQL_PostgreSQL_Volume_Session_23_Commands_CheatSheet.txt` — command reference from this lesson.

## Storage paths

MySQL stores its database files at:

```text
/var/lib/mysql
```

PostgreSQL stores its database cluster at:

```text
/var/lib/postgresql/data
```

The Compose file mounts these paths to the named volumes `mysql_data` and `postgres_data`.

## Prepare environment variables

Create a local `.env` file from `.env.example` and replace the example passwords before starting the lab. The repository-level `.gitignore` excludes `.env`.

## Start the databases

```bash
docker compose up -d
```

Verify the services:

```bash
docker compose ps
```

List the created volumes:

```bash
docker volume ls
```

## MySQL verification

Check readiness:

```bash
docker exec mysql-db mysqladmin ping -uroot -p'YOUR_ROOT_PASSWORD'
```

Open the MySQL client:

```bash
docker exec -it mysql-db mysql -uroot -p
```

Example SQL:

```sql
USE appdb;

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(150)
);

INSERT INTO users (name, email)
VALUES
('Arezou', 'arezou@example.com'),
('Ali', 'ali@example.com');

SELECT * FROM users;
```

## PostgreSQL verification

Check readiness:

```bash
docker exec postgres-db pg_isready -U appuser -d appdb
```

Open psql:

```bash
docker exec -it postgres-db psql -U appuser -d appdb
```

Example SQL:

```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(150)
);

INSERT INTO users (name, email)
VALUES
('Arezou', 'arezou@example.com'),
('Sara', 'sara@example.com');

SELECT * FROM users;
```

## Persistence test

Stop and remove the Compose containers while keeping the named volumes:

```bash
docker compose down
```

Start the services again:

```bash
docker compose up -d
```

Query the `users` tables again. The rows should still exist because the database files are stored in named volumes instead of the containers' writable layers.

## Logical backup examples

MySQL:

```bash
docker exec mysql-db \
  mysqldump -uroot -p'YOUR_ROOT_PASSWORD' appdb > mysql-appdb.sql
```

PostgreSQL:

```bash
docker exec postgres-db \
  pg_dump -U appuser appdb > postgres-appdb.sql
```

Persistent storage is not a backup. Keep database backups outside the Docker host according to the recovery requirements of the environment.

## Cleanup warning

```bash
docker compose down -v
```

The `-v` option removes the Compose volumes and therefore deletes the persisted database data used by this lab. Use it only when the lab data is no longer needed.

## Key lesson

Containers are disposable, but stateful database data should live outside the container writable layer. Docker named volumes keep that data independent from the lifecycle of individual MySQL or PostgreSQL containers.

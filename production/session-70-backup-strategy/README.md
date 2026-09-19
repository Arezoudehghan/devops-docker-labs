# Session 70 — Docker Backup Strategy

A hands-on Docker Production lab for backing up and restoring persistent Docker data.

This session focuses on named-volume backup and restore, PostgreSQL application-consistent backup with `pg_dump`, restore testing, and the recovery components needed when a Docker host is lost.

## Lab goals

- Back up a Docker named volume to a compressed archive.
- Restore a volume into a separate test volume.
- Create a PostgreSQL logical backup with `pg_dump`.
- Restore a PostgreSQL custom-format dump with `pg_restore`.
- Keep container images reproducible through a registry instead of treating containers as backup artifacts.
- Separate application configuration, persistent data, and secrets in the recovery plan.
- Validate backups by performing an actual restore test.

## Project structure

```text
session-70-backup-strategy/
├── .env.example
├── compose.yaml
├── scripts/
│   ├── backup-postgres.sh
│   ├── backup-volume.sh
│   ├── restore-postgres.sh
│   └── restore-volume.sh
├── DevOps_Backup_Strategy_Session_70_Commands_CheatSheet.txt
└── README.md
```

## Requirements

- Docker Engine
- Docker Compose plugin
- Write access to a backup directory such as `/backup/docker` and `/backup/postgres`
- Enough free disk space for backup archives

## 1. Prepare the PostgreSQL lab

Copy the example environment file and replace the placeholder password before using the lab:

```bash
cp .env.example .env
```

Start PostgreSQL:

```bash
docker compose up -d
```

Check the service:

```bash
docker compose ps
```

The Compose file gives the PostgreSQL volume the explicit name `postgres_data`, so the raw Docker backup commands and the Compose service reference the same volume.

## 2. Inspect Docker volumes

```bash
docker volume ls
docker volume inspect postgres_data
```

## 3. Back up a named volume

The helper script mounts the source volume read-only inside a temporary Alpine container and writes a timestamped `.tar.gz` archive to the backup directory.

```bash
chmod +x scripts/*.sh
sudo mkdir -p /backup/docker
./scripts/backup-volume.sh postgres_data /backup/docker
```

The script uses the same backup pattern taught in the lesson:

```bash
docker run --rm \
  -v postgres_data:/data:ro \
  -v /backup/docker:/backup \
  alpine \
  sh -c 'tar czf /backup/postgres_data_$(date +%F_%H%M).tar.gz -C /data .'
```

List the created archive:

```bash
ls -lh /backup/docker
```

Inspect archive contents without extracting:

```bash
tar tzf /backup/docker/<archive>.tar.gz
```

## 4. Restore a named volume

Restore into a separate volume first instead of overwriting the production volume:

```bash
./scripts/restore-volume.sh \
  /backup/docker/<archive>.tar.gz \
  postgres_data_restore
```

Verify that files exist in the restored volume:

```bash
docker run --rm \
  -v postgres_data_restore:/data \
  alpine \
  ls -lah /data
```

## 5. Create an application-consistent PostgreSQL backup

A raw volume archive of a running database can capture files at different moments. For a logical PostgreSQL backup, use the database-aware tool:

```bash
sudo mkdir -p /backup/postgres
./scripts/backup-postgres.sh /backup/postgres
```

The core command is:

```bash
docker compose exec -T db \
  pg_dump -U appuser -Fc appdb \
  > /backup/postgres/appdb_$(date +%F_%H%M).dump
```

## 6. Restore the PostgreSQL dump

Provide the dump file created in the previous step:

```bash
./scripts/restore-postgres.sh \
  /backup/postgres/<dump-file>.dump
```

The restore uses `pg_restore --clean --if-exists` against `appdb`.

## 7. Offline volume backup for PostgreSQL

If downtime is acceptable, stop the database before a raw volume backup:

```bash
docker compose stop db
./scripts/backup-volume.sh postgres_data /backup/docker
docker compose start db
```

This avoids the database changing files while the raw archive is being created.

## 8. Restore test

A backup job marked successful is not enough. Create a separate restore-test volume and restore into it:

```bash
docker volume create app_data_restore_test
```

Then restore an archive with `restore-volume.sh` and inspect the recovered files.

## Recovery model

A recoverable Docker application normally needs:

```text
Git configuration
+ versioned container image in a registry
+ persistent data backup
+ protected secrets
+ tested restore procedure
= recoverable application
```

Containers themselves are normally recreated. Persistent data, configuration, secrets, and the image source/registry are the important recovery assets.

## RPO and RTO

- **RPO** defines how much data loss the business can tolerate and therefore influences backup frequency.
- **RTO** defines how quickly service must be restored and therefore influences restore design, backup location, and recovery testing.

A backup stored only on the same Docker host does not protect against total host or disk loss. Keep recovery copies off the production host and test restores periodically.

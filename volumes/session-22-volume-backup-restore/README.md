# Session 22 — Backup and Restore Docker Volumes

This lab practices backing up a Docker named volume to a compressed archive, restoring it into a new volume, and verifying the recovered data.

## Files

```text
session-22-volume-backup-restore/
├── README.md
└── DevOps_Docker_Volume_Backup_Restore_Session_22_Commands_CheatSheet.txt
```

## 1. Create the source volume

```bash
docker volume create app-data
docker volume ls
docker volume inspect app-data
```

## 2. Write test data into the volume

```bash
docker run --rm \
  -v app-data:/data \
  alpine \
  sh -c 'echo "Hello from Docker Volume" > /data/file1.txt'
```

Verify the data:

```bash
docker run --rm \
  -v app-data:/data \
  alpine \
  cat /data/file1.txt
```

## 3. Create the backup directory

```bash
mkdir -p ~/docker-backups
ls -ld ~/docker-backups
```

## 4. Back up the volume

Mount the source volume read-only and write the compressed archive to the host backup directory:

```bash
docker run --rm \
  -v app-data:/data:ro \
  -v ~/docker-backups:/backup \
  alpine \
  tar czf /backup/app-data-backup.tar.gz -C /data .
```

Verify the backup file and inspect the archive contents:

```bash
ls -lh ~/docker-backups
tar tzf ~/docker-backups/app-data-backup.tar.gz
```

## 5. Simulate data loss

> Warning: the following command deletes the named volume and its stored data. Run it only for this lab after confirming the backup exists.

```bash
docker volume rm app-data
```

Confirm the source volume is gone:

```bash
docker volume ls
```

## 6. Create a restore target

```bash
docker volume create app-data-restored
```

## 7. Restore the backup

```bash
docker run --rm \
  -v app-data-restored:/data \
  -v ~/docker-backups:/backup:ro \
  alpine \
  tar xzf /backup/app-data-backup.tar.gz -C /data
```

## 8. Verify the restored data

```bash
docker run --rm \
  -v app-data-restored:/data \
  alpine \
  cat /data/file1.txt
```

Check the restored file list and permissions:

```bash
docker run --rm \
  -v app-data-restored:/data \
  alpine \
  find /data -type f

docker run --rm \
  -v app-data-restored:/data \
  alpine \
  ls -la /data
```

Expected recovered content:

```text
Hello from Docker Volume
```

## 9. Full practice lab

Create a separate lab volume:

```bash
docker volume create lab-volume
```

Create three files:

```bash
docker run --rm \
  -v lab-volume:/data \
  alpine \
  sh -c '
    echo "Docker" > /data/docker.txt
    echo "DevOps" > /data/devops.txt
    echo "Backup Test" > /data/backup.txt
  '
```

Verify the source data:

```bash
docker run --rm \
  -v lab-volume:/data \
  alpine \
  ls -la /data
```

Back it up:

```bash
docker run --rm \
  -v lab-volume:/data:ro \
  -v ~/docker-backups:/backup \
  alpine \
  tar czf /backup/lab-volume.tar.gz -C /data .
```

Inspect the archive:

```bash
tar tzf ~/docker-backups/lab-volume.tar.gz
```

> Warning: the next command deletes `lab-volume`. Run it only after verifying `lab-volume.tar.gz`.

```bash
docker volume rm lab-volume
```

Create the restore volume:

```bash
docker volume create lab-volume-restored
```

Restore the archive:

```bash
docker run --rm \
  -v lab-volume-restored:/data \
  -v ~/docker-backups:/backup:ro \
  alpine \
  tar xzf /backup/lab-volume.tar.gz -C /data
```

Verify the restored files:

```bash
docker run --rm \
  -v lab-volume-restored:/data \
  alpine \
  sh -c 'ls -la /data && cat /data/backup.txt'
```

Expected final value:

```text
Backup Test
```

## Lab workflow

```text
Named Volume -> Read-Only Mount -> tar.gz Backup -> New Volume -> Restore -> Verify
```

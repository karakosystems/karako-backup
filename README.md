# karako-backup

Daily encrypted backups of a Docker host, as one container. Every night it:

1. dumps every running Postgres and MariaDB container with `pg_dumpall` or `mariadb-dump`;
2. snapshots the dumps and every Docker volume with [restic](https://restic.net), skipping the raw data directories of
   those databases and of caches (Redis, Valkey, KeyDB, Dragonfly);
3. applies the retention policy and, once a week, reads back a sample of the repository;
4. once a week, restores every Postgres dump from the repository into a throwaway server with the same image and no
   network, and fails unless every table comes back;
5. posts the result to Discord.

Dumps are written uncompressed: restic compresses them and stores only what changed since the previous run, so
frequent backups of a large database stay small.

The repository can be any restic backend: S3, SFTP, B2, a local path. Its content is encrypted with `RESTIC_PASSWORD`;
losing that password loses the backups.

## Run

```sh
docker compose -f example/compose.yaml up -d
```

[`example/compose.yaml`](example/compose.yaml) fits any Docker host. [`example/coolify.yaml`](example/coolify.yaml) is
the same stack as a Coolify service: it also backs up `/data/coolify` (compose files, environment, proxy certificates)
without what Coolify rebuilds on its own: local database backups, Sentinel metrics, image scans, proxy logs and the
vulnerability database of its image scanner.

The container needs the Docker socket to find and dump the databases, and reads the volumes from
`/var/lib/docker/volumes` read-only.

## Configuration

| Variable | Default | Purpose |
|---|---|---|
| `BACKUP_HOST` | required | Host name recorded in every snapshot; retention applies per host |
| `RESTIC_REPOSITORY` | required | restic repository, for example `s3:s3.us-east-1.amazonaws.com/bucket/restic/host` |
| `RESTIC_PASSWORD` or `RESTIC_PASSWORD_FILE` | required | Repository encryption password |
| `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` | | Credentials of an S3 repository; other backends use their own restic variables |
| `BACKUP_SCHEDULE` | `30 4 * * *` | Cron expression, UTC |
| `BACKUP_ON_START` | `true` | Run a backup when the container starts |
| `BACKUP_KEEP_HOURLY` | `0` | Hourly snapshots kept, for a schedule that runs several times a day |
| `BACKUP_KEEP_DAILY`, `BACKUP_KEEP_WEEKLY`, `BACKUP_KEEP_MONTHLY` | `7`, `4`, `6` | Retention |
| `BACKUP_CHECK_WEEKDAY` | `7` | ISO weekday of the integrity check, `7` for Sunday |
| `BACKUP_CHECK_SUBSET` | `5%` | Share of the repository data read back by the check |
| `BACKUP_VERIFY_WEEKDAY` | `7` | ISO weekday of the restore test, `0` never runs it |
| `BACKUP_VERIFY_CPUS`, `BACKUP_VERIFY_MEMORY` | `1`, `2g` | Limits of the throwaway Postgres server |
| `BACKUP_EXTRA_PATHS` | | Space-separated paths backed up besides the volumes, when they exist |
| `BACKUP_EXCLUDES` | | Space-separated paths or globs left out |
| `BACKUP_SKIP_UNUSED_VOLUMES` | `false` | `true` leaves out the volumes no container uses |
| `DISCORD_WEBHOOK_URL` | | Discord webhook that receives every result; a failure mentions `@here` |
| `BACKUP_NOTIFY_SUCCESS` | `true` | `false` posts failures only, `daily` the first success of each day and every restore test |

A container labelled `karako-backup.skip=true` is never dumped.

The health check turns the container unhealthy when no backup succeeded in the last 26 hours.

## Commands

```sh
docker exec <container> karako-backup
docker exec <container> restic snapshots
docker exec <container> karako-backup-verify
docker exec <container> restic restore latest --target /tmp/restore --include /dumps/<container>.sql
```

## Restore a database

```sh
restic dump latest /dumps/<container>.sql | docker exec -i <postgres> psql -U postgres
restic dump latest /dumps/<container>.sql | docker exec -i <mariadb> mariadb -uroot -p<password>
```

## License

[MIT](LICENSE)

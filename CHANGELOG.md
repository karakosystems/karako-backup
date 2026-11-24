# Changelog

## [1.2.0](https://github.com/karakosystems/karako-backup/compare/karako-backup-v1.1.0...karako-backup-v1.2.0) (2026-11-24)


### Features

* keep dumps uncompressed so restic deduplicates them between runs ([d383b61](https://github.com/karakosystems/karako-backup/commit/d383b6163d2e82cdbe6249bfa0cf21a97c656a50))
* keep hourly snapshots when BACKUP_KEEP_HOURLY is set ([3fba716](https://github.com/karakosystems/karako-backup/commit/3fba716e7323c60141f4455fc41c40a6f858575e))
* post one success a day to Discord when BACKUP_NOTIFY_SUCCESS is daily ([72b2121](https://github.com/karakosystems/karako-backup/commit/72b21212d8a8e1f6e81592770cf961eb7bae585b))
* restore every Postgres dump into a throwaway server once a week ([69d09aa](https://github.com/karakosystems/karako-backup/commit/69d09aa2f70ca33237d1cf467a09b9df5d58d2ab))


### Bug Fixes

* run the weekly integrity check once on its day when backups run several times a day ([49b02cb](https://github.com/karakosystems/karako-backup/commit/49b02cbb38b5a563d1c1ec567cbf7b0136fc41d8))

## [1.1.0](https://github.com/karakosystems/karako-backup/compare/karako-backup-v1.0.0...karako-backup-v1.1.0) (2026-11-24)


### Features

* skip the volumes no container uses when BACKUP_SKIP_UNUSED_VOLUMES is set ([8b5ad0b](https://github.com/karakosystems/karako-backup/commit/8b5ad0b0316efc8314adde493ac5aaf0b52cf712))

## 1.0.0 (2026-11-24)


### Features

* back up Docker databases and volumes with restic on a schedule ([3337998](https://github.com/karakosystems/karako-backup/commit/333799816ef24a2ee5fd688e15bac1531e9e1af7))


### Bug Fixes

* upgrade the base packages and declare the root user the backup needs ([1882fb2](https://github.com/karakosystems/karako-backup/commit/1882fb2874b5200ce2484c0c57093cbe4c385253))

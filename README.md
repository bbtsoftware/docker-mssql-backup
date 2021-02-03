# Docker image for backup of Microsoft SQL Server

Docker image to create regular backups of a [Microsoft SQL Server] image.

## Information

| Service | Stats                                                                                     |
|---------|-------------------------------------------------------------------------------------------|
| Docker  | [![Build](https://img.shields.io/docker/cloud/build/bbtsoftwareag/mssql-backup.svg?style=flat-square)](https://hub.docker.com/r/bbtsoftwareag/mssql-backup/builds) [![Pulls](https://img.shields.io/docker/pulls/bbtsoftwareag/mssql-backup.svg?style=flat-square)](https://hub.docker.com/r/bbtsoftwareag/mssql-backup) [![Stars](https://img.shields.io/docker/stars/bbtsoftwareag/mssql-backup.svg?style=flat-square)](https://hub.docker.com/r/bbtsoftwareag/mssql-backup) [![Automated](https://img.shields.io/docker/cloud/automated/bbtsoftwareag/mssql-backup.svg?style=flat-square)](https://hub.docker.com/r/bbtsoftwareag/mssql-backup/builds) |
| GitHub  | [![Last commit](https://img.shields.io/github/last-commit/bbtsoftware/docker-mssql-backup.svg?style=flat-square)](https://github.com/bbtsoftware/docker-mssql-backup/commits/master) [![Issues](https://img.shields.io/github/issues-raw/bbtsoftware/docker-mssql-backup.svg?style=flat-square)](https://github.com/bbtsoftware/docker-mssql-backup/issues) [![PR](https://img.shields.io/github/issues-pr-raw/bbtsoftware/docker-mssql-backup.svg?style=flat-square)](https://github.com/bbtsoftware/docker-mssql-backup/pulls) [![Size](https://img.shields.io/github/repo-size/bbtsoftware/docker-mssql-backup.svg?style=flat-square)](https://github.com/bbtsoftware/docker-mssql-backup/) [![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](https://github.com/bbtsoftware/docker-mssql-backup/blob/master/LICENSE) |

## General

| Topic  | Description                                                            |
|--------|------------------------------------------------------------------------|
| Image  | See [Docker Hub](https://hub.docker.com/r/bbtsoftwareag/mssql-backup). |
| Source | See [GitHub](https://github.com/bbtsoftware/docker-mssql-backup).      |

## Usage

This container can create backups on a [Microsoft SQL Server] container.

**NOTE:**
The backup is written to a directory `/backup` inside the [Microsoft SQL Server] container, not to a volume in the backup container.
For using the cleanup feature attach the same `/backup` volume in the `bbtsoftwareag/mssql-backup` container.

### Tags

| Tag    | Description                                                                             | Size                                                                                                                  |
|--------|-----------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------|
| latest | Latest master build                                                                     | ![Size](https://shields.beevelop.com/docker/image/image-size/bbtsoftwareag/mssql-backup/latest.svg?style=flat-square) |
| 0.1.0  | Release [0.1.0](https://github.com/bbtsoftware/docker-mssql-backup/releases/tag/0.1.0)  | ![Size](https://shields.beevelop.com/docker/image/image-size/bbtsoftwareag/mssql-backup/0.1.0.svg?style=flat-square)  |
| 0.2.0  | Release [0.2.0](https://github.com/bbtsoftware/docker-mssql-backup/releases/tag/0.2.0)  | ![Size](https://shields.beevelop.com/docker/image/image-size/bbtsoftwareag/mssql-backup/0.2.0.svg?style=flat-square)  |

### Configuration

These environment variables are supported:

| Environment variable | Default value | Description                                                                                                                                                                                                                      |
|----------------------|---------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| DB_SERVER            | `mssql`       | Name or address of the database server to backup. Normally this should be the name of the [Microsoft SQL Server] service.                                                                                                        |
| DB_USER              | `SA`          | User used to connect to the database server.                                                                                                                                                                                     |
| DB_PASSWORD          |               | Password used to connect to the database server.                                                                                                                                                                                 |
| DB_NAMES             |               | Names of the databases for which a backup should be created.                                                                                                                                                                     |
| TZ                   |               | Timezone to use.                                                                                                                                                                                                                 |
| CRON_SCHEDULE        | `0 1 * * sun` | Cron schedule for running backups. NOTE: There is no check if there's already a backup running when starting the backup job. Therefore time interval needs to be longer than the maximum expected backup time for all databases. |
| BACKUP_CLEANUP       | `false`       | Set to "true" if you want to let the cronjob remove files older than $BACKUP_AGE days                                                                                                                                            |
| BACKUP_AGE           | `7`           | Number of days to keep backups in backup directory                                                                                                                                                                               |
| SKIP_BACKUP_LOG      | `false`       | Skip step to backup the transaction log                                                                                                                                                                                          |
| PACK                 |               | Possible values: `tar`, `zip`. <br><br> If defined, compresses the output files into a single `.tar.gz` (or `zip`)-File. Uses the `/backup_tmp` directory inside the [Microsoft SQL Server] container to temporarily store the files and moves them to `/backup` afterwards. <br><br> **IMPORTANT**: When using this feature, you have to map the `/backup_tmp` volume inside your [Microsoft SQL Server] and the backup image. |
| ZIP_PASSWORD         |               | Sets the password for the zip to the given value. Only works if `PACK` is set to `zip`                                                                                                                                           |

## Examples

### Docker Compose

The following example will create backups of the databases `MyFirstDatabaseToRestore` and `MySecondDatabaseToRestore`
running inside the `db` container every day at 01.00 CEST and stores it in the `/storage/backup` directory on the host machine.

```yaml
version: '3.7'

services:
  db:
    image: mcr.microsoft.com/mssql/server
    volumes:
      - /storage/backup:/backup
    environment:
      - ACCEPT_EULA=Y
      - MSSQL_PID=Express
      - SA_PASSWORD=MySecre(12)tPassword
    networks:
      - default
  backup:
    image: bbtsoftwareag/mssql-backup
    # for using the cleanup feature, use the backup volume from db.
    # volumes:
    #   - /storage/backup:/backup
    environment:
      - TZ=Europe/Zurich
      - DB_SERVER=db
      - DB_USER=SA
      - DB_PASSWORD=MySecre(12)tPassword
      - "DB_NAMES=
          MyFirstDatabaseToRestore
          MySecondDatabaseToRestore"
      - CRON_SCHEDULE=0 1 * * *
    networks:
      - default
```

[Microsoft SQL Server]: https://hub.docker.com/_/microsoft-mssql-server

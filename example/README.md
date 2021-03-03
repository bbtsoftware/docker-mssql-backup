# BBT Software docker-mssql-backup examples

This directory includes `docker-compose` example files for try out and testing.
It builds a database backup docker image with current project files and creates a sample database container
which contains the standard AdventureWorks2019 database from microsoft for backup.

## Preconditions

The follow precondition is required for using this examples on a desktop.

* Installation of [Docker Desktop](https://www.docker.com/products/docker-desktop) Software.
* `Docker Desktop` must switch to linux containers.

**NOTE:**
[Docker Engine](https://docs.docker.com/engine/) provides .deb and .rpm packages for Linux distribution

## Environment variable

Rename a copy of the template file `.env.template` to `.env` and modify the values of the environment variables.

## Backup directory

The directory `example/backup` will be used for `target` and `example/remote` is used for the `remote` database backup folder.

## Test database

This sample database [AdventureWorksLT2019](https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorksLT2019.bak)
is used for backup.

## Run container

To run this example container execute the command:

`docker-compose up`

## Logging

The backup container cron job write logs to stdout and stderr output streams. Docker containers emit logs to the stdout
and stderr output streams. Because containers are stateless, the logs are stored on the Docker host in JSON files by default.

`docker logs [Container]`

**NOTE:**
The log file location can get with follow docker command:
`docker inspect --format='{{.LogPath}}' [container-id or container-name]`

## Test backup file cleanup

How to modify a backup file `lastwritetime` file setting, to test the backup file cleanup function.
This example changes the `lastwritetime` file setting of `202102041519.AdventureWorks2019.tar.gz` to `2011-09-14T07:10:00`.

`$(Get-Item 202102041519.AdventureWorks2019.tar.gz).lastwritetime=$(Get-Date "2011-09-14T07:10:00")`

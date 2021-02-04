# BBT Software docker-mssql-backup examples

This directory includes `docker-compose` example files for try out and testing.
It builds a database backup docker image with current project files and creates a sample database container
which contains the standard AdventureWorks2019 database from microsoft for backup.

## Preconditions

The follow precondition is required for using this examples.

* Installation of [Docker Desktop](https://www.docker.com/products/docker-desktop) Software.
* `Docker Desktop` must switch to linux containers.

## Environment variable

Rename a copy of the template file `.env.template` to `.env` and modify the values of the environment variables.
The environment file `.env` is ignored by git.

## Backup directory

The directory `example/backup` will be used for target database backup folder.
This folder is ignored by git.

## Test database

This sample database [AdventureWorksLT2019](https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorksLT2019.bak)
is used for backup.

## Run container

To run this example container execute the command:

`docker-compose up`

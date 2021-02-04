#!/bin/bash

# Validate environment variables
[ -z "$DB_SERVER" ] && { echo "Required environment variable DB_SERVER not set" && exit 1; }
[ -z "$DB_USER" ] && { echo "Required environment variable DB_USER not set" && exit 1; }
[ -z "$DB_PASSWORD" ] && { echo "Required environment variable DB_PASSWORD not set" && exit 1; }
[ -z "$DB_NAMES" ] && { echo "Required environment variable DB_NAMES not set" && exit 1; }

echo "Backup started at $(date "+%Y-%m-%d %H:%M:%S")"

CURRENT_DATE=$(date +%Y%m%d%H%M)

# Intermediate working backup directory
WORKDIR="/backup/$CURRENT_DATE"

# Target backup directory
TARGETDIR="/backup"

for CURRENT_DB in $DB_NAMES
do

  # backup database files
  BAK_FILENAME=$WORKDIR/$CURRENT_DATE.$CURRENT_DB.bak

  echo "Backup database $CURRENT_DB to $BAK_FILENAME on $DB_SERVER..."
  if /opt/mssql-tools/bin/sqlcmd -S "$DB_SERVER" -U "$DB_USER" -P "$DB_PASSWORD" -b -Q "BACKUP DATABASE [$CURRENT_DB] TO DISK = N'$BAK_FILENAME' WITH NOFORMAT, NOINIT, NAME = '$CURRENT_DB-full', SKIP, NOUNLOAD, STATS = 10"
  then
    echo "Backup of database successfully created"
  else
    echo "Error creating database backup"
    rm -rf "$BAK_FILENAME"
  fi

  # backup log files
  if [ "$SKIP_BACKUP_LOG" = false ]; then
    TRN_FILENAME=$WORKDIR/$CURRENT_DATE.$CURRENT_DB.trn

    echo "Backup log of $CURRENT_DB to $TRN_FILENAME on $DB_SERVER..."
    if /opt/mssql-tools/bin/sqlcmd -S "$DB_SERVER" -U "$DB_USER" -P "$DB_PASSWORD" -b -Q "BACKUP LOG [$CURRENT_DB] TO DISK = N'$TRN_FILENAME' WITH NOFORMAT, NOINIT, NAME = '$CURRENT_DB-log', SKIP, NOUNLOAD, STATS = 10"
    then
      echo "Backup of log successfully created"
    else
      echo "Error creating log backup"
      rm -rf "$TRN_FILENAME"
    fi
  else
    echo "Backup of log skipped."
  fi

  # Move files from intermediate work to target directory
  echo "Copy backup files to target directory"
  find $WORKDIR -type f -name "*.$CURRENT_DB.bak" -exec mv {} $TARGETDIR \;
  find $WORKDIR -type f -name "*.$CURRENT_DB.trn" -exec mv {} $TARGETDIR \;

  # Delete intermediate directory
  echo "Delete intermediate directory"
  rmdir $WORKDIR

  # Cleanup old backup files in target directory
  if [ "$BACKUP_CLEANUP" = true ]; then
    echo ""
    echo "Backup cleanup is activated"
    find $TARGETDIR -type f -name "*.$CURRENT_DB.bak" -mtime +"$BACKUP_AGE" -exec echo {} " is deleted" \;
    find $TARGETDIR -type f -name "*.$CURRENT_DB.bak" -mtime +"$BACKUP_AGE" -exec rm {} \;

    find $TARGETDIR -type f -name "*.$CURRENT_DB.trn" -mtime +"$BACKUP_AGE" -exec echo {} " is deleted" \;
    find $TARGETDIR -type f -name "*.$CURRENT_DB.trn" -mtime +"$BACKUP_AGE" -exec rm {} \;
  else
    echo "Backup files cleanup is disabled"
  fi

done

echo "Backup process finished at $(date "+%Y-%m-%d %H:%M:%S")"

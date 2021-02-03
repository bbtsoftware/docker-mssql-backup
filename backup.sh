#!/bin/bash

# Validate environment variables
[ -z "$DB_SERVER" ] && { echo "Required environment variable DB_SERVER not set" && exit 1; }
[ -z "$DB_USER" ] && { echo "Required environment variable DB_USER not set" && exit 1; }
[ -z "$DB_PASSWORD" ] && { echo "Required environment variable DB_PASSWORD not set" && exit 1; }
[ -z "$DB_NAMES" ] && { echo "Required environment variable DB_NAMES not set" && exit 1; }

echo "Backup started at $(date "+%Y-%m-%d %H:%M:%S")"

CURRENT_DATE=$(date +%Y%m%d%H%M)
for CURRENT_DB in $DB_NAMES
do

  if [ "$PACK" ]; then
    WORKDIR="/backup_tmp"
    echo "Backup up to $WORKDIR as temporary folder to create compressed files afterwards"
  else
    WORKDIR="/backup"
  fi

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
  fi

  # package backup files into tar.gz or zip file
  if [ "$PACK" = "tar" ] || [ "$PACK" = "zip" ]; then
    echo ""
    cd "$WORKDIR"
    FILES=$(find . -type f \( -name \*\.bak -o -name \*\.trn \))
    if [ "$PACK" = "tar" ]; then
      ARCHIVE_FILENAME="/backup_tmp/$CURRENT_DATE-$CURRENT_DB.tar.gz"
      tar cfvz "$ARCHIVE_FILENAME" $FILES
      retval=$?
    elif [ "$PACK" = "zip" ]; then
      ARCHIVE_FILENAME="/backup_tmp/$CURRENT_DATE-$CURRENT_DB.zip"
      if [ "$ZIP_PASSWORD" ]; then
        zip --password "$ZIP_PASSWORD" "$ARCHIVE_FILENAME" $FILES
        retval=$?
      else
        zip "$ARCHIVE_FILENAME" $FILES
        retval=$?
      fi
    fi

    echo "Packing up results to $ARCHIVE_FILENAME"
    if [ $retval -eq 0 ]; then
        echo "Successfully packed backup into $ARCHIVE_FILENAME"
        mv "$ARCHIVE_FILENAME" "/backup"
    else
        echo "Failed creating $ARCHIVE_FILENAME"
    fi

    rm -rf $FILES
  fi

  # cleanup old backup files
  if [ "$BACKUP_CLEANUP" = true ]; then
    echo ""
    echo "Backup cleanup is activated"
    find /backup -type f -name "*.$CURRENT_DB.bak" -mtime +"$BACKUP_AGE" -exec echo {} " is deleted" \;
    find /backup -type f -name "*.$CURRENT_DB.bak" -mtime +"$BACKUP_AGE" -exec rm {} \;

    find /backup -type f -name "*.$CURRENT_DB.trn" -mtime +"$BACKUP_AGE" -exec echo {} " is deleted" \;
    find /backup -type f -name "*.$CURRENT_DB.trn" -mtime +"$BACKUP_AGE" -exec rm {} \;
  else
    echo "Backup files cleanup is disabled"
  fi

done

echo "Backup process finished at $(date "+%Y-%m-%d %H:%M:%S")"

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

# Remote backup directory
REMOTEDIR="/remote"

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

  if [ "$PACK" = "tar" ] || [ "$PACK" = "zip" ]; then
    # compress backup files into tar.gz or zip file
    echo ""
    echo "Compress backup files"
    FILES=$(find $WORKDIR -type f \( -name \*\.bak -o -name \*\.trn \))
    if [ "$PACK" = "tar" ]; then
      ARCHIVE_FILENAME="$WORKDIR/$CURRENT_DATE.$CURRENT_DB.tar.gz"
      tar cfvz "$ARCHIVE_FILENAME" $FILES
      retval=$?
    elif [ "$PACK" = "zip" ]; then
      ARCHIVE_FILENAME="$WORKDIR/$CURRENT_DATE.$CURRENT_DB.zip"
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
        cp "$ARCHIVE_FILENAME" "$TARGETDIR"
    else
        echo "Failed creating $ARCHIVE_FILENAME"
    fi

    rm -rf $FILES
  else
    # Move files from intermediate work to target directory
    echo "Copy backup files to target directory"
    find $WORKDIR -type f -name "*.$CURRENT_DB.bak"     -exec cp {} $TARGETDIR \;
    find $WORKDIR -type f -name "*.$CURRENT_DB.trn"     -exec cp {} $TARGETDIR \;
  fi

  # Push to remote directory
  if [ "$PUSH_REMOTE_MODE" = "move" ] || [ "$PUSH_REMOTE_MODE" = "copy" ]; then
    echo "Push backup to remote directory"
    find $WORKDIR -type f -name "*.$CURRENT_DB.*" -exec cp {} $REMOTEDIR \;

    if [ "$PUSH_REMOTE_MODE" = "move" ]; then
      echo "Cleanup target directory"
      find $TARGETDIR -type f -name "*.$CURRENT_DB.*" -exec rm {} \;
    fi
  fi

  # Cleanup intermediate directory
  echo "Cleanup intermediate directory"
  find $WORKDIR -type f -name "*.$CURRENT_DB.*" -exec rm {} \;
  rm -rf $WORKDIR

  # Cleanup old backup files in target directory
  if [ "$BACKUP_CLEANUP" = true ]; then
    echo ""
    echo "Backup cleanup is activated"
    find $TARGETDIR -type f -name "*.$CURRENT_DB.*" -mtime +"$BACKUP_AGE" -exec echo {} " is deleted" \;
    find $TARGETDIR -type f -name "*.$CURRENT_DB.*" -mtime +"$BACKUP_AGE" -exec rm {} \;

    if [ "$PUSH_REMOTE_MODE" = "move" ] || [ "$PUSH_REMOTE_MODE" = "copy" ]; then
      echo "Cleanup remote directory"
      find $REMOTEDIR -type f -name "*.$CURRENT_DB.*" -mtime +"$BACKUP_AGE" -exec echo {} " is deleted" \;
      find $REMOTEDIR -type f -name "*.$CURRENT_DB.*" -mtime +"$BACKUP_AGE" -exec rm {} \;
    fi
  else
    echo "Backup files cleanup is disabled"
  fi

done

echo "Backup process finished at $(date "+%Y-%m-%d %H:%M:%S")"

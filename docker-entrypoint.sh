#!/bin/bash

# Store environment variables to pass to cron job
printenv | sed 's/^\([a-zA-Z0-9_]*\)=\(.*\)$/export \1="\2"/g' > /container_env.sh

# Remove quotes from CRON_SCHEDULE
cronSchedule=${CRON_SCHEDULE}
cronSchedule=${cronSchedule%\"} 
cronSchedule=${cronSchedule#\"}

# Create crontab definition
echo "$cronSchedule . /container_env.sh; /usr/local/bin/backup.sh >> /var/log/cron.log 2>&1" > /etc/cron.d/crontab.conf

# Apply cron job
crontab /etc/cron.d/crontab.conf

# Create the log file to be able to run tail
touch /var/log/cron.log

echo "Starting cron task manager..."
echo "$cronSchedule"
cron && tail -f /var/log/cron.log
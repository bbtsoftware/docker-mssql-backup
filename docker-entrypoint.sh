#!/bin/bash

# Create mail config if defined
if [[ $SMTP_HOST ]]; then

    cat << EOF > /etc/ssmtp/ssmtp.conf
root=$SMTP_FROM
mailhub=$SMTP_HOST
AuthUser=$SMTP_USER
AuthPass=$SMTP_PASS
UseSTARTTLS=$SMTP_TLS
UseTLS=$SMTP_TLS
FromLineOverride=YES
hostname=localhost localhost.localdomain
EOF

fi

# Store environment variables to pass to cron job
printenv | sed 's/^\([a-zA-Z0-9_]*\)=\(.*\)$/export \1="\2"/g' > /container_env.sh

# Remove quotes from CRON_SCHEDULE
cronSchedule=${CRON_SCHEDULE}
cronSchedule=${cronSchedule%\"}
cronSchedule=${cronSchedule#\"}

# Create crontab definition
if [[ $SMTP_HOST ]];
then
    echo "$cronSchedule . /container_env.sh; /usr/local/bin/backup.sh 2>&1 | tee /var/log/cron.log | mail -s 'SQL Server Backup Result' $MAIL_TO" > /etc/cron.d/crontab.conf
else
    echo "$cronSchedule . /container_env.sh; /usr/local/bin/backup.sh 2>&1 >> /var/log/cron.log" > /etc/cron.d/crontab.conf
fi

# Apply cron job
crontab /etc/cron.d/crontab.conf

# Create the log file to be able to run tail
touch /var/log/cron.log

echo "Starting cron task manager..."
cron && tail -f /var/log/cron.log
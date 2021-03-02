#!/bin/bash

# Create mail config if defined
if [[ $SMTP_HOST ]]; then

    if [[ $SMTP_TLS = "on" ]]; then

    # Configuration with TLS
    cat << EOF > /etc/msmtprc
defaults

host $SMTP_HOST
port $SMTP_PORT
tls $SMTP_TLS
tls_starttls $SMTP_TLS
tls_trust_file /etc/ssl/certs/ca-certificates.crt
tls_certcheck $SMTP_TLS

account $SMTP_USER
auth $SMTP_AUTH
user $SMTP_USER
password "$SMTP_PASS"
from "$SMTP_USER"

account default: $SMTP_USER

aliases /etc/aliases
EOF

    else

    # Configuration without TLS
    cat << EOF > /etc/msmtprc
defaults

host $SMTP_HOST
port $SMTP_PORT

account $SMTP_USER
auth $SMTP_AUTH
user $SMTP_USER
password "$SMTP_PASS"
from "$SMTP_USER"

account default: $SMTP_USER

aliases /etc/aliases
EOF

    fi

    cat << EOF > /etc/aliases
root: $SMTP_FROM
default: $SMTP_FROM
EOF

    echo 'set sendmail="/usr/bin/msmtp -t"' > /etc/mail.rc

fi

# Store environment variables to pass to cron job
printenv | sed 's/^\([a-zA-Z0-9_]*\)=\(.*\)$/export \1="\2"/g' > /container_env.sh

# Remove quotes from CRON_SCHEDULE
cronSchedule=${CRON_SCHEDULE}
cronSchedule=${cronSchedule%\"} 
cronSchedule=${cronSchedule#\"}

# Write log to stdout
cronLogConfig="> /proc/1/fd/1 2>&1 | tee -a $cronLogFile"

# Create crontab definition
if [[ $SMTP_HOST ]];
then
    echo "Cron e-mail reporting activated. '${SMTP_HOST}'"
    echo "$cronSchedule . /container_env.sh; /usr/local/bin/backup.sh $cronLogConfig | mail -s 'SQL Server Backup Result' $MAIL_TO $cronLogConfig" > /etc/cron.d/crontab.conf
else
    echo "$cronSchedule . /container_env.sh; /usr/local/bin/backup.sh $cronLogConfig" > /etc/cron.d/crontab.conf
fi

# Apply cron job
crontab /etc/cron.d/crontab.conf

echo "Starting cron task manager..."
echo "  - Crontab = $cronSchedule"
cron -f
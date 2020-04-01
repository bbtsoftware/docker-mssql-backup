FROM mcr.microsoft.com/mssql-tools:latest

ENV DB_SERVER="mssql" \
    DB_USER="SA" \
    DB_PASSWORD="" \
    DB_NAMES="" \
    CRON_SCHEDULE="0 1 * * sun"

RUN apt-get update && \
    apt-get install -y cron && \
    rm -rf /var/cache/apk/*

COPY backup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/backup.sh

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]
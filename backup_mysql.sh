#!/usr/bin/bash

currentDate=$(date "+%Y.%m.%d-%H.%M.%S")

docker exec $MYSQL_CONTAINER /usr/bin/mysqldump -u $MYSQL_USER --password=$MYSQL_PASS $MYSQL_DB > /$MYSQL_ENDPOINT/backup_${currentDate}.sql 2>/$MYSQL_ENDPOINT/errors

chmod 400 /${$MYSQL_ENDPOINT}/backup_${currentDate}.sql


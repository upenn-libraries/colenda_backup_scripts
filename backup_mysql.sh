#!/usr/bin/bash

currentDate=$(date "+%Y.%m.%d-%H.%M.%S")

docker exec $MYSQL_CONTAINER /usr/bin/mysqldump -u $MYSQL_USER --password=$MYSQL_PASS $MYSQL_DB > $ENDPOINT/${currentDate}/$MYSQL_ENDPOINT/backup.sql 2>$ENDPOINT/${currentDate}/$MYSQL_ENDPOINT/errors

chmod 400 $ENDPOINT/${currentDate}/$MYSQL_ENDPOINT/backup.sql


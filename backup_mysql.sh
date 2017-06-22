currentDate=$(date "+%Y.%m.%d-%H.%M.%S")
docker exec $MYSQL_CONTAINER /usr/bin/mysqldump -u $MYSQL_USER --password=$MYSQL_PASS $MYSQL_DB > /backups/backup_${currentDate}.sql 2>/backups/errors
chmod 400 /backups/backup_${currentDate}.sql

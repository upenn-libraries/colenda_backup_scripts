docker exec colenda_db_1 /usr/bin/mysqldump -u $MYSQL_USER --password=$MYSQL_PASS $MYSQL_DB > /$ENDPOINT/backup.sql
chmod 600 /$ENDPOINT/backup.sql

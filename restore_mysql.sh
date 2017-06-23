cat backup.sql | docker exec -i $MYSQL_CONTAINER /usr/bin/mysql -u $MYSQL_USER --password=$MYSQL_PASS $MYSQL_DB


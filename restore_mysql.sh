#!/usr/bin/bash

if (( $# != 1 ))
then
  echo "Usage: Supply the absolute path to the MySQL dump you wish to use"
  exit 1
fi

MYSQL_ORIGIN="$1"

cat $MYSQL_ORIGIN | docker exec -i $MYSQL_CONTAINER /usr/bin/mysql -u $MYSQL_USER --password=$MYSQL_PASS $MYSQL_DB


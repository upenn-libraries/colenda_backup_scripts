#!/usr/bin/bash

if (( $# != 1 ))
then
  echo "Usage: Supply the path within the Fedora endpoint, to the Fedora backup you wish to use"
  exit 1
fi

FEDORA_ORIGIN="$1"

docker exec fcrepodev_fcrepo_1 curl --data "/bkup/$FEDORA_ORIGIN" $HOSTNAME:8080/fcrepo/rest/fcr:restore
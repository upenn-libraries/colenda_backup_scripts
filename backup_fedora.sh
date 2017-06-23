#!/usr/bin/bash

currentDate=$(date "+%Y.%m.%d")

docker exec $FEDORA_CONTAINER mkdir -p /bkup/${currentDate}/${FEDORA_ENDPOINT}

docker exec $FEDORA_CONTAINER curl --data "/bkup/${currentDate}/${FEDORA_ENDPOINT}" $HOSTNAME:8080/fcrepo/rest/fcr:backup

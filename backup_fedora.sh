#!/usr/bin/bash

currentDate=$(date "+%Y.%m.%d-%H.%M.%S")

docker exec $FEDORA_CONTAINER mkdir -p /bkup/${currentDate}

docker exec $FEDORA_CONTAINER curl --data "/bkup/${currentDate}" $HOSTNAME:8080/fcrepo/rest/fcr:backup
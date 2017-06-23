#!/usr/bin/bash

currentDate=$(date "+%Y.%m.%d-%H.%M.%S")

mkdir -p $ENDPOINT/${currentDate}/$BARE_REPOS_ENPOINT

rsync -rlptv $BARE_REPOS_ORIGIN/ $ENDPOINT/${currentDate}/$BARE_REPOS_ENPOINT/ > $ENDPOINT/${currentDate}/$BARE_REPOS_ENPOINT/rsync_log
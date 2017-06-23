#!/usr/bin/bash

currentDate=$(date "+%Y.%m.%d")

mkdir -p $ENDPOINT/${currentDate}/$BARE_REPOS_ENDPOINT

rsync -rlptv $BARE_REPOS_ORIGIN/ $ENDPOINT/${currentDate}/$BARE_REPOS_ENDPOINT/ > $ENDPOINT/${currentDate}/$BARE_REPOS_ENDPOINT/rsync_log
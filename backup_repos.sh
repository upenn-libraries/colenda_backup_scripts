#!/usr/bin/bash

currentDate=$(date "+%Y.%m.%d-%H.%M.%S")

mkdir -p $BARE_REPOS_ENPOINT/${currentDate}

rsync -rlptv $BARE_REPOS_ORIGIN/ $BARE_REPOS_ENPOINT/${currentDate}/ > $BARE_REPOS_ENPOINT/${currentDate}/rsync_log
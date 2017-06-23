#!/usr/bin/bash

currentDate=$(date "+%Y.%m.%d-%H.%M.%S")

mkdir -p $BARE_REPOS_BACKUP/${currentDate}

rsync -rlptv $BARE_REPOS_ORIGIN/ $BARE_REPOS_BACKUP/${currentDate}/ > $BARE_REPOS_BACKUP/${currentDate}/rsync_log
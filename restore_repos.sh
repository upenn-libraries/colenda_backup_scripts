#!/usr/bin/bash

if (( $# != 1 ))
then
  echo "Usage: Supply the absolute path to the backups location you wish to use"
  exit 1
fi

BACKUPS_ORIGIN="$1"

rsync -rlptv $BACKUPS_ORIGIN/ $BARE_REPOS_ORIGIN/
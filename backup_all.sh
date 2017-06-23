#!/usr/bin/bash

source ~/.bash_profile

echo "Backing up MySQL..."
./backup_mysql.sh
echo "...done."
echo "Backing up git repos..."
./backup_repos.sh
echo "...done."
echo "Backing up Fedora..."
./backup_fedora.sh
echo "...done."


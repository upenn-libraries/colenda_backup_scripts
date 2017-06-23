# Backup and Restore
This document details step-by-step methods for backing up and restoring each of the following parts of Colenda:
* Bulwark (Rails app) database (repos, arks, application data)
* Bare Git Repos (filesystem-level, used to tether application data and binaries to Ceph cluster and provide interaction layer with git and Bulwark software)
* Fedora (Samvera data backing layer, used by Solr search index and Bulwark front-end)
* Solr (Search index, must be kept in-sync with what is in Fedora)
* Fedora and Solr (Database and filesystem are intact, Fedora and Solr must be rebuilt)
* Entire Application (rebuild from scratch)
## Bulwark Database (Repos, arks, Colenda application database)

### Backup:
1. Source the correct environment variables for the MySQL root user and root password, database to be backed up, the name of the Docker database container, and the name of the backup directory location on the host where the MySQL dumps should be stored, example below:
   ```
   MYSQL_USER=root
   MYSQL_PASS=xyz
   MYSQL_CONTAINER=colenda_db_1
   MYSQL_DB=colenda_db
   ENDPOINT=backup_directory_on_host
     
   export MYSQL_USER;
   export MYSQL_PASS;
   export MYSQL_CONTAINER;
   export MYSQL_DB;
   export ENDPOINT;
   ```
2. With the MySQL container up and running, run the following commands:
   ```
   docker exec $MYSQL_CONTAINER /usr/bin/mysqldump -u $MYSQL_USER --password=$MYSQL_PASS $MYSQL_DB > /$ENDPOINT/backup_${currentDate}.sql 2>/$ENDPOINT/errors
   chmod 400 /$ENDPOINT/backup_${currentDate}.sql
   ```
3. Verify that your backup SQL dump is at its intended destination.  Any errors in the MySQL dump will be logged to a file called "errors" in the ```$ENDPOINT``` directory.  
  
NOTE: This process can be scheduled as a cron job to run as root on a recurring basis.  The ```backup_mysql.sh``` bash script in this repository encapsulates the functionality, provided that the correct variables (specified in step 1) are sourced.  
### Restore:

1. Source the correct environment variables, matching those sourced for the MySQL dump of the database you intend to restore, following the example in step 1 of the "Backups" section above.
2. Ensure that you are starting with a fresh database.  Stop and remove the database container, and remove the database container volume.  This will destroy ALL data remaining in the database for the existing application, so only do this if you have a SQL dump from which to restore the application in hand.
3. Start up the application with a newly-created MySQL container and MySQL container backing volume.  With the MySQL container up and running, run the following command:
   ```
   docker exec $WEB_CONTAINER bundle exec rake db:reset
   ```
   This will populate the empty database with the correct table structure, and will enforce utf-8 encoding.
4. With the MySQL container up and running, run the following command:
   ```
   cat backup.sql | docker exec -i $MYSQL_CONTAINER /usr/bin/mysql -u $MYSQL_USER --password=$MYSQL_PASS $MYSQL_DB
   ```
   Change 'backup.sql' in the cat command to point to the SQL file you wish to use. 
   To use this command verbatim, copy the SQL dump file from which you wish to restore into your current directory and name it 'backup.sql' and then run the above command.
5. Verify that your application has the data from the restore.

NOTE: This process can be run with a bash script.    

## Bare Git Repos (Filesystem)
### Backup:
1. Source the correct environment variables for the location of the bare git repos to be backed up, and the destinate to which they will be backed up, example below:
   ```
   BARE_REPOS_BACKUP=/abs/path/to/backedup/bare/repos
   BARE_REPOS_ORIGIN=/abs/path/to/bare/repos
       
   export BARE_REPOS_BACKUP;
   export BARE_REPOS_ORIGIN;
   ```
2. Run the following command:
   ```
   rsync -rlptv $BARE_REPOS_ORIGIN $BARE_REPOS_BACKUP
   ```
### Restore: 
1. Source the correct environment variable for the location of the backups of the bare git repos and the destination to which those backups are intended to be restored, example below:
   ```
   BARE_REPOS_BACKUP=/abs/path/to/backedup/bare/repos
   BARE_REPOS_ORIGIN=/abs/path/to/bare/repos
     
   export BARE_REPOS_BACKUP;
   export BARE_REPOS_ORIGIN;
   ```
2. Run the following command:
   ```
   rsync -rlptv $BARE_REPOS_BACKUP/ $BARE_REPOS_ORIGIN/
   ```
## Fedora
### Backup:

1. With the desired Fedora backup files present at the endpoint to which the ```/bkup``` directory in the Fedora container is mounted in the host (see example in step 10 in Entire Application:Restore Procedure section for clarity), issue the following command on the running Fedora container:
   ```
   docker exec $FEDORA_CONTAINER curl --data "/bkup" $HOSTNAME:8080/fcrepo/rest/fcr:backup
   ```
   This will export a backup of the Fedora application data to the endpoint to which the ```/bkup``` directory in the Fedora container is mounted in the host.  Go to the ```$LOCAL_BACKUP``` endpoint on the host to verify that the export is available.
### Restore:
Restore command:
1. With the desired Fedora backup files present at the endpoint to which the ```/bkup``` directory in the Fedora container is mounted in the host (see example in step 10 in Entire Application:Restore Procedure section for clarity), issue the following command on the running Fedora container:
   ```
   docker exec $FEDORA_CONTAINER curl --data "/bkup/$FEDORA_ORIGIN" $HOSTNAME:8080/fcrepo/rest/fcr:restore
   ``` 
   This may take a while, depending on how much data is in the Fedora backup.
3. Verify that the data is visible in the front end of the application.  If you see Rails errors indicating that ActiveFedora cannot find objects, this indicates that the Solr index is likely out of sync with what is in Fedora.  Follow the steps in the Solr:Restore section below, restart all containers, and verify that the application is functional with the intended data.
## Solr
### Backup:
There are methods for backing up and restoring from a Solr index, however due to the nature of Fedora's interaction with Solr, and the need for the Solr index to be in lock-step with what is in the Solr index, it is recommended to start from scratch when restoring.  See the Restore section for more information.
### Restore:
1. Stop and remove the Solr container, remove the Solr volume, and start from scratch.
2. In a web browser, navigate to ```$HOSTNAME:8983```, and in the Core Admin section, add a new core called ```blacklight-core```.
3. With all containers up and running for Bulwark, run the following command:
   
   ```docker exec $WEB_CONTAINER bundle exec rails runner "ActiveFedora::Base.reindex_everything"```
   This will reindex all data from Fedora into Solr.  It may take a while, depending on how much data is in the Fedora instance.
## Fedora and Solr
### Backup
Follow the steps in the Fedora:Backup section above.
### Restore
1. Stop and remove the Fedora and Solr containers.  Remove the Fedora volumes (application and db).  Remove the Solr volume.
2. Spin up new Fedora and Solr containers. 
3. Visit the Solr Core Admin in a browser and create a core called ```blacklight-core```.
4. With the desired Fedora backup files present at the endpoint to which the ```/bkup``` directory in the Fedora container is mounted in the host (see example in step 10 in Entire Application:Restore Procedure section for clarity)
   ```
   docker exec $FEDORA_CONTAINER curl --data "/bkup/$FEDORA_ORIGIN" $HOSTNAME:8080/fcrepo/rest/fcr:restore
   ```
## Entire Application

To rebuild the entire application from scratch, the following assets, all taken from the same point in time, are necessary:
* A SQL dump of the application data in Bulwark/Colenda.
* A snapshot of the bare git repos in use in Bulwark/Colenda.
* A Fedora backup of the current state of Bulwark/Colenda.

### Restore Procedure:

1. Stop and remove any still-running containers in Bulwark, Fedora, and Solr.
2. Remove all volumes associated with Bulwark, Fedora, and Solr containers.
3. For Fedora, run the following command from within the Fedora application directory:
   ```
   docker-compose up -d
   ```
4. For Solr, run the following command from within the Solr application directory: 
   ```
   docker-compose up -d
   ``` 
5. In a web browser, navigate to ```$HOSTNAME:8983```, and in the Core Admin section, add a new core called ```blacklight-core```.
6. For Bulwark, run the following command from within the Bulwark application directory:
   ```
   docker-compose up 
   ```
  You can optionally add the ```-d``` flag to daemonize, however it may be useful to keep the output window open during the restore process to catch errors.
7. With all containers running for Bulwark, Fedora, and Solr, run the following command:
   ```
   docker exec -it $WEB_CONTAINER bundle exec rake db:reset
   ```
   You will see the output of this command, adding tables to the MySQL database.  Once this is complete, proceed to step 8.
8. To restore the MySQL data: from within the ```colenda_backup_scripts``` directory, issue the following command:
   ```
   ./restore_mysql.sh /absolute/path/to/backup.sql
   ```
   You will see output complaining about using a password at the command line (which would be perfectly valid, were we not using docker exec commands and sourced variables). Once this is complete, go to the application in a browser and verify that the correct data has been restored.
9. To restore the bare git repos: from within the ```colenda_backup_scripts``` directory, issue the following command:
   ```
    ./restore_repos.sh /absolute/path/to/git_repos
   ```
   You will see output relating to the git repos transferred via rsync.  Once this is complete, verify that the repos are in their intended destination with correct permissions.  You may need to change ownership to the gitannex user in Bulwark (9999:9999).
10. To restore Fedora: this one is a little trickier.  From within the ```colenda_backup_scripts``` directory, issue the following command:
    ```
    ./restore_repos.sh local/path/within/bkup/to/fedora_backup
    ```
    The Fedora container has a volume mounted to a local directory on the server to allow ease of backup transfer.  The Fedora restore command looks in the folder called "bkup" inside the container, which is mapped to the ```$LOCAL_BACKUP``` directory on the host. To find out where this is, run ```docker inspect $FEDORA_CONTAINER | grep LOCAL_BACKUP``` on the running Fedora container.  The backup from which to restore the Fedora installation's data must be inside this directory.  As Fedora already looks in this directory when looking for a backup endpoint, the value of ```$LOCAL_BACKUP``` should not be included in the command line argument.
    
    EXAMPLE:
    Assuming ```$LOCAL_BACKUP =/backup_directory```, move the Fedora restore directory under it. Assuming the Fedora restore directory is now at ```/backup_directory/2017.06.23/fcrepo``` on the host, the command to restore Fedora would look like this:
    ```
    ./restore_repos.sh 2017.06.23/fcrepo
    ```
    You will see output related to this transfer.  Once complete, navigate to ```$HOSTNAME:8080/fcrepo/rest``` in a browser, look for the ```prod``` endpoint, and click around to make sure your objects and their associated metadata and binaries are there. 
11. To restore the Solr index: from within the ```colenda_backup_scripts``` directory, issue the following command:
    ```
    ./reindex_solr.sh 
    ```
    You will not see any output from this command until it is nearly complete, so be patient!  Once this is complete, navigate to ```$HOSTNAME``` in a web browser and click through the Blacklight interface to verify that the Solr index and ActiveFedora are functioning.
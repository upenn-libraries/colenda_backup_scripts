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
4. This process can be scheduled as a cron job to run as root on a recurring basis.  The ```backup_mysql.sh``` bash script in this repository encapsulates the functionality, provided that the correct variables (specified in step 1) are sourced.  
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

NOTE: This process can be expedited with a bash script.  The ```restore_mysql.sh``` bash script in this repository encapsulates the functionality, provided that the correct variables (specified in step 1) are sourced, and the SQL dump is named 'backup.sql', present in the directory from which the bash script is run.  

## Bare Git Repos (Filesystem)

### Backup:
Backup command:

```rsync -rlptv $BARE_REPOS_ORIGIN $BARE_REPOS_BACKUP```

### Restore: 
Restore command:
``` rsync -rlptv /backups/repos/ /colenda_dirs/fs_pub_data/```

## Fedora

### Backup:
Backup command:

where $HOSTNAME=the domain name of the host of the Fedora container, for example ```kate-dev.library.upenn.int```
1. Run the following command on the running Fedora container:
   ```docker exec fcrepodev_fcrepo_1 curl --data '/bkup' $HOSTNAME:8080/fcrepo/rest/fcr:backup```
2. Verify that the backup is present in the directory on the host to which the ```/bkup``` directory in the Fedora container is mapped.

### Restore:
Restore command:
where $HOSTNAME=the domain name of the host of the Fedora container, for example ```kate-dev.library.upenn.int```
2. Run the following command on the running Fedora container:
   
   ```docker exec fcrepodev_fcrepo_1 curl --data '/bkup' $HOSTNAME:8080/fcrepo/rest/fcr:restore``` 
   This may take a while, depending on how much data is in the Fedora backup.
3. Verify that the data is visible in the front end of the application.  If you see Rails errors indicating that ActiveFedora cannot find objects, this indicates that the Solr index is likely out of sync with what is in Fedora.  Follow the steps in the Solr:Restore section below, restart all containers, and verify that the application is functional with the intended data.

## Solr

### Backup:

There are methods for backing up and restoring from a Solr index, however due to the nature of Fedora's interaction with Solr, and the need for the Solr index to be in lock-step with what is in the Solr index, it is recommended to start from scratch when restoring.  See the Restore section for more information.

### Restore:

1. Stop and remove the Solr container, remove the Solr volume, and start from scratch.
2. With all containers up and running for Bulwark, run the following command:
  
   ```docker exec colenda_web_1 bundle exec rails runner "ActiveFedora::Base.reindex_everything"```
   This will reindex all data from Fedora into Solr.  It may take a while, depending on how much data is in the Fedora instance.

## Fedora and Solr

### Backup

Follow the steps in the Fedora:Backup section above.

### Restore

1. Stop and remove the Fedora and Solr containers.  Remove the Fedora volumes (application and db).  Remove the Solr volume.
2. Spin up new Fedora and Solr containers. 
3. Visit the Solr Core Admin in a browser and create a core called ```blacklight-core```.
4. With the desired Fedora backup files present where

## Entire Application

To rebuild the entire application from scratch, the following assets, all taken from the same point in time, are necessary:
* A SQL dump of the application data in Bulwark/Colenda.
* A snapshot of the bare git repos in use in Bulwark/Colenda.
* A Fedora backup of the current state of Bulwark/Colenda.

### Restore Procedure:
 
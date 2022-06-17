#!/bin/bash
DATE=$(date +"%d%b%y")
PATH=${PATH}:/usr/local/bin
MAIL=emailaddress
HOST=$(hostname)
export SCRIPTDIR=/home/oracle/scripts/rman

# Verwijder eerst logfiles ouder dan 2 weken.
if [ -d ${SCRIPTDIR}/logging ]; then
        cd ${SCRIPTDIR}/logging
        find . -name '*.log' -mtime +14 -exec rm {} \;
fi
# set +x

# Start de backup
# ps -ef|grep -v grep|grep pmon|awk '{printf(substr($8,10)"\n")}' | while read DBSID
# do
#############################
# Set environment for DBSID
#############################
export ORACLE_SID=$1
export ORAENV_ASK=NO; . oraenv
#############################
# Start RMAN backup
#############################
${ORACLE_HOME}/bin/rman nocatalog target / log="${SCRIPTDIR}/logging/${ORACLE_SID}_backup_full_hot_$DATE.log" <<EOF
run {
#       Set parameters.
# CONFIGURE RETENTION POLICY TO REDUNDANCY OF 2 COPIES ;
CONFIGURE RETENTION POLICY TO REDUNDANCY = 2;
CONFIGURE BACKUP OPTIMIZATION ON;
CONFIGURE ENCRYPTION FOR DATABASE ON;
CONFIGURE CONTROLFILE AUTOBACKUP ON;
CONFIGURE DEVICE TYPE DISK BACKUP TYPE TO COMPRESSED BACKUPSET;
# create schema report
report schema;
#check database for logical and physical corruption.
backup validate check logical database;
#backup full database plus controlfile
backup AS COMPRESSED BACKUPSET full database
        include current controlfile
        tag full_backup
        format '/u01/app/oracle_backup/backup/%d_DATABASE_%s_%p.BCK';
SQL 'ALTER SYSTEM ARCHIVE LOG CURRENT';
# Backup archivelogs delete input
backup AS COMPRESSED BACKUPSET archivelog all delete input
tag Archivelogs
format '/u01/app/oracle_backup/backup/%d_ARCHIVES_%s_%p.BCK';
# Backup control file to trace.
SQL 'ALTER DATABASE BACKUP CONTROLFILE TO TRACE';
CONFIGURE CONTROLFILE AUTOBACKUP OFF;
}
EOF

# Maintenance
${ORACLE_HOME}/bin/rman nocatalog target / log="${SCRIPTDIR}/logging/${ORACLE_SID}_Maintenance_$DATE.log" <<EOF
run {
report obsolete;
delete noprompt obsolete;
crosscheck backup;
delete noprompt expired backup;
crosscheck archivelog all;
delete noprompt expired archivelog all;
delete noprompt archivelog until time 'sysdate-2'; }
EOF

# Recovery catalog synchroniseren
${ORACLE_HOME}/bin/rman target / catalog rman/Cardif01@EMREP <<EOF
resync catalog;
EOF

done


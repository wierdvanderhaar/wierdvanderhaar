#!/bin/bash

function logdate {
  echo -n `date +%F" "%a" "%T"."%N | awk -F "." '{ print $1"." substr($2,1,3)}'`' - '
}

DATUM=`date -I`
logdate && echo Variable DATUM: $DATUM

BACKUPDIR=/tmp/ovm_export_db
# backup map aanmaken
if [ ! -d "$BACKUPDIR" ]; then
       logdate && echo Backup dir $BACKUPDIR aanmaken
       mkdir -p $BACKUPDIR
fi

logdate && echo Backups ouder dan 60 dagen verwijderen
find /backup/ovm_export_db -name 'ovm_export_db_*.tar.gz' -mtime +60 -exec rm {} \;

logdate && echo Backup tempdir $BACKUPDIR leegmaken
rm -rf $BACKUPDIR/*

# OVM backup maken bron MOS Doc ID 1522460.1
export WORK_DIR=$BACKUPDIR

logdate && echo Variablen exporteren uit /u01/app/oracle/ovm-manager-3/.config
for i in `cat /u01/app/oracle/ovm-manager-3/.config` ; do export $i && echo $i; done

cd /u01/app/oracle/ovm-manager-3/ovm_upgrade/bin

logdate && echo Start ovm_upgrade.sh --export
sh ./ovm_upgrade.sh  --export --dbuser=$OVSSCHEMA --dbpass=Oracleovm3 --dbhost=$DBHOST --dbport=$LSNR --dbsid=$SID --workpath=$WORK_DIR
logdate && echo Export gereed

logdate && echo TAR $BACKUPDIR naar /backup/ovm_export_db/ovm_export_db_$DATUM.tar.gz
mkdir -p /backup/ovm_export_db
#tar -zcf /backup/ovm_export_db/ovm_export_db_$DATUM.tar.gz $BACKUPDIR
tar -zcf /backup/ovm_export_db/ovm_export_db_$DATUM.tar.gz -C $BACKUPDIR .
logdate && echo TAR gereed

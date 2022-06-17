#! /bin/bash
. ~/.bash_profile
set -x
# for i in `cat /home/oracle/scripts/db_list.lst`
ps -ef|grep -v grep|grep arc0|awk '{printf(substr($8,10)"\n")}' | while read DBSID
do
    echo $DBID
    export ORACLE_SID=$DBSID
    export ORAENV_ASK=NO; . oraenv
    export DBNAME=`echo ${ORACLE_SID} | grep -E '^[A-Za-z]' | awk -F [1-9] '{print $1}'`
    echo ${DBNAME}
    export DBNAME=`${DBNAME} | awk '{print toupper($0)}'`
#    mkdir -p /u01/backup/${DBNAME}
rman target / <<EOF
crosscheck archivelog all;
delete noprompt archivelog until time "SYSDATE-2";
EOF
done

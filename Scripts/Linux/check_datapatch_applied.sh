#! /bin/bash
. ~/.bash_profile

# set -x

# Set environment
export SCRIPTDIR=/home/oracle/dbanl

# Start online backup. For elke database in archivelogmode
ps -ef|grep -v grep|grep m00|awk '{printf(substr($8,10)"\n")}' | while read DBSID
do
    echo ${DBSID}
    export ORACLE_SID=${DBSID}
    export ORAENV_ASK=NO; . /usr/local/bin/oraenv
    ${ORACLE_HOME}/bin/sqlplus / as sysdba @$SCRIPTDIR/pdbs.sql <<EOF
column ACTION_TIME format a30
column COMMENTS format a50
select ACTION_TIME,COMMENTS from registry\$history;
EOF
done

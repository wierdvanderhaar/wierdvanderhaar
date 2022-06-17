#! /bin/bash
. ~/.bash_profile

# set -x

# Set environment
export SCRIPTDIR=/home/oracle/dbanl/scripts

ps -ef|grep -v grep|grep m00|awk '{printf(substr($8,10)"\n")}' | while read DBSID
do
    echo ${DBSID}
    export ORACLE_SID=${DBSID}
    export ORAENV_ASK=NO; . /usr/local/bin/oraenv
    ${ORACLE_HOME}/bin/sqlplus / as sysdba <<EOF
-- select CLIENT_NAME,STATUS from DBA_AUTOTASK_CLIENT;
EXEC DBMS_AUTO_TASK_ADMIN.DISABLE('SQL TUNING ADVISOR',NULL,NULL);
EXEC DBMS_AUTO_TASK_ADMIN.DISABLE('AUTO SPACE ADVISOR',NULL,NULL);
select CLIENT_NAME,STATUS from DBA_AUTOTASK_CLIENT;
EOF
    ${ORACLE_HOME}/bin/sqlplus / as sysdba @$SCRIPTDIR/pdb.sql <<EOF
-- select CLIENT_NAME,STATUS from DBA_AUTOTASK_CLIENT;
EXEC DBMS_AUTO_TASK_ADMIN.DISABLE('SQL TUNING ADVISOR',NULL,NULL);
EXEC DBMS_AUTO_TASK_ADMIN.DISABLE('AUTO SPACE ADVISOR',NULL,NULL);
select CLIENT_NAME,STATUS from DBA_AUTOTASK_CLIENT;
EOF
done

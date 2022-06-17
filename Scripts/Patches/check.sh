#! /bin/bash
. ~/.bash_profile

#########################################################################
#                                                                       #
#               SET ENVIRONMENT                                         #
#                                                                       #
#########################################################################
# set -x
export PATH=/usr/local/bin:$ORACLE_HOME/bin:$PATH
export DATE=`date +%Y%m%d`
export ORATAB=/etc/oratab

ps -ef|grep -v grep|grep pmon|awk '{printf(substr($8,10)"\n")}' | while read DBSID
do
    echo $DBID
    export ORACLE_SID=$DBSID
    ORAENV_ASK=NO ; . oraenv
#     $ORACLE_HOME/bin/sqlplus '/ as sysdba' <<EOF
# alter pluggable database all open;
# EOF
     echo "$ORACLE_SID"
#    $ORACLE_HOME/OPatch/datapatch -verbose
    $ORACLE_HOME/bin/sqlplus '/ as sysdba' <<EOF
set lines 200
set pages 100
SELECT status,
 patch_id
 FROM   sys.dba_registry_sqlpatch;
EOF
done

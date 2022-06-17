#! /bin/bash
#. ~/.bash_profile
sh /etc/profile.d/oracle.sh

#########################################################################
#                                                                       #
#               SET ENVIRONMENT                                         #
#                                                                       #
#########################################################################
set -x
export PATH=/usr/local/bin:$ORACLE_HOME/bin:$PATH
export DATE=`date +%Y%m%d`
export SCRIPTDIR=/home/oracle/scripts/changepwd
export LOGDIR=${SCRIPTDIR}/logging/${DATE}
export ORATAB=/etc/oratab

export USERNAME=$1
export NEWPWD=$2


ps -ef|grep -v grep|grep rsm0|awk '{printf(substr($8,10)"\n")}' | while read DBSID
do
    echo $DBID
    export ORACLE_SID=$DBSID
    ORAENV_ASK=NO ; . oraenv
    $ORACLE_HOME/bin/dgmgrl / "show database '${ORACLE_SID}02'"
done


# Handige grep
./check_DG_Status.sh | egrep 'Database|Lag'
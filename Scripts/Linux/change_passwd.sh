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


ps -ef|grep -v grep|grep pmon|awk '{printf(substr($8,10)"\n")}' | while read DBSID
do
    echo $DBID
    export ORACLE_SID=$DBSID
    ORAENV_ASK=NO ; . oraenv
    $ORACLE_HOME/bin/sqlplus '/ as sysdba' <<EOF
    alter user ${USERNAME} identified by $NEWPWD;
EOF
echo "Het wachtwoord voor $USERNAME in database $ORACLE_SID is gewijzigd in $NEWPWD"
done

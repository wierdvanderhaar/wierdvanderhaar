#! /bin/bash
. ~/.bash_profile
#########################################################################
#                                                                       #
#               SET ENVIRONMENT                                         #
#                                                                       #
#########################################################################
set -x
export PATH=/usr/local/bin:$ORACLE_HOME/bin:$PATH
export DATE=`date +%Y%m%d`

export ORACLE_SID=CMAN
export ORAENV_ASK=NO ; . oraenv
export WHAT=$1

if [ "$WHAT" == "shutdown" ]
then
$ORACLE_HOME/bin/cmctl <<EOF
administer cman_wscman01
shutdown abort
EOF
else
$ORACLE_HOME/bin/cmctl <<EOF
administer cman_wscman01
startup
EOF
fi

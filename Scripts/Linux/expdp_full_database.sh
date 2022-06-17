#!/bin/bash
set -x
export hostname=`hostname`
export ORACLE_SID=$1
export DBNAME=`echo ${ORACLE_SID^^}`
export ORAENV_ASK=NO; . oraenv
# Export NLS_LANG from db
export NLS_LANG=`echo "SELECT ''||a.value||'_'||b.VALUE||'.'||c.VALUE||'' FROM (select VALUE from nls_database_parameters where parameter = 'NLS_LANGUAGE') a, (select VALUE from nls_database_parameters where parameter = 'NLS_TERRITORY') b,(select VALUE from nls_database_parameters where parameter = 'NLS_CHARACTERSET') c;" | sqlplus -s / as sysdba | grep -v A.VALUE | grep _` && printenv NLS_LANG
mkdir -p /backup/${hostname}/${DBNAME}

sqlplus / as sysdba <<EOF
create or replace directory EXPDP as '/backup/${hostname}/${DBNAME}';
grant read, write on directory EXPDP to system;
EOF

expdp system/dbawork directory=EXPDP FILE=expdp_full_${ORACLE_SID}.DMP full=Y logfile=expdp_full_${ORACLE_SID}.LOG REUSE_DUMPFILES=Y CONSISTENT=y

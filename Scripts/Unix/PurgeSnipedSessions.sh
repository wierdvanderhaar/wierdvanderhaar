#! /usr/bin/ksh
#
# Name            : PurgeSnipedSessions.sh
# Parameters      : -
# 
# Description
# -----------
# Purge all unix processes for sniped sessions.
#
# History
# -------
# 25-03-2008  JSTEI  Initial release



# -------------------------------------------------------------------------------------------------
# Name         : InitVars
# Parameters   : -
#
# Description
# -----------
# Initialize variables.
# -------------------------------------------------------------------------------------------------

InitVars() {
   ORATAB_LOC=/var/opt/oracle/oratab
   if [ ! -f ${ORATAB_LOC} ]; then
      echo ${0}': Cannot locate configuration file '${ORATAB_LOC} >&2
      exit 1
   fi

   if [ `echo ':'${PATH}':' | grep ':/usr/local/bin:' | wc -l` -eq 0 ]; then
      export PATH=${PATH}:/usr/local/bin
   fi
}

# -------------------------------------------------------------------------------------------------
# Name         : ListRunningInstances
# Parameters   : -
#
# Description
# -----------
# List all running instances
# -------------------------------------------------------------------------------------------------

ListRunningInstances() {
   ps -ef| grep ora_smon[_] | cut -c58- | sort
}

# -------------------------------------------------------------------------------------------------
# Name         : ListSnipedSessions
# Parameters   : -
#
# Description
# -----------
# List all sniped sessions on the current instance.
# -------------------------------------------------------------------------------------------------

ListSnipedSessions() {
 sqlplus -s /nolog <<EOF
 connect / as sysdba
 select p.spid from v\$process p,v\$session s
 where s.paddr=p.addr
   and s.status='SNIPED'
   and s.server = 'DEDICATED';
EOF
}

# -------------------------------------------------------------------------------------------------
#                                   M A I N
# -------------------------------------------------------------------------------------------------

InitVars
for DB in `ListRunningInstances`; do
   export ORAENV_ASK=NO
   export ORACLE_SID=${DB}

   if [ `grep '^'${DB}':' ${ORATAB_LOC} | wc -l` -ne 1 ]; then
      echo ${0}': Instance '${DB}' not defined in '${ORATAB_LOC}' or defined more than once' >&2
      continue
   fi

   . /usr/local/bin/oraenv
   echo Checking instance $DB
   for PID in `ListSnipedSessions | grep '^[0-9]'`; do
      ps -fp ${PID}|tail -1
      kill -9 ${PID}
   done
done


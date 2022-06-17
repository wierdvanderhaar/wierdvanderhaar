#! /usr/bin/ksh
#
# Name            : CompileInvalids.sh
# Parameters      : -
#
# Description
# -----------
# Compile all invalid objects for all databases
#
# History
# -------
# 20-07-2011  BBAK   Initial release



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
# Name         : CompileAll
# Parameters   : -
#
# Description
# -----------
#
# -------------------------------------------------------------------------------------------------

CompileAll() {
 sqlplus -s  /nolog <<EOF
 connect / as sysdba

 set pages 9999
 set lines 200
 set trimspool on

 break on report
 compute sum of aantal on report

 select owner , object_type , count(*) aantal
 from dba_objects
 where status = 'INVALID'
 group by  owner , object_type
 order by  owner , object_type
 ;

 @$ORACLE_HOME/rdbms/admin/utlrp.sql

 select owner , object_type , count(*) aantal
 from dba_objects
 where status = 'INVALID'
 group by  owner , object_type
 order by  owner , object_type
 ;


EOF
}





# -------------------------------------------------------------------------------------------------
# OpenLogfile
# -------------------------------------------------------------------------------------------------

OpenLogfile() {


LOGFILE=CompileInvalids.log

exec 6>&1           # Link file descriptor #6 with stdout.
                    # Saves stdout.

exec > $LOGFILE     # stdout replaced logfile


}

# -------------------------------------------------------------------------------------------------
# CloseLogfile
# -------------------------------------------------------------------------------------------------


CloseLogfile() {

exec 1>&6 6>&-      # Restore stdout and close file descriptor #6.

}


# -------------------------------------------------------------------------------------------------
#                                   M A I N
# -------------------------------------------------------------------------------------------------

InitVars

OpenLogfile

for DB in `ListRunningInstances`; do
   export ORAENV_ASK=NO
   export ORACLE_SID=${DB}

   if [ `grep '^'${DB}':' ${ORATAB_LOC} | wc -l` -ne 1 ]; then
      echo ${0}': Instance '${DB}' not defined in '${ORATAB_LOC}' or defined more than once' >&2
      continue
   fi

   . /usr/local/bin/oraenv
   echo Compiling $DB
   CompileAll
done

CloseLogfile



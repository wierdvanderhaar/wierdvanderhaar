#! /usr/bin/ksh

# --------------------------------------------------------------
# Name       : InitVars
# Parameters : -
# 
# Description
# -----------
# Initialize variables
# --------------------------------------------------------------

InitVars() {
   ORASETTINGS_LOC=/var/opt/oracle/orasettings
   if [ ! -f ${ORASETTINGS_LOC} ]; then
      echo ${0}": Cannot find file "${ORASETTINGS_LOC} >&2
      exit 1
   fi

   ORATAB_LOC=/var/opt/oracle/oratab
   if [ ! -f ${ORATAB_LOC} ]; then
      echo ${0}": Cannot find file "${ORATAB_LOC} >&2
      exit 1
   fi

   RMAN_USER=`grep '^RMAN_USER=' ${ORASETTINGS_LOC} | cut -d= -f 2`
   if [ -z "${RMAN_USER}" ]; then
      echo ${0}": Parameter RMAN_USER not defined in "${ORASETTINGS_LOC} >&2
      exit 1
   fi

   RMAN_PWD=`grep '^RMAN_PWD=' ${ORASETTINGS_LOC} | cut -d= -f 2`
   if [ -z "${RMAN_PWD}" ]; then
      echo ${0}": Parameter RMAN_PWD not defined in "${ORASETTINGS_LOC} >&2
      exit 1
   fi

   RMAN_TS_NAME=`grep '^RMAN_TS_NAME=' ${ORASETTINGS_LOC} | cut -d= -f 2`
   if [ -z "${RMAN_TS_NAME}" ]; then
      echo ${0}": Parameter RMAN_TS_NAME not defined in "${ORASETTINGS_LOC} >&2
      exit 1
   fi

   RMAN_PRIVILEGES=`grep '^RMAN_PRIVILEGES=' ${ORASETTINGS_LOC} | cut -d= -f 2`
   if [ -z "${RMAN_PRIVILEGES}" ]; then
      echo ${0}": Parameter RMAN_PRIVILEGES not defined in "${ORASETTINGS_LOC} >&2
      exit 1
   fi

   RMAN_DEVICE_TYPE=`grep '^RMAN_DEVICE_TYPE=' ${ORASETTINGS_LOC} | cut -d= -f 2`
   if [ -z "${RMAN_DEVICE_TYPE}" ]; then
      echo ${0}": Parameter RMAN_DEVICE_TYPE not defined in "${ORASETTINGS_LOC} >&2
      exit 1
   fi

   RMAN_CHANNEL_PARAM=`grep '^RMAN_CHANNEL_PARAM=' ${ORASETTINGS_LOC} | cut -d= -f 2-`
   if [ -z "${RMAN_CHANNEL_PARAM}" ]; then
      echo ${0}": Parameter RMAN_CHANNEL_PARAM not defined in "${ORASETTINGS_LOC} >&2
      exit 1
   fi

   Pd=0
}

# ------------------------------------------------------------
# Name       : ParseParams
# Parameters : -
#
# Description
# -----------
# Parse the parameters supplied.
# ------------------------------------------------------------

ParseParams() {
   while getopts c:hi:u: name 2>/dev/null
   do
      case ${name} in
      d)   Pd=1
           ;;
      ?)   echo Invalid option ${name} >&2
           exit 2;;
      esac
   done

   if [ ${OPTIND} -gt 1 ]; then
      shift $((${OPTIND} -1))
   fi

   DB_LIST=${*}
   DB_COUNT=${#}
}

ListInstances() {
   if [ ${DB_COUNT} -eq 0 ]; then
      echo ${ORACLE_SID}
   else
      for DB_NAME in ${DB_LIST}; do
         echo ${DB_NAME}
      done
   fi
}

# --------------------------------------------------------------
# Name       : SetInstanceEnvironment
# Parameters : -
# 
# Description
# -----------
# Set the correct environment
# --------------------------------------------------------------

SetInstanceEnvironment() {
   RMAN_CMD=${ORACLE_HOME}/bin/rman
   RMAN_OH=${ORACLE_HOME}

   RMAN_CHANNEL_PARAM=`echo ${RMAN_CHANNEL_PARAM} | sed "s:\\${RMAN_OH}:"${RMAN_OH}":g"`
}

RunSQL() {
   TMP_RUNSQL_FILE=/tmp/runsql_${$}.tmp
   ( echo set feedback off
     echo set pagesize 0
     echo set heading off
     echo set trimspool on
     echo connect / as sysdba
     echo ${*}
     echo /
     echo exit
     echo exit
   ) 2>&1 | ${ORACLE_HOME}/bin/sqlplus -s /nolog | grep -v 'Connected' | tee ${TMP_RUNSQL_FILE}

   grep 'ORA-' ${TMP_RUNSQL_FILE} >/dev/null 2>&1
   if [ ${?} -eq 0 ]; then
      RETVAL=1
   else
      RETVAL=0
   fi

   rm ${TMP_RUNSQL_FILE}
}

# --------------------------------------------------------------
# Name       : CreateUser
# Parameters : -
# 
# Description
# -----------
# Create the actual RMAN user
# --------------------------------------------------------------

CreateUser() {
   RunSQL 'CREATE USER '${RMAN_USER}' IDENTIFIED BY '${RMAN_PWD}' DEFAULT TABLESPACE '${RMAN_TS_NAME}
}

# --------------------------------------------------------------
# Name       : GrantPrivileges
# Parameters : -
# 
# Description
# -----------
# Grant actual privileges to the RMAN user
# --------------------------------------------------------------

GrantPrivileges() {
   for PRIVILEGE in `echo ${RMAN_PRIVILEGES} | tr ',' ' '`; do
      RunSQL 'GRANT '${PRIVILEGE}' TO '${RMAN_USER}
   done
}

# --------------------------------------------------------------
# Name       : ConfigureRMANdefaults
# Parameters : -
# 
# Description
# -----------
# Configure the defaults for RMAN and store them in the controlfile.
# --------------------------------------------------------------

ConfigureRMANdefaults() {
   TMP_FILE=/tmp/`basename ${0}`_${$}.tmp
   RMAN_LOG_FILE=/tmp/x.log

   (
      echo "RUN {"
      # IFS='@'
      for CMD in `grep 'RMAN_CONFIGURATION_PARAMETER=' ${ORASETTINGS_LOC}| cut -d= -f 2- | tr ' ' '@'`; do
         echo ${CMD}";" |
            sed 's:\${RMAN_DEVICE_TYPE}:'${RMAN_DEVICE_TYPE}':g' |
            sed 's:\${RMAN_CHANNEL_PARAM}:'${RMAN_CHANNEL_PARAM}':g'|
            tr '@' ' '
      done 
      echo "show all;"
      echo "exit"
      echo "}"
   ) >${TMP_FILE}

   ${RMAN_CMD} nocatalog target ${RMAN_USER}/${RMAN_PWD} msglog $RMAN_LOG_FILE append cmdfile=${TMP_FILE}
}

# ------------------------------------------------------------------
#    M A I N   P R O G R A M
# ------------------------------------------------------------------

InitVars
ParseParams ${*}
ListInstances | while read INSTANCE_NAME; do
   if [ "${ORACLE_SID}" != "${INSTANCE_NAME}" ]; then
      ORACLE_HOME=`grep '^'${INSTANCE_NAME}':' ${ORATAB_LOC} | cut -d: -f 2`
      if [ -z "${ORACLE_HOME}" ]; then
         echo ${0}": Instance "${INSTANCE_NAME}" not defined in "${ORATAB_LOC} >&2
         continue
      fi
   fi

   SetInstanceEnvironment
   if [ ! -f ${RMAN_CMD} ]; then
      echo ${0}": Rman executable "${RMAN_CMD}" not found" >&2
      continue
   fi

   CreateUser
   if [ ${RETVAL} -ne 0 ]; then
      echo ${0}": An error occurred while creating the user "${RMAN_USER} >&2
      echo ${0}": aborting configuration of RMAN for instance "${ORACLE_SID} >&2
      continue
   fi

   GrantPrivileges

   ConfigureRMANdefaults
done


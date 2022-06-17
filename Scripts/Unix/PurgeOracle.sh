#!/bin/ksh
#
# Name       : PurgeOracle.sh
# Parameters : -
#
# Description
# -----------
# Remove old logfiles and truncate large logfiles
#
# History
# ----------------
# 2008-01-03  JSTEI  Remove algorithm altered. Dump directory itself was
#                    removed when no files where recently altered.
# 2008-01-10  JSTEI  Files based on suffix were erroroneously not removed.
# 2009-01-14  JSTEI  Export/dumpfile locations are also purged

# -----------------------------------------------------------------
# Name       : CheckPositiveValue
# Parameters : parameter_name
#              parameter_value
# 
# Description
# ------------
# Verify that parameter_value contains a positive value. Return an
# error otherwise.
# -----------------------------------------------------------------

CheckPositiveValue() {
   if [ -z "${2}" ]; then
      echo ${0}": No value for parameter "${1}" specified in "${ORASETTINGS_LOC} >&2
      exit 2
   fi
   expr ${2} + 0 >/dev/null 2>&1
   if [ ${?} -ne 0 ]; then
      echo ${0}": Value for parameter "${1}" ["${2}"] specified in "${ORASETTINGS_LOC}" is not numeric" >&2
      exit 2
   fi
   if [ ${?} -lt 0 ]; then
      echo ${0}": Value for parameter "${1}" ["${2}"] specified in "${ORASETTINGS_LOC}" cannot be negative" >&2
      exit 2
   fi
}

# -----------------------------------------------------------------
# Name       : InitVars
# Parameters : -
# 
# Description
# ------------
# Initialize variables.
# -----------------------------------------------------------------

InitVars() {
   export ORATAB_LOC=/var/opt/oracle/oratab
   export ORASETTINGS_LOC=/var/opt/oracle/orasettings
   export ORACLE_BASE=/u01/app/oracle
   export ORACLE_ADMIN=${ORACLE_BASE}/admin

   export PURGE_ARCHIVE_RETENTION=`grep '^PURGE_ARCHIVE_RETENTION=' ${ORASETTINGS_LOC} | cut -d= -f 2 | head -1`
   CheckPositiveValue "PURGE_ARCHIVE_RETENTION" "${PURGE_ARCHIVE_RETENTION}"

   export PURGE_AUDIT_RETENTION=`grep '^PURGE_AUDIT_RETENTION=' ${ORASETTINGS_LOC} | cut -d= -f 2 | head -1`
   CheckPositiveValue "PURGE_AUDIT_RETENTION" "${PURGE_AUDIT_RETENTION}"

   export PURGE_EXPORT_RETENTION=`grep '^PURGE_EXPORT_RETENTION=' ${ORASETTINGS_LOC} | cut -d= -f 2 | head -1`
   CheckPositiveValue "PURGE_EXPORT_RETENTION" "${PURGE_EXPORT_RETENTION}"

   export PURGE_DUMP_RETENTION=`grep '^PURGE_DUMP_RETENTION=' ${ORASETTINGS_LOC} | cut -d= -f 2 | head -1`
   CheckPositiveValue "PURGE_DUMP_RETENTION" "${PURGE_DUMP_RETENTION}"

   export PURGE_MAX_ALERTFILE_SIZE=`grep '^PURGE_MAX_ALERTFILE_SIZE=' ${ORASETTINGS_LOC} | cut -d= -f 2 | head -1`
   CheckPositiveValue "PURGE_MAX_ALERTFILE_SIZE" "${PURGE_MAX_ALERTFILE_SIZE}"

   export PURGE_MAX_LISTENERLOG_SIZE=`grep '^PURGE_MAX_LISTENERLOG_SIZE=' ${ORASETTINGS_LOC} | cut -d= -f 2 | head -1`
   CheckPositiveValue "PURGE_MAX_LISTENERLOG_SIZE" "${PURGE_MAX_LISTENERLOG_SIZE}"

   export DUMP_BASE_DIRECTORY=`grep '^DUMP_BASE_DIRECTORY=' ${ORASETTINGS_LOC} | cut -d= -f 2 | head -1`
   if [ -z ''${DUMP_BASE_DIRECTORY} ]; then
      echo ${0}': Parameter DUMP_BASE_DIRECTORY not definied in '${ORASETTINGS_LOC} >&2
      exit 1
   fi
}

# -----------------------------------------------------------------
# Name       : PurgeDir
# Parameters : 1 - Directory
#              2 - Retention period in days
#              3 - suffix (optional)
# 
# Description
# ------------
# Remove all files and subdirectories in the specified directory
# with an access time older than the retention period. 
# Optionally, check the suffix.
# -----------------------------------------------------------------

PurgeDir() {
   for FILENAME in `find ${1} -atime +${2} -print`; do
      if [ ${FILENAME} != ${1} ]; then
         if [ ${#} -ge 3 ]; then
            if [ `echo ${FILENAME} | grep ${3}'$' | wc -l` -gt 0 ]; then
               if [ -d ${FILENAME} ]; then
                  rm -rf ${FILENAME} 
               else
                  rm -f ${FILENAME} 
               fi
            fi
         else
            if [ -d ${FILENAME} ]; then
               rm -rf ${FILENAME} 
            else
               rm -f ${FILENAME} 
            fi
         fi
      fi
   done
}

# -----------------------------------------------------------------
# Name       : PurgeArchiveLogs
# Parameters : 1 - ORACLE_SID
# 
# Description
# ------------
# Remove all archivelog files older than the defined retention period.
# -----------------------------------------------------------------

PurgeArchiveLogs() {
   if [ -d ${ORACLE_ADMIN}/${1}/arch ]; then
      echo "- Archive logfiles older than "${PURGE_ARCHIVE_RETENTION}" days...\c"

      PurgeDir ${ORACLE_ADMIN}/${1}/arch ${PURGE_ARCHIVE_RETENTION}
      echo 
   fi
}

# -----------------------------------------------------------------
# Name       : PurgeAuditLogs
# Parameters : 1 - ORACLE_SID
# 
# Description
# ------------
# Remove all audit files older than the defined retention period.
# -----------------------------------------------------------------

PurgeAuditLogs() {
   if [ -d ${ORACLE_ADMIN}/${1}/adump ]; then
      echo "- Audit files older than "${PURGE_AUDIT_RETENTION}" days...\c"
      PurgeDir ${ORACLE_ADMIN}/${1}/adump ${PURGE_AUDIT_RETENTION} .aud
      echo 
   fi
}

# -----------------------------------------------------------------
# Name       : PurgeBackgroundDump
# Parameters : 1 - ORACLE_SID
# 
# Description
# ------------
# Remove all files in the background dump location older than the
# specified retention period.
# -----------------------------------------------------------------

PurgeBackgroundDump() {
   if [ -d ${ORACLE_ADMIN}/${1}/bdump ]; then
      echo "- Background dump files older than "${PURGE_DUMP_RETENTION}" days...\c"
      PurgeDir ${ORACLE_ADMIN}/${1}/bdump ${PURGE_DUMP_RETENTION}
      echo 
   fi
}

# -----------------------------------------------------------------
# Name       : PurgeCoreDump
# Parameters : 1 - ORACLE_SID
# 
# Description
# ------------
# Remove all files in the coredump location older than the specified
# retention period.
# -----------------------------------------------------------------

PurgeCoreDump() {
   if [ -d ${ORACLE_ADMIN}/${1}/cdump ]; then
      echo "- Coredump files older than "${PURGE_DUMP_RETENTION}" days...\c"
      PurgeDir ${ORACLE_ADMIN}/${1}/cdump ${PURGE_DUMP_RETENTION}
      find ${ORACLE_ADMIN}/${1}/cdump -name '*core*' -type d -exec rmdir {} \; 2>/dev/null
      echo 
   fi
}

# -----------------------------------------------------------------
# Name       : PurgeUserDump
# Parameters : 1 - ORACLE_SID
# 
# Description
# ------------
# Remove all files in the user dump location older than the
# specified retention period.
# -----------------------------------------------------------------

PurgeUserDump() {
   if [ -d ${ORACLE_ADMIN}/${1}/udump ]; then
      echo "- User log files older than "${PURGE_DUMP_RETENTION}" days...\c"
      PurgeDir ${ORACLE_ADMIN}/${1}/udump ${PURGE_DUMP_RETENTION}
      echo 
   fi
}

# -----------------------------------------------------------------
# Name       : TruncateAlertLogs
# Parameters : 1 - ORACLE_SID
# 
# Description
# ------------
# Truncate large files in the background dump location.
# -----------------------------------------------------------------

TruncateAlertLogs() {
   if [ -d ${ORACLE_ADMIN}/${1}/bdump ]; then
      for LARGEFILE in `find ${ORACLE_ADMIN}/${1}/bdump -name '*.log' -size +${PURGE_MAX_ALERTFILE_SIZE}c`
      do
         if [ `echo ${LARGEFILE} | grep '.gz$' | wc -l` -eq 1 ]; then
            continue
         fi

         if [ `fuser -u ${LARGEFILE} 2>&1 | grep '(' | wc -l` -ne 0 ]; then
            continue
         fi

         echo '- Truncate file '${LARGEFILE}' ...\c'
         BACKUPFILE=${LARGEFILE}.`date '+%Y%m%d'`'.gz'
         cat ${LARGEFILE} | gzip -c >${BACKUPFILE}
         # truncate alert file
         > ${LARGEFILE}
         echo 
      done
   fi
}

# -----------------------------------------------------------------
# Name       : TruncateListenerLogs
# Parameters : 1 - ORACLE_SID
# 
# Description
# ------------
# Truncate grote bestanden in de background dump locatie.
# -----------------------------------------------------------------

TruncateListenerLogs() {
   ORACLE_HOME=`grep '^LISTENER:' ${ORATAB_LOC} | cut -d: -f 2`
   if [ -d ${ORACLE_HOME}/network/log ]; then
      for LISTENER_FILE in `find ${ORACLE_HOME}/network/log -name '*.log' -size +${PURGE_MAX_LISTENERLOG_SIZE}c`
      do  
         if [ `echo ${LISTENER_FILE} | grep '.gz$' | wc -l` -eq 1 ]; then
            continue
         fi

         if [ `fuser -u ${LISTENER_FILE} 2>&1 | grep '(' | wc -l` -ne 0 ]; then
            continue
         fi

         echo 'Truncate listener log '${LISTENER_FILE}' ...\c'
         BACKUPFILE=${LISTENER_FILE}.`date '+%Y%m%d'`'.gz'
         cat ${LISTENER_FILE} | gzip -c >${BACKUPFILE}
         # truncate listener.log
         > ${LISTENER_FILE}
         echo 
      done
   fi
}

# -----------------------------------------------------------------
# Name       : PurgeAuditLogsRDBMS
# Parameters : -
# 
# Description
# ------------
# Remove all audit logs in the central audit location older than
# the defined retention period.
# -----------------------------------------------------------------

PurgeAuditLogsRDBMS() {
   for OHOME in `grep ':' ${ORATAB_LOC} | grep -v '^#' | cut -d: -f 2 | sort | uniq`; do
      if [ -d ${OHOME}/rdbms/audit ]; then
         echo 'Purge audit-log in Oracle Home '${OHOME}' older than '${PURGE_AUDIT_RETENTION}' days...\c'
      PurgeDir ${OHOME}/rdbms/audit ${PURGE_AUDIT_RETENTION} .aud
         echo
      fi
   done
}

PurgeExports() {
   export ORACLE_SID=${1}
   EXPORT_DIRECTORY=`eval echo ${DUMP_BASE_DIRECTORY}`
   if [ -d ${EXPORT_DIRECTORY} ]; then
      echo '- exports/dumps in '${EXPORT_DIRECTORY}' older than '${PURGE_EXPORT_RETENTION}' days...\c'
      PurgeDir ${EXPORT_DIRECTORY} ${PURGE_EXPORT_RETENTION}
      echo 
   fi
}

# -------------------------------------------------------------------
#                 H O O F D P R O G R A M M A
# -------------------------------------------------------------------

InitVars

cat $ORATAB_LOC | sort | while read LINE
do
  case $LINE in
    \#*) ;;        #comment-line in oratab
    [a-z,A-Z]*) 
      ORACLE_SID=`echo $LINE | awk -F: '{print $1}' -`
      ORACLE_HOME=`echo $LINE | awk -F: '{print $2}' -`
      AUTOSTART=`echo $LINE | awk -F: '{print $3}' -`
      BACKUP_MODE=`echo $LINE | awk -F: '{print $4}' -`

      if [ -f ${ORACLE_HOME}/dbs/orapw${ORACLE_SID} ]; then
         echo "Purge files instance "${ORACLE_SID}

         if [ "${BACKUP_MODE}" != "H" ]; then
            PurgeArchiveLogs    ${ORACLE_SID}
         fi

         PurgeAuditLogs      ${ORACLE_SID}
         PurgeBackgroundDump ${ORACLE_SID}
         PurgeCoreDump       ${ORACLE_SID}
         PurgeUserDump       ${ORACLE_SID}
#         TruncateAlertLogs   ${ORACLE_SID}
         PurgeExports        ${ORACLE_SID}
      fi
    ;;
  esac
done

#TruncateListenerLogs
PurgeAuditLogsRDBMS

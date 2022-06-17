#! /usr/bin/ksh
# 
# Name  : StatusStageArea.sh
#
# History
# -------
# 2007-08-10  JSTEI  Default for d_VAL is retention period
# 2007-11-09  JSTEI  read statements replace by 'for .. in'
# 2007-11-09  JSTEI  Stage area info is no longer displayed if
#                    stage area directory does no longer exist.
# 2007-11-09  JSTEI  Check whether to use awk or nawk
# 2008-12-23  JSTEI  Datum weergave was foutief. Gecorrigeerd.



# -------------------------------------------------------------
# Name       : InitVars
# Parameters : -
#
# Description
# -----------
# Initialize variables.
# -------------------------------------------------------------

InitVars() {
   ORATAB_LOC=/var/opt/oracle/oratab
   if [ ! -f ${ORATAB_LOC} ]; then
      echo ${0}": Cannot find "${ORATAB_LOC} >&2
      exit 1
   fi

   ORASETTINGS_LOC=/var/opt/oracle/orasettings
   if [ ! -f ${ORASETTINGS_LOC} ]; then
      echo ${0}": Cannot find "${ORASETTINGS_LOC} >&2
      exit 1
   fi

   HOTCOPY_LOGFILE_DEFAULT=`grep '^HOTCOPY_LOGFILE=' ${ORASETTINGS_LOC} | cut -d= -f 2`
   if [ -z "${HOTCOPY_LOGFILE_DEFAULT}" ]; then
      echo ${0}": Value for HOTCOPY_LOGFILE not defined in "${ORASETTINGS_LOC} >&2
      exit 1
   fi

   HOTCOPY_RETENTION_DEFAULT=`grep '^HOTCOPY_RETENTION_DAYS=' ${ORASETTINGS_LOC} | cut -d= -f 2`
   if [ -z "${HOTCOPY_RETENTION_DEFAULT}" ]; then
      echo ${0}": Value for HOTCOPY_RETENTION_DEFAULT not defined in "${ORASETTINGS_LOC} >&2
      exit 1
   fi

   AWK_EXEC=`which nawk 2>/dev/null`
   if [ -z "${AWK_EXEC}" ]; then
      AWK_EXEC=`which awk`
   fi

   Pd=0
   Ps=0
   Pv=0
   PD=0

   s_VAL=''
   d_VAL=`CalculateStartDate 7`
   D_VAL=''
}

# ---------------------------------------------------------------
# Name      : Show_Usage
# Parameter : -
#
# Description
# -----------
# Show the correct usage of this script
# ---------------------------------------------------------------

Show_Usage() {
   (
       echo "Usage: "${0}" [options...] instance..."
       echo
       echo "Options"
       echo "-------"
       echo "-d days"
       echo "   Only show entries from d days or earlier"
       echo "   Default equals the retention period"
       echo "-D date"
       echo "   Date the files where copied to the staging area"
       echo "   format YYMMDD"
       echo "-h"
       echo "   Help info"
       echo "-s status"
       echo "   Only show entries with the given status"
       echo "-v"
       echo "   Verbose"
   ) >&2
}

# ---------------------------------------------------------------
# Name      : CalculateStartDate
# Parameter : days
#
# Description
# -----------
# Determine the date n days ago.
# ---------------------------------------------------------------

CalculateStartDate() {
   YYYY=`date '+%Y'`
   MM=`date '+%m'`
   DD=`date '+%d'`

   COUNT=${1}
   while [ ${COUNT} -gt 0 ]; do
#     Use remaining days in current month

      DD_STEPS=`expr ${DD} - 1`
      if [ ${DD_STEPS} -gt ${COUNT} ]; then
        DD=`expr ${DD} - ${COUNT}`
        COUNT=0
      else
        DD=1
        COUNT=`expr ${COUNT} - ${DD_STEPS}`
      fi
      if [ ${COUNT} -eq 0 ]; then
         continue
      fi

#     Go the previous month
      MM=`expr ${MM} - 1`
      if [ ${MM} -eq 0 ]; then
         MM=12
         YYYY=`expr ${YYYY} - 1`
      fi
      case ${MM} in
         1)	DD=31 
		;;
         2)	if [ `expr ${YYYY} \% 4` -ne 0 ]; then
                   DD=28
                elif [ `expr ${YYYY} \% 400 -eq 0 ]; then
                   DD=29
                elif [ `expr ${YYYY} \% 100 -eq 0 ]; then
                   DD=28
                else
                   DD=29
                fi
		;;
         3)	DD=31 
		;;
         4)	DD=30
		;;
         5)	DD=31 
		;;
         6)	DD=30
		;;
         7)	DD=31 
		;;
         8)	DD=31
		;;
         9)	DD=30
		;;
         10)	DD=31 
		;;
         11)	DD=30
		;;
         12)	DD=31 
		;;
      esac
      COUNT=`expr ${COUNT} - 1`
   done
   echo $YYYY $MM $DD | ${AWK_EXEC} '{ printf("%4.4d%2.2d%2.2d",$1,$2,$3 ) }'
}

# ------------------------------------------------------------
# Name       : ParseParams
# Parameters : parameter list
#
# Description
# -----------
# Parse the parameters.
# ------------------------------------------------------------

ParseParams() {
   while getopts d:s:vD:? name 2>/dev/null
   do
      case ${name} in
      D)   PD=1
           if [ ${Pd} -eq 1 ]; then
              echo ${0}": Options d and D are mutually exclusive" >&2
              exit 2
           fi
           expr ${OPTARG} + 1 >/dev/null 2>&1
           if [ ${?} -ne 0 ]; then
              echo ${0}": Value for parameter "${name}" "${OPARG}" is not a date" >&2
              exit 2
           fi
           D_VAL=${OPTARG}
           if [ ${D_VAL} -lt 70000 -o ${D_VAL} -gt 999999 ]; then
              echo ${0}": Value for parameter "${name}" "${OPARG}" is not a date" >&2
              exit 2
           fi
           ;;
      d)   Pd=1
           if [ ${PD} -eq 1 ]; then
              echo ${0}": Options d and D are mutually exclusive" >&2
              exit 2
           fi
           if [ -z ''${OPTARG} ]; then
              Show_Usage
              exit 2
           fi
           expr ${OPTARG} + 0 >/dev/null 2>&1
           if [ ${?} -ne 0 ]; then
              echo ${0}": Number of days must be numeric" >&2
              Show_Usage
              exit 2
           fi
           if [ ${OPTARG} -lt 0 ]; then
              echo ${0}": Number of days must be positive" >&2
              Show_Usage
              exit 2
           fi
           d_VAL=`CalculateStartDate ${OPTARG}`
           ;;
      s)   s_VAL="${OPTARG}"
           if [ -z ''${s_VAL} ]; then
              Show_Usage
              exit 2
           fi
           Ps=1
           ;;
      v)   Pv=1
           ;;
      ?)   Show_Usage
           exit 2;;
      esac
   done

   shift $((${OPTIND} -1))

   INSTANCE_COUNT=${#}
   INSTANCE_LIST=`echo ${*} | sed 's/[ ] */,/g'`
}

# -------------------------------------------------------------
# Name       : ListInstances
# Parameters : -
#
# Description
# -----------
# List all the instances that are defined in ORATAB
# -------------------------------------------------------------

ListInstances() {
   grep ':' ${ORATAB_LOC} |
      grep -v '#' |
      grep -v -i '^listener'  |
      cut -d: -f 1 |
      sort
}

# -------------------------------------------------------------
# Name       : GetInstanceVariables
# Parameters : -
#
# Description
# -----------
# Determine all the instance specific variables.
# -------------------------------------------------------------

GetInstanceVariables() {
   HOTCOPY_LOGFILE_INSTANCE=`grep -i '^HOTCOPY_LOGFILE_'${ORACLE_SID}'=' ${ORASETTINGS_LOC} | cut -d= -f 2 | head -1`
   if [ -z "${HOTCOPY_LOGFILE_INSTANCE}" ]; then
      HOTCOPY_LOGFILE_INSTANCE=${HOTCOPY_LOGFILE_DEFAULT}
   fi

   if [ ${Pd} -eq 0 ]; then
      HOTCOPY_RETENTION_INSTANCE=`grep -i '^HOTCOPY_RETENTION_DAYS_'${ORACLE_SID}'=' ${ORASETTINGS_LOC} | cut -d= -f 2 | head -1`
      if [ -z "${HOTCOPY_RETENTION_INSTANCE}" ]; then
         HOTCOPY_RETENTION_INSTANCE=${HOTCOPY_RETENTION_DEFAULT}
      fi
      d_VAL=`CalculateStartDate ${HOTCOPY_RETENTION_INSTANCE}`
   else
      HOTCOPY_RETENTION_INSTANCE=${d_VAL}
   fi
}

# -------------------------------------------------------------
# Name       : ListLogFileInfo
# Parameters : name of log file
#
# Description
# -----------
# Extract the info in the logfile
# -------------------------------------------------------------

ListLogFileInfo() {
   cat ${1} | 
   sed 's/[ ] *$//g' | 
   ${AWK_EXEC} '
BEGIN			{ LINE = -1 
			}
/Run date/		{ DAYNAME=substr($4,1,3)
                          if ( index("ma,di,wo,do,vr,za,zo",DAYNAME) > 0 ) {
                             LANGUAGE=NL
                             MONTH_ABBR=substr($5,1,3)
                             OFFSET=index("jan,feb,maa,apr,mei,jun,jul,aug,sep,okt,nov,dec,Jan,Feb,Maa,Apr,Mei,Jun,Jul,Aug,Sep,Okt,Nov,Dec",MONTH_ABBR)
                             MM = ( OFFSET + 3 ) / 4
                             if ( MM > 12 ) MM = MM - 12
                             DD=$6
                          } else {
                             LANGUAGE=UK
                             MONTH_ABBR=substr($5,1,3)
                             OFFSET=index("jan,feb,mar,apr,may,jun,jul,aug,sep,oct,nov,dec,Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec",MONTH_ABBR)
                             MM = ( OFFSET + 3 ) / 4
                             if ( MM > 12 ) MM = MM - 12
                             DD=$6
                          }
                          YY=$NF
                        }
/Staging area/		{ AREA=$4
			}
/Oracle database/	{ ORACLE_SID=$4 }
/DATAFILES/		{ STARTTIJD = $2 }
/CONTROLFILE/		{ STOPTIJD = $2 }
/TABLESPACE/		{ LINE=NR + 2 
                          STATUS="OK"
                          SECTION="TS"
                        }
/FILETYPE/		{ LINE=NR + 2 
                          SECTION="FILETYPE"
                        }
/Current online log/	{ ARCHIVE_START=$4
                          ARCHIVE_END=$5 - 1

                          printf("%s,%s,%4.4d%2.2d%2.2d,%s,%d,%d,%s,%s\n",AREA,ORACLE_SID,YY,MM,DD,STATUS,ARCHIVE_START,ARCHIVE_END,STARTTIJD,STOPTIJD)
			}
NR == LINE		{ if ( SECTION == "TS" ) 
                             if ( NF > 0 ) {
                                LINE=LINE + 1
                                if ( STATUS != $NF ) {
                                   STATUS=$NF
                                }
                             }
                          if ( SECTION="FILETYPE" )
                             if ( NF > 0 ) {
                                LINE=LINE + 1
                                if ( $1 != "DATAFILES" )
                                   if ( STATUS != $NF ) {
                                      STATUS=$NF
                                   }
                             }
                        }
'
}

# -------------------------------------------------------------
# Name       : FilterInfo
# Parameters : Data files
#
# Description
# -----------
# Filter the logfile data based on the parameters.
# -------------------------------------------------------------

FilterInfo() {
   LF_STAGE_AREA=`echo ${*} | cut -d, -f 1`
   LF_SID=`echo ${*} | cut -d, -f 2`
   LF_YYYYMMDD=`echo ${*} | cut -d, -f 3`
   LF_STATUS=`echo ${*} | cut -d, -f 4`
   LF_ARCHIVE_START=`echo ${*} | cut -d, -f 5`
   LF_ARCHIVE_STOP=`echo ${*} | cut -d, -f 6`
   LF_START=`echo ${*} | cut -d, -f 7`
   LF_STOP=`echo ${*} | cut -d, -f 8`

   SHOW=Y

   if [ ${INSTANCE_COUNT} -gt 0 ]; then
      SHOW=N
      for INSTANCE_NAME in ${INSTANCE_LIST}; do
         if [ ${INSTANCE_NAME} = ${LF_SID} ]; then
            SHOW=Y
         fi
      done
   fi

   if [ ${Pd} -eq 1 ]; then
      if [ ${LF_YYYYMMDD} -lt ${d_VAL} ]; then
         SHOW=N
      fi
   fi

   if [ ${PD} -eq 1 ]; then
      if [ `echo ${LF_YYYYMMDD} | cut -c3-` -ne ${D_VAL} ]; then
         SHOW=N
      fi
   fi
   if [ ${Ps} -eq 1 ]; then
      if [ "${LF_STATUS}" != "${s_VAL}" ]; then
         SHOW=N
      fi
   fi

   if [ ! -d ${LF_STAGE_AREA} ]; then
      SHOW=N
   fi

   if [ ${SHOW} = "Y" ]; then
      echo ${DATALINE} | cut -d, -f 2-
   fi
}

ShowAllLogFileData() {
   for ORACLE_SID in `ListInstances`; do
      GetInstanceVariables
      HOTCOPY_LOGFILE_MASK=`echo ${HOTCOPY_LOGFILE_INSTANCE} |
                            sed 's/\${ORACLE_SID}/'${ORACLE_SID}'/g' |
                            sed 's/\${SEQUENCE}/[0-9][0-9][0-9]/g' |
                            sed 's/\${YYMMDD}/[0-9][0-9][0-1][0-9][0-3][0-9]/g'`
      for HOTCOPY_LOGFILE in ${HOTCOPY_LOGFILE_MASK}; do
         if [ ! -f ${HOTCOPY_LOGFILE} ]; then
            continue
         fi
         ListLogFileInfo ${HOTCOPY_LOGFILE} 
      done
   done 
}

InitVars
ParseParams ${*}
for DATALINE in `ShowAllLogFileData`; do
   FilterInfo "${DATALINE}"
done   |
sort -t, -k1,2 |
${AWK_EXEC} ' 
BEGIN   { FS=","
          if ( 1 == '${Pv}' ) {
             print("Instance  Date      Time      Time      LogSeq   LogSeq   Status") 
             print("                    Started   Stopped   Started  Stopped") 
             print("--------  --------  --------  --------  -------  -------  ------")
          }
        }

	{ DSP_SID=$1
          DSP_YY=substr($2,3,2)
          DSP_MM=substr($2,5,2)
          DSP_DD=substr($2,7,2)
          DSP_STARTED=$6
          DSP_STOPPED=$7
          DSP_ARCH_BEGIN=$4
          DSP_ARCH_END=$5
          DSP_STATUS=$3
          printf("%-8s  %2.2d-%2.2d-%2.2d  %8s  %8s  %7d  %7d  %s\n",DSP_SID,DSP_YY,DSP_MM,DSP_DD,DSP_STARTED,DSP_STOPPED,DSP_ARCH_BEGIN,DSP_ARCH_END,DSP_STATUS)
        }
'



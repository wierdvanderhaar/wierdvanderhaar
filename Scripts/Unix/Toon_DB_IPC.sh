#! /bin/ksh
#
# Gebruik   : Toon_DB_IPC
# Parameters: {-db | -shmid | -shmkey | -semid | -semkey } value...
#
# Omschrijving
# ------------
#
# Historie
# --------
# 30-10-2007  JSTEI  Initialisatie Oracle environment gewijzigd.
# 02-12-2008  JSTEI  Ondersteuning voor meerdere semaphores en shared memory segments per instance

InitVariabelen() {
   ORATAB_LOC=/var/opt/oracle/oratab
   ORAENV_ASK=NO
   TOON_HEADER=YES
   SHM_PARNAME='Shared_memory'
   SEM_PARNAME='Semaphores'
}


# ----------------------------------------------------------------
# Naam       : Help_Aanroep
# Parameters : programmanaam
# 
# Omschrijving
# ------------
# Toon helpinformatie bij aanroep
# ----------------------------------------------------------------

Help_Aanroep() {
   (
      echo Aanroep: ${0} [optie].. waarde
      echo 
      echo Mogelijke opties
      echo ----------------
      echo -db databasenaam \(default\)
      echo -shmid shared_memory_id
      echo -shmkey shared_memory_key
      echo -semid semaphore_id
      echo -semkey semaphore_key
   ) >&2
}

# ----------------------------------------------------------------
# Naam       : SmonList
# Parameters : -
# 
# Omschrijving
# ------------
# Genereer een overzicht van databanken waarvan een smon-instance
# actief is.
# ----------------------------------------------------------------

SmonList() {
   # ps -fu oracle | grep 'ora_smon[_]' | cut -c57-|sort
   OS=`uname -s`
   if [ "${OS}" = "Linux" ]; then
      ps -e -o command
   else
      ps -e -o comm
   fi | 
   grep 'ora_smon[_]' |
   cut -c10- | 
   sort
}

# ----------------------------------------------------------------
# Naam       : Oracle8ShmParameters
# Parameters : 
# 
# Omschrijving
# ------------
# Bepaal het shared memory gebruik van een 8i instance.
#
# Retourvariabelen
# ----------------
# SHM_ID     Shared Memory ID
# SHM_KEY    Shared Memory Key
# ----------------------------------------------------------------

Oracle8ShmParameters()
{
   svrmgrl >/dev/null 2>&1 <<EOF
connect internal
oradebug ipc
exit
EOF
   TRC_FILENAME=`ls -1t ${ORACLE_BASE}/admin/${ORACLE_SID}/udump/*.trc | head -1`
   SHM_ID=`cat ${TRC_FILENAME} | awk 'BEGIN { SHM_NR=0 }
/Shmid/	{ SHM_NR = NR + 1 }
SHM_NR == NR	{ print $3 ; exit }
'`
   SHM_KEY=`ipcs -m | grep '^m[ \t]*'${SHM_ID}'[ \t]'|cut -c16-25`

   rm ${TRC_FILENAME} >/dev/null 2>&1
}

# ----------------------------------------------------------------
# Naam       : Get_IPC
# Parameters : databasenaam
# 
# Omschrijving
# ------------
# Bepaal IPC gebruik voor de opgegeven database
#
# Retourvariabelen
# ----------------
# SHM_ID     Shared Memory ID
# SHM_KEY    Shared Memory Key
# SEM_ID     Semaphore ID
# SEM_KEY    Semaphore Key
# ----------------------------------------------------------------

Get_IPC()
{
   export ORAENV_ASK=NO
   export ORACLE_SID=${1}
   . /usr/local/bin/oraenv
   unset ORAENV_ASK

   # sysresv | tr '\t' ' ' | sed 's/ [ ] */,/' | awk '

   # SHM_ID

   sysresv | awk '
		BEGIN			{ SHM_LNR = 0
                                          SHM_PARNAME="'${SHM_PARNAME}'"
					} 
		/ORACLE_SID/		{ 
			  			split($5,f,"\"")
			  			SID = f[2]
                        	        }
		/^Shared Memory:/	{ SHM_LNR=NR+2 }
		/^Semaphores:/		{ SHM_LNR=0 
					}
		NR == SHM_LNR		{ 
                         		  printf("%s,'${SHM_PARNAME}',%s,%s\n",SID,$1,$2)
                         		  SHM_LNR=NR + 1
					}
		' 

   sysresv | awk '
		BEGIN			{ SEM_LNR=0
					} 
		/ORACLE_SID/		{ 
			  			split($5,f,"\"")
			  			SID = f[2]
                        	        }
		/^Semaphores:/		{ SEM_LNR=NR + 2
					}
                /^Oracle/               { SEM_LNR = 0 }
		NR == SEM_LNR		{ 
                         		  printf("%s,'${SEM_PARNAME}',%s,%s\n",SID,$1,$2)
                         		  SEM_LNR=NR + 1
					}
		'

}

# ----------------------------------------------------------------
# Naam       : Toon_IPC
# Parameters : database
#              parameter
#              id
#              key
# 
# Omschrijving
# ------------
# Toon individuele IPC gegevens
# ----------------------------------------------------------------

Toon_IPC() {
   if [ ${TOON_HEADER} = 'YES' ]; then
      ToonHeader
      TOON_HEADER=NO
   fi

   echo ${1},${2},${3},${4} | awk '
	      BEGIN { FS="," }
                    { printf("%-8s ",$1) 
                      printf("%-15s ",$2) 
                      printf("%-12s ",$3) 
                      printf("%-12s ",$4) 
                      printf("\n")
                    }'
}

# ----------------------------------------------------------------
# Naam       : ToonHeader
# Parameters : -
# 
# Omschrijving
# ------------
# Toon de header voor de uitvoer
# ----------------------------------------------------------------

ToonHeader() {
   echo | awk 'BEGIN { printf("%-8s %-15s %-12s %-12s\n","Database","Parameter","ID","KEY") }'
}

# ----------------------------------------------------------------
#    H O O F D P R O G R A M M A
# ----------------------------------------------------------------

InitVariabelen

if [ ${#} -eq 0 ]; then
   for DB in `SmonList`; do
      for DATALINE in `Get_IPC ${DB}`; do
         Toon_IPC `echo ${DATALINE} | tr ',' ' '`
      done
   done
else
   SELECTIE=1
   for OPTIE in ${*}
   do
      case ${OPTIE} in
         '-h')   	Help_Aanroep
                        exit 0
                        ;;
         '-db') 	SELECTIE=1
			;;
        '-shmid')  SELECTIE=2
			;;
         '-shmkey') 	SELECTIE=3
			;;
         '-semid')  	SELECTIE=4
			;;
         '-semkey') 	SELECTIE=5
			;;
	 '-header')	TOON_HEADER=YES
			;;
	 '-noheader')	TOON_HEADER=NO
			;;
         *) 		for DB in `SmonList`
                        do
                           for DATALINE in `Get_IPC ${DB}`; do
                              PAR=`echo ${DATALINE} | cut -d, -f 2`
                              ID=`echo ${DATALINE} | cut -d, -f 3`
                              KEY=`echo ${DATALINE} | cut -d, -f 4`

			      case ${SELECTIE} in
				   1)	if [ x${DB} == x${OPTIE} ]; then
                                           Toon_IPC `echo ${DATALINE} | tr ',' ' '`
 					fi
					;;
				   2)	if [ ${PAR} = ${SHM_PARNAME} ]; then
				   	   if [ x${ID} == x${OPTIE} ]; then
                                              Toon_IPC `echo ${DATALINE} | tr ',' ' '`
 					   fi
 					fi
					;;
				   3)	if [ ${PAR} = ${SHM_PARNAME} ]; then
				   	   if [ x${KEY} == x${OPTIE} ]; then
                                              Toon_IPC `echo ${DATALINE} | tr ',' ' '`
 					   fi
 				        fi
				        ;;
				   4)	if [ ${PAR} = ${SEM_PARNAME} ]; then
				   	   if [ x${ID} == x${OPTIE} ]; then
                                              Toon_IPC `echo ${DATALINE} | tr ',' ' '`
 					   fi
 					fi
					;;
				   5)	if [ ${PAR} = ${SEM_PARNAME} ]; then
				   	   if [ x${KEY} == x${OPTIE} ]; then
                                              Toon_IPC `echo ${DATALINE} | tr ',' ' '`
 					   fi
 					fi
				        ;;
			      esac
                           done
                         done
      esac
   done
fi

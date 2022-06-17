#!/bin/bash
# ---------------------------------------------------------------------------------------------------
# File name:		orabackup.sh
# Version:		2018.080.1			
# Purpose:		Back-up Oracle databases			
# Parameters:           --all			: Back-up van alle gestarte instances
#			-e			: Komma gescheiden lijst met alle instances die uitgesloten (exclude) worden.
#					  	  Gebruiken i.c.m. --all
#			-d			: Komma gescheiden lijst met instances die geback-upt dienen te worden.
#						  Gebruiken i.p.v. --all
#			--online		: Online back-up (default)
#			--offline		: Offline back-up
#                                                 De database dient vanuit het rman (rcv) script in mount fase gebracht te
#                                                 worden en daarna ook weer geopend.
#                                                 Een offline back-up van een RAC database wordt niet ondersteund
#			--incremental	        : Incrementele back-up
#			-l			: Level van de incrementele back-up. Toegestane waarden zijn 0 en 1 
#						  Gebruiken i.c.m. --incremental
#			--archivelog	        : Archivelog back-up
#			--clusterdb		: Betreft cluster databases in een RAC
#			--catalog		: Synchronisatie naar een Rman catalog
#                       --configfile            : Gebruik van extern configuratie bestand $SCRIPTDIR/config/backup.conf       
#
# Author:		Gerben Lenderink
# History:		Version		Date		Author		Change Description
#			2018.080.1	21-03-2018	G. Lenderink	1e definitieve versie
#
# ---------------------------------------------------------------------------------------------------

# --------------------------------------------
# Script configuration
# --------------------------------------------
PATH=/usr/local/bin:$PATH
ORAENV_ASK=NO
SCRIPTNAME=$(basename "$0")
SCRIPTDIR=$( cd "$(dirname "$0")" && pwd )
EXECDATE=$(date +"%d%m%Y_%H%M")
ONLINESCRIPT="BackupDbOnline.rcv"		    	# Naam online back-up script
OFFLINESCRIPT="BackupDbOffline.rcv"		        # Naam offline back-up script
ARCHIVELOGSCRIPT="BackupArchivelog.rcv"			# Naam archivelog back-up script
INCREMENTALSCRIPT="BackupDbIncremental.rcv"			# Naam incremental back-up script
ARCHIVELOGFILEBASENAME="Archive"				# Eerste deel van de archivelog	back-up logfile naam	
ONLINELOGFILEBASENAME="Online"				# Eerste deel van de online back-up logfile naam
OFFLINELOGFILEBASENAME="Offline"				# Eerste deel van de offline back-up logfile naam
INCREMENTALLOGFILEBASENAME="Incremental"		# Eerste deel van de incremental back-up logfile naam
DEFEXCLUDELIST='+ASM,-MGMTDB,+APX'			# Instances die standaard worden uitgesloten van een back-up
CONFIGFILE="$SCRIPTDIR/config/backup.conf"              # Naam en locatie van eventueel te gebruiken extern configuratiebestand

# De onderstaande variabelen moeten gedefinieerd zijn als geen gebruik gemaakt wordt van een extern configuratiebestand
# bij de aanroep van dit script.
BCKSCRIPTDIR="$SCRIPTDIR/rman"          # Default locatie van de back-up (rcv) bestanden
BCKLOGDIR="$SCRIPTDIR/logging"          # Default locatie van de back-up logs
BCKPATH="/tmp"                          # Default locatie voor de back-up bestanden
LOGRETENTION=7                          # Default aantal dagen dat de logs bewaard worden
RMANCATALOG=                            # Default Net Service Name van de Rman catalog
RCATUSER=                               # Default Rman catalog owner
RCATPWD=                                # Password Rman catalog owner  


# ------------------------------------------------------------------
# Processing command line parameters 
# ------------------------------------------------------------------

if [[ $# -eq 0 ]]; then
  echo "Argumenten verwacht bij aanroep van dit script. Zie script header voor informatie m.b.t. het gebruik van dit script."
  exit 1
fi

function is_valid_value {
  if [[ $1 =~ ^\- ]] || [[ -z $1 ]]; then return 1; else return 0; fi
}

while (( $# )); do
  CURRENT_ARG=$1
  NEXT_ARG=$2
  case $CURRENT_ARG in
    --all)
      # Alle gestarte databases back-uppen
      ALL_INSTANCES='true'
      shift 1 #skip current argument
      ;;
    -e)
      # Komma gescheiden lijst met Sids die niet geback-upt hoeven te worden. Gebruiken icm --all
      if  is_valid_value $NEXT_ARG; then
        EXCLUDELIST=$NEXT_ARG
        shift 2 # skip current argument and value
      else
        echo "Geen geldige waarde  gevonden voor argument $CURRENT_ARG!"
        exit 1
      fi
      ;;
    -d)
      # Komma gescheiden lijst met Sids die geback-upt dienen te worden.
      if  is_valid_value $NEXT_ARG; then
        INSTANCELIST=$NEXT_ARG
        shift 2 
      else
        echo "Geen geldige waarde gevonden voor argument $CURRENT_ARG!"
        exit 1
      fi
      ;;
    --online)
      # Online back-up
	  ONLINE='true'
      shift 1 
      ;;
    --offline)
      # Offline back-up
      OFFLINE='true'
      shift 1
      ;;
    --archivelog)
      # Archivelog back-up
      ARCHIVELOG='true'
      shift 1 
      ;;
    --incremental)
      # Incemental back-up
      INCREMENTAL='true'
      shift 1 
      ;;
    -l)
      # Level van de incremental back-up
      if  is_valid_value $NEXT_ARG; then
        INCLEVEL=$((NEXT_ARG))
        shift 2 
      else
        echo "Geen geldige waarde gevonden voor argument $CURRENT_ARG!"
        exit 1
      fi
      ;;
    --clusterdb)
      # Betreft RAC database(s)
      CLUSTERDB='true'
      shift 1
      ;;
    --catalog)
      # Gebruik een recovery catalog om de back-up informatie naar te syncroniseren
      USECATALOG='true'
      shift 1
      ;;
    --configfile)
      # Pad naar te gebruiken configuratie bestand.
        USE_CONFIG='true'
        shift 1 
      ;;
    *)
      # Onbekende parameters
      echo "Argument $CURRENT_ARG is onbekend!"
      exit 1
      ;;

   esac
done

# ------------------------------------------------------------------
# Functions
# ------------------------------------------------------------------

function clean_up {
  # Perform program exit housekeeping. Optionally accepts an exit status
  unset SIDLIST
  unset EXCLUDE 
  exit $1
# End clean_up
}

function validate_input {
  # Complexe validatie van de input gegeven via argumenten bij de script aanroep
  # Controleer of het opgegeven configuratiebestand ook bestaat
  if [[ $USE_CONFIG ]]; then
    # Controleer of configuratie bestand aanwezig is
    if [[ -e $CONFIGFILE ]]; then
      # Configuratie parameters inlezen
      echo "Back-ups uitgevoerd op basis van settings in $CONFIGFILE"
      RMANCATALOG=$(cat $CONFIGFILE | grep RMANCATALOG | awk -F'=' '{print $2}' | sed s'/[\n\s ]//g') # tr -d '\n' | tr -d ' ')
      RCATUSER=$(cat $CONFIGFILE | grep RCATUSER | awk -F'=' '{print $2}' | sed s'/[\n\s ]//g') # tr -d '\n' | tr -d ' ')
      RCATPWD=$(cat $CONFIGFILE | grep RCATPWD | awk -F'=' '{print $2}' | sed s'/[\n\s ]//g') # tr -d '\n' | tr -d ' ')
      BCKSCRIPTDIR=$(cat $CONFIGFILE | grep BCKSCRIPTDIR | awk -F'=' '{print $2}' | sed s'/[\n\s ]//g') # tr -d '\n' | tr -d ' ')
      BCKLOGDIR=$(cat $CONFIGFILE | grep BCKLOGDIR | awk -F'=' '{print $2}' | sed s'/[\n\s ]//g') # tr -d '\n' | tr -d ' ')
      BCKPATH=$(cat $CONFIGFILE | grep BCKPATH | awk -F'=' '{print $2}' | sed s'/[\n\s ]//g') # tr -d '\n' | tr -d ' ')
      LOGRETENTION=$(cat $CONFIGFILE | grep LOGRETENTION | awk -F'=' '{print $2}' | sed s'/[\n\s ]//g') # tr -d '\n' | tr -d ' ')
    else
      echo "Configuratiebestand $CONFIGFILE niet gevonden!"
      exit 1
    fi
  else
    echo "Back-ups uitgevoerd op basis van default setting in back-up script"
  fi

  # Controleer of niet zowel een INSTANCELIST als --all is opgegeven
  if [[ "$ALL_INSTANCES" ]] && [[ "$INSTANCELIST" ]]; then 
    echo "Een combinatie van zowel -d als --all wordt niet ondersteund."
    exit 1
  fi
  # Controleer of zowel een INSTANCELIST als --all ontbreken
  if [[ -z "$ALL_INSTANCES" ]] && [[ -z "$INSTANCELIST" ]]; then
    echo "Zowel de -d als --all parameter ontbreken."
    exit 1
  fi
  # Controleer of de -exclude is opgegeven zonder --all
  if  [[ "$EXCLUDELIST" ]] && [[ -z "$ALL_INSTANCES" ]]; then
    echo "De -exclude optie is gebruikt zonder --all."
    exit 1
  fi
  # Controleer of er geen combinatie van online/offline/incremental/archivelog is opgegeven
  if [[ $ONLINE ]]; then
    if [[ $OFFLINE ]] || [[ $INCREMENTAL ]] || [[ $ARCHIVELOG ]]; then
      echo "Een combinatie van --online, --offline, --incremental en --archivelog wordt niet ondersteund."
      exit 1
    fi
  elif [[ $OFFLINE ]]; then
    if [[ $ONLINE ]] || [[ $INCREMENTAL ]] || [[ $ARCHIVELOG ]]; then
      echo "Een combinatie van --online, --offline, --incremental en --archivelog wordt niet ondersteund."
      exit 1
    fi
  elif [[ $INCREMENTAL ]]; then 
    if [[ $OFFLINE ]] || [[ $ONLINE ]] || [[ $ARCHIVELOG ]]; then
      echo "Een combinatie van --online, --offline, --incremental en --archivelog wordt niet ondersteund."
      exit 1
    fi
  elif [[ $ARCHIVELOG ]]; then
    if [[ $OFFLINE ]] || [[ $INCREMENTAL ]] || [[ $ONLINE ]]; then
      echo "Een combinatie van --online, --offline, --incremental en --archivelog wordt niet ondersteund."
      exit 1
    fi
  fi
  # Controleer of een correct incremental level is opgegeven.
  if [[ $INCREMENTAL ]]; then
    if [[ ! $INCLEVEL ]]; then
      echo "Bij gebruik van --incremental moet ook een level (-l) opgegeven worden."
      exit 1
    else
      if (( $INCLEVEL > 1 )); then
        echo "De waarde van -l moet 0 of 1 zijn."
      fi
    fi
  fi
  # Zet het default back-up type indien niet opgegeven
  if [[ ! $ONLINE ]] && [[ ! $OFFLINE ]] && [[ ! $INCREMENTAL ]] && [[ ! $ARCHIVELOG ]]; then
    ONLINE='true'
  fi
  # Configureren juiste back-up scripts en logfile naam
  if [[ $ONLINE ]]; then
    BACKUPSCRIPT=$ONLINESCRIPT
    LOGFILEBASENAME=$ONLINELOGFILEBASENAME
  elif [[ $OFFLINE ]]; then
    BACKUPSCRIPT=$OFFLINESCRIPT
    LOGFILEBASENAME=$OFFLINELOGFILEBASENAME
  elif [[ $ARCHIVELOG ]]; then
    BACKUPSCRIPT=$ARCHIVELOGSCRIPT
    LOGFILEBASENAME=$ARCHIVELOGFILEBASENAME
  elif [[ $INCREMENTAL ]]; then
    BACKUPSCRIPT=$INCREMENTALSCRIPT
    LOGFILEBASENAME=$INCREMENTALLOGFILEBASENAME
  fi
  # Controleer of catalog, username en password voor de recovery catalog zijn geconfigureerd als --catalog is opgegeven
  if [[ $USECATALOG ]]; then
    if [[ ! $RMANCATALOG ]] || [[ ! $RCATUSER ]] || [[ ! $RCATPWD ]]; then
      echo "Een of meerdere van de parameters RMANCATALOG, RCATUSER en RCATPWD zijn niet geconfigureerd in het script."
      exit 1
    fi
  fi 
# End validate_input
}


function delete_backuplog {
  # Verwijderen van back-up logfiles die buiten de retentieperiode vallen
  DB=$1
  find $BCKLOGDIR -name "*${DB}*" -mtime +${LOGRETENTION} -type f -delete
# End delete_backuplog
}

function start_backup {
  # Starten van de Rman back-up voor een database
  DBNAME=$1
  if [[ $OFFLINE ]]; then
    # De database dient vanuit het rman (rcv) script in mount fase gebracht te worden en daarna ook weer geopend.
    # Een offline back-up van een RAC database wordt niet ondersteund
    echo "Offline back-up database $DBNAME gestart. Zie logfile ${BCKLOGDIR}/${LOGFILEBASENAME}_${DBNAME}_${EXECDATE}.log"
    rman target / cmdfile=$BCKSCRIPTDIR/$BACKUPSCRIPT log=${BCKLOGDIR}/${LOGFILEBASENAME}_${DBNAME}_${EXECDATE}.log  1>/dev/null
  elif [[ $ONLINE ]]; then
    echo "Online back-up database $DBNAME gestart. Zie logfile ${BCKLOGDIR}/${LOGFILEBASENAME}_${DBNAME}_${EXECDATE}.log"
    rman target / cmdfile=$BCKSCRIPTDIR/$BACKUPSCRIPT log=${BCKLOGDIR}/${LOGFILEBASENAME}_${DBNAME}_${EXECDATE}.log  1>/dev/null
  elif [[ $ARCHIVELOG ]]; then
    echo "Archivelog back-up database $DBNAME gestart. Zie logfile ${BCKLOGDIR}/${LOGFILEBASENAME}_${DBNAME}_${EXECDATE}.log"
  rman target / cmdfile=$BCKSCRIPTDIR/$BACKUPSCRIPT using \"$BCKPATH\" log=${BCKLOGDIR}/${LOGFILEBASENAME}_${DBNAME}_${EXECDATE}.log  1>/dev/null
  elif [[ $INCREMENTAL ]]; then
    echo "Incremental level $INCLEVEL back-up database $DBNAME gestart. Zie logfile ${BCKLOGDIR}/${LOGFILEBASENAME}_L${INCLEVEL}_${DBNAME}_${EXECDATE}.log"
    rman target / cmdfile=$BCKSCRIPTDIR/$BACKUPSCRIPT using \"$INCLEVEL\" log=${BCKLOGDIR}/${LOGFILEBASENAME}_L${INCLEVEL}_${DBNAME}_${EXECDATE}.log 1>/dev/null
  fi
  # Synchronisatie naar catalog
  if [[ $USECATALOG ]]; then
    echo "Synchronisatie van de back-up gegevens naar de Rman catalog in $RMANCATALOG"
    rman target / catalog $RCATUSER/$RCATPWD@$RMANCATALOG 1>/dev/null <<EOF
      RESYNC CATALOG;
      EXIT;
EOF
  
  fi
   
# End start_backup
}

function get_dbname {
  # Database naam uit Sid halen
  DBSID=$1
  if [[ $CLUSTERDB ]]; then
    # Betreft een cluster instance dus laatste karakter verwijderen
    DBNAME="${DBSID%?}"
  else
    # Geen cluster instance, dus Dbname=Sid
    DBNAME=$DBSID
  fi
}

function in_array {
  # Controleer of de betreffende SID ($2) voorkomt in de opgegeven lijst ($1)
  local ARRAY=${1}[@]
  local SEEKING=${2}
  for ELEMENT in ${!ARRAY}; do
    if [[ ${SEEKING} =~ ^[+]*${ELEMENT}.* ]]; then
      # Sid gevonden in de lijst
      return 0
    fi
  done
  return 1
}

trap clean_up 1 SIGHUP SIGINT SIGTERM

# ------------------------------------------------------------------
# Main procedure
# ------------------------------------------------------------------
validate_input

# Vullen array met uitsluitingen
declare -a EXCLUDE
# Standaard uitgesloten instances ($DEFEXCLUDELIST) opnemen
for DBSID in $(echo $DEFEXCLUDELIST | sed "s/,/ /g"); do
  EXCLUDE=("${EXCLUDE[@]}" "$DBSID")
done
# Eventuele extra opgegeven uitsluitingen toevoegen
if [[ $EXCLUDELIST ]]; then
  for DBSID in $(echo $EXCLUDELIST | sed "s/,/ /g"); do
    EXCLUDE=("${EXCLUDE[@]}" "$DBSID")
  done
fi

# Vullen array met te controleren instances
declare -a SIDLIST
if [[ $ALL_INSTANCES ]]; then
  # Vraag de SID op van alle gestart instances
  for DBSID in $(ps -ef|grep -v grep|grep _pmon_|awk '{printf(substr($8,10)"\n")}'); do
    #De default uitgesloten instances en eventueel extra uitgesloten instances worden uit de lijst gehaald.
    if in_array EXCLUDE $DBSID ; then
      # Deze SID moet niet gecontroleerd worden
      echo "$DBSID is uitgesloten van de back-up."
    else
      SIDLIST=("${SIDLIST[@]}" "$DBSID")
    fi
  done
else
  # Zet de opgegeven instance lijst om in een sid lijst
  for DBSID in $(echo $INSTANCELIST | sed "s/,/ /g"); do
     SIDLIST=("${SIDLIST[@]}" "$DBSID")
  done
fi

# Script stoppen als de Sid lijst leeg is
if [[ ${#SIDLIST[@]} -eq 0 ]]; then
  echo 'Geen instances gestart op deze server of opgegeven lijst is leeg!'
  exit 0
fi

# Backup starten
for SID in "${SIDLIST[@]}"; do
  export ORACLE_SID=$SID
  . oraenv 1>/dev/null 2>&1
  get_dbname $SID
  delete_backuplog $DBNAME
  start_backup $DBNAME
done

# Clean up
clean_up 0

#End <script name>


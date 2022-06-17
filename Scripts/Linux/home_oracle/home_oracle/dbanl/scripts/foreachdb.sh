#!/bin/bash
# ---------------------------------------------------------------------------------------------------
# File name:		foreachdb.sh
# Version:    	        2018.080.1			
# Purpose:		Statement of script uitvoeren in 1 of meerdere databases			
# Parameters:           --all			: Actie uitvoeren in alle gestarte instances
#		        -e			: Komma gescheiden lijst met instances die uitgesloten worden.
#					  	  Gebruiken i.c.m. --all
#			-d			: Komma gescheiden lijst met instances waarin de actie uitgevoerd dient te worden.
#						  Gebruiken i.p.v. --all
#			-s			: Voer het opgegeven script uit. Volledig pad naar het script tussen ''
#			-c			: Voer opgegeven SQL statement uit. Statement tussen '' en inclusief ';'
#			-u			: User waarmee aangelogd wordt op de database
#			-p			: Wachtwoord van de user waarmee aangelogd wordt op de database
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
SCRIPTDIR=$( cd "$(dirname "$0")" && pwd )
DEFEXCLUDELIST='+ASM,-MGMTDB,+APX'			    # Instances die standaard worden uitgesloten. 
 
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
    -s)
      # Uit te voeren script
      if  is_valid_value $NEXT_ARG; then
        SCRIPT=$NEXT_ARG
        shift 2
      else
        echo "Geen geldige waarde gevonden voor argument $CURRENT_ARG!"
        exit 1
      fi
      ;;
    -c)
      # Uit te voeren sql statement
      if  is_valid_value $NEXT_ARG; then
        SQL=$NEXT_ARG
        shift 2
      else
        echo "Geen geldige waarde gevonden voor argument $CURRENT_ARG!"
        exit 1
      fi
      ;;
    -u)
      # User waarmee aangelogd wordt op de database
      if  is_valid_value $NEXT_ARG; then
        USER=$NEXT_ARG
        shift 2
      else
        echo "Geen geldige waarde gevonden voor argument $CURRENT_ARG!"
        exit 1
      fi
      ;;
    -p)
      # Wachtwoord van de user waarmee aangelogd wordt op de database
      if  is_valid_value $NEXT_ARG; then
        PASSWD=$NEXT_ARG
        shift 2
      else
        echo "Geen geldige waarde gevonden voor argument $CURRENT_ARG!"
        exit 1
      fi
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
  if  [[ -z "$SCRIPT" ]] && [[ -z "$SQL" ]]; then
    echo "Er is geen statement (-c) of script (-s) opgegeven."
    exit 1
  fi
  if  [[ "$SCRIPT" ]] && [[ "$SQL" ]]; then
    echo "Zowel een statement (-c) als een script (-s) opgegeven."
    exit 1
  fi
  if  [[ -z "$USER" ]] || [[ -z "$PASSWD" ]]; then
    echo "Er is geen username (-u) en/of wachtwoord (-p) opgegeven."
    exit 1
  fi
# End validate_input
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
if [[ "$EXCLUDELIST" ]]; then
  for DBSID in $(echo $EXCLUDELIST | sed "s/,/ /g"); do
    EXCLUDE=("${EXCLUDE[@]}" "$DBSID")
  done
fi

# Vullen array met te controleren instances
declare -a SIDLIST
if [[ "$ALL_INSTANCES" ]]; then
  # Vraag de SID op van alle gestart instances
  for DBSID in $(ps -ef|grep -v grep|grep _pmon_|awk '{printf(substr($8,10)"\n")}'); do
    #De default uitgesloten instances en eventueel extra uitgesloten instances worden uit de lijst gehaald.
    if in_array EXCLUDE $DBSID ; then
      # Deze SID komt voor in de uitsluitingslijst 
      echo "$DBSID is uitgesloten."
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

# Uitvoeren gevraagde acties:
for SID in "${SIDLIST[@]}"; do
  export ORACLE_SID=$SID
  . oraenv 1>/dev/null 2>&1
  echo "** $SID **:"
  if [[ "$SQL" ]]; then
    sqlplus -S $USER/$PASSWD <<EOF
      $SQL
EOF
  elif [[ "$SCRIPT" ]]; then
    sqlplus -S $USER/$PASSWD @$SCRIPT
  fi
done

# Clean up
clean_up 0

#End <script name>


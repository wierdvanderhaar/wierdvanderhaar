#! /bin/ksh
#
# Script    : Check_DB_IPC.sh
# 
# Omschrijving
# ------------
# Dit script controleert het actuele IPC gebruik van de draaiende
# databanken met de maximaal in de kernel geconfigureerde resources.
#
# Mutatie-historie
# ----------------

# -------------------------------------------------------------
# Naam           : Help_Aanroep
# Parameters     : programmanaam
# 
# Omschrijving
# ------------
# Toon hoe dit programma aangeroepen moet worden
# -------------------------------------------------------------

Help_Aanroep()
{
   (
      echo Aanroep: ${0} [optie] [database]...
      echo
      echo Mogelijke opties
      echo ----------------
      echo -m   Toon alleen shared memory gegevens
      echo -s   Toon alleen semaphore gegevens
      echo -t   Toon alleen de totalen 
   ) >&2
}

# -------------------------------------------------------------
# Naam           : InitVars
# Parameters     : -
# 
# Omschrijving
# ------------
# Initialiseer de variabelen.
# -------------------------------------------------------------

InitVars() {
   Pm=0
   Ps=0
   Pt=0

   AWK_PROG=`which nawk 2>/dev/null`
   if [ -z "${AWK_PROG}" ]; then
      AWK_PROG=`which awk 2>/dev/null`
   fi
}

# ------------------------------------------------------------
# Naam       : ParseParams
# Parameters : -
#
# Omschrijving
# ------------
# Parse de opgegeven parameters.
# ------------------------------------------------------------

ParseParams() {
   while getopts hmst name 2>/dev/null
   do
      case ${name} in
      h)        Help_Aanroep
                exit 0
                ;;
      m)	Pm=1
                ;;
      s)	Ps=1
                ;;
      t)	Pt=1
                ;;
      ?)   echo Ongeldige optie >&2
           Help_Aanroep
           exit 2;;
      esac
   done

   shift $((${OPTIND} -1))

   DB_LIST=${*}

   if [ ${Pm} -eq 0 -a ${Ps} -eq 0 -a ${Pt} -eq 0 ]; then
      Pm=1
      Ps=1
      if [ -z ''${DB_LIST} ]; then
         Pt=1
      fi
   fi
   if [ ${Pt} -ne 0 -a ! -z ''${DB_LIST} ]; then
      echo Optie t is ongeldig in combinatie met individuele databanken >&2
      exit 2
   fi
}

# -------------------------------------------------------------
# Naam           : Bepaal_Kernel_Instellingen
# Parameters     : -
# 
# Omschrijving
# ------------
# Bepaal de geconfigureerde kernel instellingen voor semaphores
# -------------------------------------------------------------

Bepaal_Kernel_Instellingen() {
   OS=`uname -s`
   if [ "${OS}" = "Linux" ]; then
      OS_SEMMSL=`cat /proc/sys/kernel/sem | awk '{print $1}'`
      OS_SEMMNS=`cat /proc/sys/kernel/sem | awk '{print $2}'`
      OS_SEMOPM=`cat /proc/sys/kernel/sem | awk '{print $3}'`
      OS_SEMMNI=`cat /proc/sys/kernel/sem | awk '{print $4}'`
   else
      OS_SEMMNI=`sysdef | grep SEMMNI | cut -f 1`
      OS_SEMMSL=`sysdef | grep SEMMSL | cut -f 1`
      OS_SEMMNS=`sysdef | grep SEMMNS | cut -f 1`
   fi
}

# -------------------------------------------------------------
# Naam           : Bepaal_Actueel_Gebruik
# Parameters     : -
# 
# Omschrijving
# ------------
# Bepaal de daadwerkelijke gebruikte semaphores en shared memory.
# -------------------------------------------------------------

Bepaal_Actueel_Gebruik() {
   OS=`uname -s`
   USED_SEMMSL=0
   USED_SEMMNS=0
   if [ "${OS}" = "Linux" ]; then
      USED_SEMMNI=`ipcs -s | grep '^0x' | wc -l`
      for nsem in `ipcs -s | grep '^0x' | awk '{print $5}'`
      do
         if [ ${nsem} -gt ${USED_SEMMSL} ]; then
            USED_SEMMSL=${nsem}
         fi
         USED_SEMMNS=`expr ${USED_SEMMNS} + ${nsem}`
      done
   else
      USED_SEMMNI=`ipcs -s | grep '^s' | wc -l`
      for nsem in `ipcs -sb | grep '^s' | cut -c57-`
      do
         if [ ${nsem} -gt ${USED_SEMMSL} ]; then
            USED_SEMMSL=${nsem}
         fi
         USED_SEMMNS=`expr ${USED_SEMMNS} + ${nsem}`
      done
   fi
}

# -------------------------------------------------------------
# Naam           : Toon_Cumulatief_Instellingen
# Parameters     : -
# 
# Omschrijving
# ------------
# Toon de gedefinieerde kernel settings voor shared memory en
# semaphores.
# -------------------------------------------------------------

Toon_Cumulatief_Instellingen() {
   if [ ${Pm} -ne 0 -o ${Ps} -ne 0 ]; then
      echo
   fi

   (
      echo SEMMNI,"Maximaal aantal semaphore sets",${OS_SEMMNI},${USED_SEMMNI}
      echo SEMMSL,"Maximaal aantal identifiers in een set",${OS_SEMMSL},${USED_SEMMSL} 
      echo SEMMNS,"Maximaal aantal semaphores systeembreed",${OS_SEMMNS},${USED_SEMMNS}
   ) | ${AWK_PROG} '
BEGIN { FS="," 
        printf("%-10s %-40s %6s %6s\n","Parameter","Betekenis","Huidig","Used")
        printf("---------- ---------------------------------------- ------ ------\n")
      } 
{ printf("%-10s %-40s %6d %6d\n",$1,$2,$3,$4) }
'
}

# -------------------------------------------------------------
# Naam           : Lees_IPC_Waarden_Shm
# Parameters     : -
# 
# Omschrijving
# ------------
# Bepaal de IPC waarden met betrekking tot shared memory voor 
# de user oracle.
# -------------------------------------------------------------

LijstShm() {
   OS=`uname -s`
   if [ "${OS}" = "Linux" ]; then
      ipcs -m |
         sed 's/ [ ]*/,/g' |
         grep '^0x'
   else
      ipcs -m -b |
         sed 's/ [ ]*/,/g' |
         grep '^m,'
   fi | sed 's/ [ ]*/,/g'
}

Lees_IPC_Waarden_Shm() {
   OS=`uname -s`
   for IPC_DATA in `LijstShm`
   do
      if [ "${OS}" = "Linux" ]; then
         ID=`echo ${IPC_DATA} | cut -d, -f 2`
         KEY=`echo ${IPC_DATA} | cut -d, -f 1`
         RIGHTS=`echo ${IPC_DATA} | cut -d, -f 4`
         OWNER=`echo ${IPC_DATA} | cut -d, -f 3`
         SEGSZ=`echo ${IPC_DATA} | cut -d, -f 5`
         GROUP=""
      else
         ID=`echo ${IPC_DATA} | cut -d, -f 2`
         KEY=`echo ${IPC_DATA} | cut -d, -f 3`
         RIGHTS=`echo ${IPC_DATA} | cut -d, -f 4`
         OWNER=`echo ${IPC_DATA} | cut -d, -f 5`
         GROUP=`echo ${IPC_DATA} | cut -d, -f 6`
         SEGSZ=`echo ${IPC_DATA} | cut -d, -f 7`
      fi
      SEGSZ_KB=`expr ${SEGSZ} / 1024`
      TOTAL=`expr ${TOTAL} + ${SEGSZ_KB}`
   
      if [ ${OWNER} != 'oracle' ]; then
         continue
      fi

      DB=`Toon_DB_IPC.sh -noheader -shmid ${ID} | cut -d' ' -f 1`
      ToonVlag=N
      if [ -z ''${DB_LIST} ]; then
         ToonVlag=J
      else
         for DBi in ${DB_LIST}; do
            if [ ${DBi} == ${DB} ]; then
               ToonVlag=J
            fi
         done
      fi
      if [ ${ToonVlag} == 'J' ]; then
         echo $ID,$KEY,$RIGHTS,$OWNER,$GROUP,${DB},${SEGSZ_KB}
      fi
   done | sort -t, +5 -6
}

# -------------------------------------------------------------
# Naam           : Toon_IPC_Waarden_Shm
# Parameters     : -
# 
# Omschrijving
# ------------
# Toon de IPC waarden met betrekking tot shared memory voor 
# de user oracle.
# -------------------------------------------------------------

Toon_IPC_Waarden_Shm() {
   ${AWK_PROG} '
   BEGIN	{ FS="," 
             printf("%10s %15s %-11s %-8s %-8s %-8s %9s\n","Shm ID","Shm Key","Rights","Owner","Group","Instance","SEGSZ_KB")
	   }
	   { 
             printf("%10s %15s %-11s %-8s %-8s %-8s %9s\n",$1,$2,$3,$4,$5,$6,$7)
	   }
   '
}

# -------------------------------------------------------------
# Naam           : Lees_IPC_Waarden_Sem
# Parameters     : -
# 
# Omschrijving
# ------------
# Bepaal de IPC waarden met betrekking tot semaphores voor de 
# user oracle.
# -------------------------------------------------------------

LijstSem() {
   OS=`uname -s`
   if [ "${OS}" = "Linux" ]; then
      ipcs -s  |
         sed 's/ [ ]*/,/g' |
         grep '^0x'
   else
      ipcs -s -b |
         sed 's/ [ ]*/,/g' |
         grep '^s,'
   fi | sed 's/ [ ]*/,/g'
}

Lees_IPC_Waarden_Sem() {
   OS=`uname -s`
   for IPC_DATA in `LijstSem`
   do
      if [ "${OS}" = "Linux" ]; then
         ID=`echo ${IPC_DATA} | cut -d, -f 2`
         KEY=`echo ${IPC_DATA} | cut -d, -f 1`
         RIGHTS=`echo ${IPC_DATA} | cut -d, -f 4`
         OWNER=`echo ${IPC_DATA} | cut -d, -f 3`
         GROUP=""
         NSEMS=`echo ${IPC_DATA} | cut -d, -f 5`
      else
         ID=`echo ${IPC_DATA} | cut -d, -f 2`
         KEY=`echo ${IPC_DATA} | cut -d, -f 3`
         RIGHTS=`echo ${IPC_DATA} | cut -d, -f 4`
         OWNER=`echo ${IPC_DATA} | cut -d, -f 5`
         GROUP=`echo ${IPC_DATA} | cut -d, -f 6`
         NSEMS=`echo ${IPC_DATA} | cut -d, -f 7`
      fi
   
      if [ ${OWNER} != 'oracle' ]; then
         continue
      fi

      DB=`Toon_DB_IPC.sh -noheader -semid ${ID} | cut -d' ' -f 1`
      ToonVlag=N
      if [ -z ''${DB_LIST} ]; then
         ToonVlag=J
      else
         for DBi in ${DB_LIST}; do
            if [ ${DBi} == ${DB} ]; then
               ToonVlag=J
            fi
         done
      fi
      if [ ${ToonVlag} == 'J' ]; then
         echo $ID,$KEY,$RIGHTS,$OWNER,$GROUP,${DB},${NSEMS}
      fi
   done | sort -t, +5 -6
}

# -------------------------------------------------------------
# Naam           : Toon_IPC_Waarden_Sem
# Parameters     : -
# 
# Omschrijving
# ------------
# Toon de IPC waarden met betrekking tot semaphores voor de 
# user oracle.
# -------------------------------------------------------------

Toon_IPC_Waarden_Sem() {
   if [ ${Pm} -ne 0 ]; then
      echo
   fi
${AWK_PROG} '
BEGIN	{ FS="," 
          printf("%10s %15s %-11s %-8s %-8s %-8s %8s\n","Sem ID","Sem Key","Rights","Owner","Group","Instance","# Sem")
	}
	{ 
          printf("%10s %15s %-11s %-8s %-8s %-8s %8s\n",$1,$2,$3,$4,$5,$6,$7)
	}
'
}

# -------------------------------------------------------------
#      H O O F D P R O G R A M M A
# -------------------------------------------------------------

InitVars
ParseParams ${*}
TOTAL=0

if [ ${Pm} == 1 ]; then
   Lees_IPC_Waarden_Shm |
   Toon_IPC_Waarden_Shm 
fi 

if [ ${Ps} == 1 ]; then
   Lees_IPC_Waarden_Sem |
   Toon_IPC_Waarden_Sem 
fi

if [ ${Pt} == 1 ]; then
   Bepaal_Kernel_Instellingen
   Bepaal_Actueel_Gebruik
   Toon_Cumulatief_Instellingen
fi

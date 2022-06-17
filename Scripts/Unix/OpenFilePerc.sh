#! /bin/bash
#
# Naam           : OpenFilePecc.sh
# Parameters     : Geen
#
# Omschrijving
# ------------
# Bepaal het percentage van het maximaal aantal open files dat in gebruik is.
#

#if [ `id --real --user` -ne 0 ]; then
#    echo ${0}': Script moet als root gestart worden' >&2
#    exit 1
#fi

FILE_MAX=`/sbin/sysctl -a 2>/dev/null | grep 'fs.file-max' | cut -d'=' -f 2`

TOTAL_OPENFILES=0
for DATA in `ls -l /proc/[0-9]*/fd/* 2>/dev/null | cut -c47- | cut -d'/' -f 3  | sort | uniq -c | sort -n -r | sed 's/^[ ] *//g' | tr ' ' ',' `; do
   OPENFILES=`echo $DATA | cut -d',' -f 1 `
   TOTAL_OPENFILES=`expr ${TOTAL_OPENFILES} + ${OPENFILES}`
done 

# USED_PERC=`expr \( ${TOTAL_OPENFILES} \* 100 \) / ${FILE_MAX} `
USED_PERC=`expr \( \( ${TOTAL_OPENFILES} \* 100 \) / \( ${FILE_MAX} / 10 \) + 5 \) \/ 10`

echo 'em_result='${USED_PERC}

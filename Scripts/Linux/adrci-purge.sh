#!/bin/bash
. ~/.bash_profile
export PURGETIME=$1
let PURGEMIN="${PURGETIME}*60*24"
echo $PURGETIME
echo $PURGEMIN


# Purge ADR contents (adr_purge.sh)
echo "INFO: adrci purge started at `date`"
adrci exec="show homes"|grep -v : | while read file_line
do
echo "INFO: adrci purging diagnostic destination " $file_line
echo "INFO: purging ALERT older than $PURGETIME days"
adrci exec="set homepath $file_line;purge -age ${PURGEMIN} -type ALERT"
echo "INFO: purging INCIDENT older than $PURGETIME days"
adrci exec="set homepath $file_line;purge -age ${PURGEMIN} -type INCIDENT"
echo "INFO: purging TRACE older than $PURGETIME days"
adrci exec="set homepath $file_line;purge -age ${PURGEMIN} -type TRACE"
echo "INFO: purging CDUMP older than $PURGETIME days"
adrci exec="set homepath $file_line;purge -age ${PURGEMIN} -type CDUMP"
echo "INFO: purging HM older than $PURGETIME days"
adrci exec="set homepath $file_line;purge -age ${PURGEMIN} -type HM"
echo ""
echo ""
done
echo
echo "INFO: adrci purge finished at `date`"

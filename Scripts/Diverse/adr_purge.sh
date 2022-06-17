# set -x
/home/oracle/scripts/maintenance/rotate_listener.sh LISTENER 7
# Purge ADR contents (adr_purge.sh)
echo "INFO: adrci purge started at `date`"
adrci exec="show homes"|grep -v : | while read file_line
do
echo "INFO: adrci purging diagnostic destination " $file_line
echo "INFO: purging ALERT older than 30 days"
adrci exec="set homepath $file_line;purge -age 43200 -type ALERT"
echo "INFO: purging INCIDENT older than 30 days"
adrci exec="set homepath $file_line;purge -age 43200 -type INCIDENT"
echo "INFO: purging TRACE older than 30 days"
adrci exec="set homepath $file_line;purge -age 43200 -type TRACE"
echo "INFO: purging CDUMP older than 30 days"
adrci exec="set homepath $file_line;purge -age 43200 -type CDUMP"
echo "INFO: purging HM older than 30 days"
adrci exec="set homepath $file_line;purge -age 43200 -type HM"
echo ""
echo ""
done
echo
echo "INFO: adrci purge finished at `date`"

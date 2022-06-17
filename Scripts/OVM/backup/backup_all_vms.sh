#! /bin/bash
. ~/.bash_profile
#########################################################################
#					        			
# Bestand:	backup_all_vms.sh                       			
# Doel:		backup alle VM's als template
# Auteur:	Wierd van der Haar | DBA.nl				
# Historie:	2016-09-20	v1.0. Creatie en test.  
# 									
#########################################################################
# set -x
export SCRIPTDIR=/root/backup
export LOGDIR=${SCRIPTDIR}/logging
export BACKUPDIR=/vmbackup
export DATE=`date +%Y%m%d`
export DBALIST="m.lip@gorinchem.nl,s.klop@gorinchem.nl,m.v.hattem@gorinchem.nl"
export SMTPSERVER=exch13srvr.ggorinchem.nl

# Cleanup old backup and old logfiles. 
# find ${BACKUPDIR}/*.tgz -mtime +31 -exec rm -f {} \;
# find ${LOGDIR}/*.log -mtime +31 -exec rm -f {} \;

# Cleanup old VM listing
rm -f ${LOGDIR}/vms/*

# List alle actieve VM's op deze OVS Server.
${SCRIPTDIR}/listvms.sh
for file in /root/backup/logging/vms/*
do
# do something on "$file"
echo $file
filename=$file
IFS=$'\n'
old_IFS=$IFS
IFS=$'\n'
lines=($(cat $file)) # array
export vmname=${lines[0]}
echo $vmname
export vmuuid=${lines[1]}
echo $vmuuid
export vmconfig=${lines[2]}
echo $vmconfig
IFS=$old_IFS
###########################
# Stop VM in kwestie
###########################
echo "`date`" 									> ${LOGDIR}/${DATE}_${vmname}.log
echo "$vmname wordt NU Gestopt!!!!"						>> ${LOGDIR}/${DATE}_${vmname}.log
xm shutdown ${vmuuid} -w								>> ${LOGDIR}/${DATE}_${vmname}.log
##########################################################
# Check of de NFS share beschikbaar is. Zo niet mount deze.			>> ${LOGDIR}/${DATE}_${vmname}.log
##########################################################
if [ $(mount | grep -c ${BACKUPDIR}) != 1 ]
then
        /bin/mount ${BACKUPDIR} || exit 1
        echo "${BACKUPDIR} is now mounted"					>> ${LOGDIR}/${DATE}_${vmname}.log
else
        echo "${BACKUPDIR} already mounted"					>> ${LOGDIR}/${DATE}_${vmname}.log
fi
###########################
# Start backup van de VM											
###########################
echo "Start backup van ${vmname} | `date`" 					>> ${LOGDIR}/${DATE}_${vmname}.log
${SCRIPTDIR}/backup-vm-as-template.sh ${vmuuid} ${BACKUPDIR}			>> ${LOGDIR}/${DATE}_${vmname}.log
echo "Einde backup van ${vmname} | `date`" 					>> ${LOGDIR}/${DATE}_${vmname}.log
###########################
# Start VM in kwestie
###########################
echo "Start VM ${vmname} | `date`" 						>> ${LOGDIR}/${DATE}_${vmname}.log
xm create ${vmconfig}
##########################
# Add VM Info for future reference
#########################
echo "           "								>> ${LOGDIR}/${DATE}_${vmname}.log
echo "Full info on $vmname"							>> ${LOGDIR}/${DATE}_${vmname}.log
echo "===================================================================="	>> ${LOGDIR}/${DATE}_${vmname}.log
xm list -l $vmuuid								>> ${LOGDIR}/${DATE}_${vmname}.log
echo "===================================================================="	>> ${LOGDIR}/${DATE}_${vmname}.log

###########################
# Remove formating Logfile for easy mailing 
###########################
cat ${LOGDIR}/${DATE}_${vmname}.log | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" > ${LOGDIR}/${DATE}_${vmname}_noformat.log
mv -f ${LOGDIR}/${DATE}_${vmname}_noformat.log ${LOGDIR}/${DATE}_${vmname}.log
##########################
# MAIL Logfile 
##########################
mailx -S smtp=${SMTPSERVER} -s "Logfile Full Backup ${vmname} gemaakt op ${DATE}" -v $DBALIST > /dev/null < ${LOGDIR}/${DATE}_${vmname}.log
done

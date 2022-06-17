#!/bin/bash
. ~/.bash_profile
#########################################################################
#
# Bestand:      backup_one_vm.sh
# Doel:         backup de opgegeven VM als template
# Auteur:       Wierd van der Haar | DBA.nl
# Historie:     2017-08-15      v1.0. Creatie en test.
#
#########################################################################
# set -x
export SCRIPTDIR=/root/backup
export LOGDIR=${SCRIPTDIR}/logging
export BACKUPDIR=/vmbackup
export DATE=`date +%Y%m%d`
export DBALIST="m.lip@gorinchem.nl,s.klop@gorinchem.nl,m.v.hattem@gorinchem.nl"
export SMTPSERVER=exch13srvr.ggorinchem.nl

# Roep het script aan met de naam van de VM.
export VMNAME=$1

echo "De backup van de VM ${VMNAME} wordt nu gestart!"

# Cleanup old backup and old logfiles.
# find ${BACKUPDIR}/*.tgz -mtime +31 -exec rm -f {} \;
# find ${LOGDIR}/*.log -mtime +31 -exec rm -f {} \;

# Cleanup old VM listing
rm -f ${LOGDIR}/vms/${VMNAME}.lst

# Restart OVS-AGENT
service ovs-agent restart

# List alle actieve VM's op deze OVS Server.
# ${SCRIPTDIR}/listvms.sh
LALL=
while getopts ":a" opt; do
   [[ $opt = a ]] && LALL=YES
done

if [[ $LALL ]]; then
   vmids=$(ls -d /OVS/Repositories/*/VirtualMachines/* |xargs -n1 basename)
else
   vmids=$(/usr/sbin/xm list |grep ^[0-9] |awk '{print $1}')
fi

for v in $vmids; do
export vmname=${VMNAME,,}
export simp=`grep simp /OVS/Repositories/*/VirtualMachines/$v/vm.cfg |cut -c19- |sed "s/'//g"`
export simp=${simp,,}
export vmuuid=$v
export vmconfig=`ls /OVS/Repositories/*/VirtualMachines/$v/vm.cfg`
#
if [ ${simp} = ${vmname} ]; then
        # echo "De naam is gelijk"
        echo $simp
        echo $vmuuid
        echo $vmconfig
        ###########################
        # Stop VM in kwestie
        ###########################
        echo "`date`"                                                                   > ${LOGDIR}/${DATE}_${vmname}.log
        echo "$vmname wordt NU Gestopt!!!!"                                             >> ${LOGDIR}/${DATE}_${vmname}.log
        /usr/sbin/xm shutdown ${vmuuid} -w                                                              >> ${LOGDIR}/${DATE}_${vmname}.log
        #/usr/sbin/xm destroy ${vmuuid}                                                         >> ${LOGDIR}/${DATE}_${vmname}.log
        ##########################################################
        # Check of de NFS share beschikbaar is. Zo niet mount deze.                     >> ${LOGDIR}/${DATE}_${vmname}.log
        ##########################################################
        if [ $(mount | grep -c ${BACKUPDIR}) != 1 ]
        then
                /bin/mount ${BACKUPDIR} || exit 1
                echo "${BACKUPDIR} is now mounted"                                      >> ${LOGDIR}/${DATE}_${vmname}.log
        else
                echo "${BACKUPDIR} already mounted"                                     >> ${LOGDIR}/${DATE}_${vmname}.log
        fi
        ###########################
        # Start backup van de VM
        ###########################
        echo "Start backup van ${vmname} | `date`"                                      >> ${LOGDIR}/${DATE}_${vmname}.log
        ${SCRIPTDIR}/backup-vm-as-template.sh ${vmuuid} ${BACKUPDIR}                    >> ${LOGDIR}/${DATE}_${vmname}.log
        echo "Einde backup van ${vmname} | `date`"                                      >> ${LOGDIR}/${DATE}_${vmname}.log
        ###########################
        # Start VM in kwestie
        ###########################
        echo "Start VM ${vmname} | `date`"                                              >> ${LOGDIR}/${DATE}_${vmname}.log
        /usr/sbin/xm create ${vmconfig}
        ##########################
        # Add VM Info for future reference
        #########################
        echo "           "                                                              >> ${LOGDIR}/${DATE}_${vmname}.log
        echo "Full info on $vmname"                                                     >> ${LOGDIR}/${DATE}_${vmname}.log
        echo "===================================================================="     >> ${LOGDIR}/${DATE}_${vmname}.log
        /usr/sbin/xm list -l $vmuuid                                                            >> ${LOGDIR}/${DATE}_${vmname}.log
        echo "===================================================================="     >> ${LOGDIR}/${DATE}_${vmname}.log
        ###########################
        # Remove formating Logfile for easy mailing
        ###########################
        cat ${LOGDIR}/${DATE}_${vmname}.log | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" > ${LOGDIR}/${DATE}_${vmname}_noformat.log
        mv -f ${LOGDIR}/${DATE}_${vmname}_noformat.log ${LOGDIR}/${DATE}_${vmname}.log
        ##########################
        # MAIL Logfile
        ##########################
        mailx -S smtp=${SMTPSERVER} -s "Logfile Full Backup ${vmname} gemaakt op ${DATE}" -v $DBALIST > /dev/null < ${LOGDIR}/${DATE}_${vmname}.log
# else
#       #echo "De opgegeven vmname => ${vmname} bestaat niet of is niet actief op deze OVM Server."
#       continue
fi
done
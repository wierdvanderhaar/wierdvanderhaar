#! /bin/bash
# set -x
# Script moet twee zaken checken.
# 1. Is het mount-point er. Zo niet mounten.
# 2. Zo ja kan er ook een ls worden uitgevoerd. Zo niet remounten.

export DATE=$(date +"%d%b%y %R")
export fs=$1
if [ -z "${fs}" ]
then
     echo "Er is geen filesysteem opgegeven.... exiting"
     exit
fi


if [ $(mount | grep -c ${fs}) = 0 ]
then
                echo "$DATE - ${fs} was niet gemount -> remounting....." >> /root/remount_fs.log
                /bin/mount ${fs} || exit 1
                echo "$DATE - ${fs} is nu weer gemount................." >> /root/remount_fs.log
else
                ls ${fs} >/dev/null
                status=$?
                if [ $status != 0 ]; then
                echo "$DATE - Problemen met ${fs} - remounting....." >> /root/remount_fs.log
                /bin/umount ${fs} || exit 1
                /bin/mount ${fs} || exit 1
                echo "$DATE - ${fs} is weer gemount................"  >> /root/remount_fs.log
                else
                echo "$fs is gemount en kan worden beschreven."
                fi
fi

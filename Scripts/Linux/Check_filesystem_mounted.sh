#! /bin/bash
if [ $(mount | grep -c /u01/app/oracle/backup) != 1 ]
then
        /bin/mount /u01/app/oracle/backup || exit 1
        echo "/u01/app/oracle/backup is now mounted"
else
        echo "/u01/app/oracle/backup already mounted"
fi

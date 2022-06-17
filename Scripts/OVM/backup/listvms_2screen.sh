#!/bin/bash
#set -x
export LOGDIR=/root/backup/logging/vms

# Remove old logging
rm -f ${LOGDIR}/*

LALL=
while getopts ":a" opt; do
   [[ $opt = a ]] && LALL=YES
done

if [[ $LALL ]]; then
   vmids=$(ls -d /OVS/Repositories/*/VirtualMachines/* |xargs -n1 basename)
else
   vmids=$(xm list |grep ^[0-9] |awk '{print $1}')
fi

for v in $vmids; do
   grep simp /OVS/Repositories/*/VirtualMachines/$v/vm.cfg |cut -c19- |sed "s/'//g"
   echo $v										
   ls /OVS/Repositories/*/VirtualMachines/$v/vm.cfg
done
exit 0

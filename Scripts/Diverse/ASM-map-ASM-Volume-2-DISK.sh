#!/bin/ksh
for i in `/etc/init.d/oracleasm listdisks`
do
v_asmdisk=`/etc/init.d/oracleasm querydisk $i | awk  '{print $2}'`
v_minor=`/etc/init.d/oracleasm querydisk -d $i | awk -F[ '{print $2}'| awk -F] '{print $1}' | awk '{print $1}'`
v_major=`/etc/init.d/oracleasm querydisk -d $i | awk -F[ '{print $2}'| awk -F] '{print $1}' | awk '{print $2}'`
v_device=`ls -la /dev | grep $v_minor | grep $v_major | awk '{print $10}'`
echo "ASM disk $v_asmdisk based on /dev/$v_device  [$v_minor $v_major]"
done

## In /proc/partitions staan ook alle devices. 



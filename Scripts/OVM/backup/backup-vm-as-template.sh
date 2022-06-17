#!/bin/bash
#
# Script name: mktemplate
# Description:
#
#   Creates an importable VM template from an existing VM's UUID. The template
#   name is taken from the existing VM's simple name to make it easier to
#   identify. These templates are compatible with both Oracle VM 2.x and 3.x.
#
# Usage: mktemplate <the vm UUID> [Directory to keep the template]
#
# returns: 0 - operation succeeded
#          1 - usages error
#          2 - VM does not exist
#          3 - directory unavailable
#          4 - VM still running
#          9 - script terminated
#
# Version: 1.1
# Author: BINGLIU
# Relevant Oracle KM notes: 
#
# Copyright (c) 2010, 2016, Oracle and/or its affiliates. All rights reserved.
# 


# usage: print_msg <msg type> "string"
#  type: msg, inf, err
print_msg()
{
    if [ "$1" == "msg" ]
    then
        echo -e "\e[1m\e[92m${2}\e[0m"
    elif [ "$1" == "inf" ]
    then
        echo -e "\e[1m\e[93m${2}\e[0m"
    elif [ "$1" == "err" ]
    then
        echo -e "\e[1m\e[31m${2}\e[0m" 1>&2 
    fi 
}

print_mark()
{
    print_msg msg "x-----------------------------------------------------------------x"
}

if [ $# -ne 1 -a $# -ne 2 ]
then
    print_msg err "Usage: $(basename "$0") <VM's UUID> [Directory to keep the template]"
    exit 1
elif [ $# -eq 2 ]
then
    if [ ! -d "$2" ]
    then
        print_msg err  "\"$2\" does not exist or is not a directory."
        exit 3
    fi
fi



VMID=$1
VMCFG=`ls /OVS/Repositories/*/VirtualMachines/${VMID}/vm.cfg 2> /dev/null`

if [ $? -ne 0 ]
then
    print_msg err "Virtual Machine \"${VMID}\" does not exist."
    exit 2
fi

VMNAME=$(grep OVM_simple_name "${VMCFG}" | cut -d\' -f2)

if (! ovs-agent-dlm --lock --uuid ${VMID} 2> /dev/null) 
then
    print_msg err "VM \"${VMID}\" is still running."
    print_msg inf "** If the VM is not runing, try \"ovs-agent-dlm --unlock --uuid ${VMID}\" first."
    exit 4
fi
    

clean_tmp()
{
    echo 
    print_msg err "Program terminated! Cleaning..."
    print_msg msg "*** Delete temporary files:"
    print_mark
    if [ "x${WORKDIR}" != "x" ]
    then
        print_msg inf "${WORKDIR}"
        cd ; rm -rf "${WORKDIR}"
    fi

    if [ "x${TMPVMCFG}" != "x" ]
    then
        print_msg inf "${TMPVMCFG}"
        rm -f "${TMPVMCFG}"
    fi
    print_mark

    
    if [ -f "${VM_TEMPLATE}" ]
    then
        print_msg msg "*** Delete incomplete template:"
        print_mark
        print_msg inf "${VM_TEMPLATE}"
        rm -f "${VM_TEMPLATE}"
        print_mark
    fi
    
    print_msg msg "*** Release VM lock..."
    ovs-agent-dlm --unlock --uuid "${VMID}"

    exit 9
}
    

trap clean_tmp SIGHUP SIGINT SIGILL SIGTERM SIGQUIT

TMPVMCFG="$(mktemp -t .vm.cfg_XXXXXXXXXX)"
cp -f "${VMCFG}" "${TMPVMCFG}"


search_pdisk()
{

    if ( grep -i phy "${VMCFG}" > /dev/null 2>&1)
    then
        for pdisk in $(cat "${VMCFG}" | tr ',' '\n' | grep -o '/dev/mapper/.*')
        do
            PDISK_BASENAME="$(basename ${pdisk})"
            PDISK_BLOCK=$(cat /sys/block/$(multipath -ll ${PDISK_BASENAME} | grep "dm-" | cut -d' ' -f 2)/size)
            PDISK_PSEC=$(cat /sys/block/$(multipath -ll ${PDISK_BASENAME} | grep "dm-" | cut -d' ' -f 2)/queue/physical_block_size)
            # pdisk size KB
            PDISK_SIZE=$((${PDISK_BLOCK}*${PDISK_PSEC}*2/1024))
            echo "${PDISK_SIZE}:${pdisk}:${PDISK_BASENAME}.img"

            sed -i s"%phy:${pdisk}%file:/OVS/seed_pool/${VMNAME}/${PDISK_BASENAME}.img%g" "${TMPVMCFG}"
        done
    fi
}

search_vdisk()
{
    if ( grep -i "file:" "${VMCFG}" > /dev/null 2>&1)
    then
        # locate vdisks
        for vdisk in $(cat "${VMCFG}" | tr ',' '\n' | grep -o '/OVS/Repositories/.*img')
        do
            DISK_BASENAME="$(basename "${vdisk}")"
            # vdisk size KB
            VDISK_INFO=$(du -kl "${vdisk}" | awk '{print $1":"$2}')
            echo "${VDISK_INFO}:${DISK_BASENAME}"
            # update configure file
            sed -i "s%$(dirname ${vdisk})%/OVS/seed_pool/${VMNAME}/%g" "${TMPVMCFG}"
        done
    fi
}

pharse_disk()
{
    search_pdisk
    search_vdisk
}


# usage: list_all_disk requires golbal disk array
list_all_disk()
{
    i=0
    while [ "x${disk_list[$i]}" != "x" ]
    do
        echo "${disk_list[$i]}" | cut -d':' -f2
        i=$(($i+1))
    done
}

# search_avail_partition <size in KB>
search_avail_partition()
{
    for mount_point in $(df -P | awk '{print $4":"$6}'| grep -v Avail)
    do
        if [ $1 -lt $(echo "${mount_point}" | cut -d':' -f1) ]
        then
            echo "${mount_point}" | cut -d':' -f2
        fi
    done
}


select_avail_partition()
{
    print_mark
    echo

    print_msg inf "$(search_avail_partition ${total_size} | grep -n -e ".*")"
    avail_partition=($(search_avail_partition ${total_size}))

    echo
    print_mark
    echo


    echo -n "Choice: "
    read partition_count
    isnum=$(echo "${partition_count}" | awk -F"\n" '{print ($0 != $0+0)}')
    echo 
    while [ ${isnum} -eq 1 ] || [ ${partition_count} -lt 1 ] || [ "x${avail_partition[((${partition_count}-1))]}" == "x" ]
    do
         print_msg inf "invalid number!"
         echo -n "Try again: "
         read partition_count
         isnum=$(echo "${partition_count}" | awk -F"\n" '{print ($0 != $0+0)}')
    done

    PREWORKDIR="${avail_partition[((${partition_count}-1))]}"
}


# main
disk_list=($(pharse_disk))

# caculate required disk space
c=0
# size Unit KB
total_size=0
while [ "x${disk_list[$c]}" != "x" ]
do
    total_size=$(($(echo "${disk_list[$c]}" | cut -d':' -f1)+${total_size}))
    c=$(($c+1))
done


PREWORKDIR="$2"

if [ "x${PREWORKDIR}" == "x" ]
then
    echo 
    print_msg msg "** Available partitions for creating template:"
    echo
    select_avail_partition
fi

workdir_freespace=$(df -P "${PREWORKDIR}" | awk '{print $4}'| grep -v Avail | uniq)

if [ ${workdir_freespace} -lt ${total_size} ]
then
    echo
    print_msg inf "\"${PREWORKDIR}\" has insufficient disk space, please choice a directory:"
    echo 
    select_avail_partition
fi

print_msg msg  "** Generate template config file..."
WORKDIR="$(mktemp -d -p ${PREWORKDIR} -t .template_XXXXXXXXXX)"
if [ "x${WORKDIR}" == "x" ]
then
    print_msg err "Cannot make work directory: ${WORKDIR}."
    clean_tmp
fi

VM_TEMPLATE="$(mktemp -p "${PREWORKDIR}" -t "${VMNAME}_XXXXXXXXXX.tgz")"

cd "${WORKDIR}"

mkdir -p "${VMNAME}"
cp -f "${TMPVMCFG}" "${VMNAME}/vm.cfg"
sed -i -e "s/OVM_simple_name/name/g" \
       -e "/.*${VMID}/d" \
          "${VMNAME}/vm.cfg"


print_msg msg "** Link virtual disks and copy physical disks..."
i=0
while [ "x${disk_list[$i]}" != "x" ]
do
    
        source_disk="$(echo ${disk_list[$i]} | awk -F: '{print $2}')"
        target_disk="$(echo ${disk_list[$i]} | awk -F: '{print $3}')"

    if (echo "${disk_list[$i]}" | grep "/dev/mapper" > /dev/null 2>&1)
    then
        cp --sparse=always "${source_disk}" "${VMNAME}/${target_disk}"
        if [ $? != 0 ]
        then
            print_msg err "pdisk copy operation is terminated. Exiting.."
	    clean_tmp
	fi
    else
        ln -s "${source_disk}" "${VMNAME}/${target_disk}"
    fi
    i=$(($i+1))
done

print_msg msg "** Archive template..."

tar zchSf "${VM_TEMPLATE}" "${VMNAME}"
if [ $? != 0 ]
then
    print_msg err "Archive operation terminated. Exiting.."
    clean_tmp
fi

echo -e  "\e[1m\e[97m** \"${VM_TEMPLATE}\" created **\e[0m"

print_msg msg "** unlock VM..."
ovs-agent-dlm --unlock --uuid "${VMID}"

print_msg msg "** Force delete following temporary files:"

print_mark
print_msg inf "${WORKDIR}"
print_msg inf "${TMPVMCFG}"
print_mark

trap - SIGHUP SIGINT SIGILL SIGTERM SIGQUIT
print_msg msg "press Ctrl+C to cancel!"

count=5
while [ ${count} -gt 0 ]
do 
    if [ ${count} -eq 1 ]
    then
        echo ${count}.
    else
        echo -n "${count}..."
    fi
    count=$((${count} - 1 ))
    sleep 1
done

rm -rf "${WORKDIR}"
rm -f "${TMPVMCFG}"


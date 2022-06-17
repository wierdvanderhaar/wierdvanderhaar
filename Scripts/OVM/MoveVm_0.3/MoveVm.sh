#!/bin/bash
# Rel. 0.3 - MoveVm.sh
# S. Coter - simon.coter@oracle.com
# https://blogs.oracle.com/scoter
# Target of this script is to move a VM, its vdisks and its config file to a different repository.
# Reqs:
# 1) ovmcli enabled on Oracle VM Manager on port 10000 
# 2) Vm status: stopped
# Tested on Oracle VM 3.3.1 Build 1065 or newer
# Fixes from v0.1:
# 1) fixed check on OVMCLI release
# Fixes from v0.2:
# 1) fixed issue related to custom-names on vdisks (thanks to PGOMOLA and JDOSTALE)

if [ $# -lt 5 ]
 then
	clear
	echo ""
	echo "#####################################################################################"
	echo " You have to specify <guest id> or <guest name>:"
	echo " Use MoveVm.sh <Oracle VM Manager password> <Oracle VM Manager host> <guest name> <Oracle VM Server Pool> <target Repository> [shutdown the vm] [start the vm] "
	echo " Optional Parameters:"
	echo " 		[shutdown the vm] [Y/N] = vm running will be stopped before the moving."
	echo " 		[start the vm] [Y/N] = vm, once moved, will be started."
	echo " Example:"
        echo "           MoveVm.sh Welcome1 ovm-mgr.oracle.local vmdb01 myPool repotarget Y Y"
        echo "           MoveVm.sh Welcome1 ovm-mgr.oracle.local vmdb01 myPool repotarget y N"
        echo "           MoveVm.sh Welcome1 ovm-mgr.oracle.local vmdb01 myPool repotarget n N"
        echo "           MoveVm.sh Welcome1 ovm-mgr.oracle.local vmdb01 myPool repotarget N y"
	echo "##########################################################################################"
	echo ""
	exit -1
fi
today=`date +'%Y%m%d-%H%M'`
password=$1
mgrhost=$2
guest=$3
pool=$4
repotarget=$5
force=`echo $6 | tr [a-z] [A-Z]`
restart=`echo $7 | tr [a-z] [A-Z]`

# Default copy-type is SPARSE
# If you want you can modify to "NON_SPARSE_COPY"
#copytype=NON_SPARSE_COPY
copytype=SPARSE_COPY
#copytype=THIN_CLONE

# Execute first-connection in case of reboot of Oracle VM Manager or client-host, specifying admin password
/usr/bin/expect FirstConn.exp $password $mgrhost

# Check VM Name is unique
isunique=`ssh admin@$mgrhost -p 10000 list vm |grep -cx $guest`
if [ $isunique -gt 1 ]; then
        echo "==> Found more than one Vm object with name $guest!"
	echo "==> Please work on unique names to have this script working!"
        exit 1
fi

# Get generic info on vm
vmdetails=`ssh admin@$mgrhost -p 10000 show vm name=$guest`

# Get generic info on vm disks (virtual = all - physical - cd/iso)
vmdisks=`ssh admin@$mgrhost -p 10000 list VirtualDisk`

# CHECK VM NAME
checkguest=`echo "$vmdetails" |grep -ci "Locked = false"`
if [ $checkguest -lt 1 ]; then
        echo "==> Unable to identify Virtual Machine $guest specified!"
        exit 1
fi

# CHECK POOL NAME AND VM MEMBERSHIP
checkpool=`ssh admin@$mgrhost -p 10000 show ServerPool name=$pool |grep -c $guest`
if [ $checkpool -lt 1 ]; then
        echo "==> Unable to identify Server Pool $pool specified or Vm is not part of this pool"
        exit 1
fi

# CHECK REPOTARGET NAME
checkrepotarget=`ssh admin@$mgrhost -p 10000 show repository name=$repotarget|grep -ci "Locked = false"`
if [ $checkrepotarget -lt 1 ]; then
        echo "==> Unable to identify Target Repository $repotarget specified!"
        exit 1
fi

# CHECK SERVER THAT GUEST VM
checkovs=`echo "$vmdetails" |grep "Server =" |cut -d "[" -f2 |cut -d "]" -f1`
checkrepopresented=`ssh admin@$mgrhost -p 10000 show repository name=$repotarget |grep "Presented Server" |grep -c $checkovs`
if [ $checkrepopresented -lt 1 ]; then
        echo "==> Unable to move VM $guest to repository $repotarget!"
        echo "==> Repository $repotarget is not presented to server $checkovs !"
        exit 1
fi

# CHECK OVMCli RELEASE (FEATURES AVAILABLE)
ovmclirel=`ssh admin@$mgrhost -p 10000 showversion |grep '[0-9].[0-9]' |cut -d "." -f1,2 |sed 's|[^0-9]*||'`
case $ovmclirel in
        3.2)    echo "==> Oracle VM 3.2 release is not supported by this script."
                exit 1;;
        3.3)    echo "==> Oracle VM 3.3 CLI";;
        3.4)    echo "==> Oracle VM 3.4 CLI";;
esac

# CHECK VM AND ALL ITS COMPONENTS ARE NOT ALREADY ON TARGET REPOSITORY
checkactrepotemp=`echo "$vmdetails" |grep VmDiskMapping |cut -d "[" -f2 |cut -d "]" -f1| sed -e 's/Mapping for disk Id (//'| sed -e 's/)//'`
checkactrepo="";
for checkactrepotempi in $checkactrepotemp; do
 if test -n "`echo ${vmdisks} | grep ${checkactrepotempi}`"; then
  echo "==> Will migrate/clone vm disk $checkactrepotempi as it is in VirtualDisk list!"
  checkactrepo="${checkactrepo}`echo ${checkactrepotempi}`"
 else
  echo "==> Skipping vm disk $checkactrepotempi as it is not in VirtualDisk list!"
 fi
done
checkactvmcfg=`echo "$vmdetails" |grep "Repository =" |grep -c $repotarget`
countvdisks=`echo "$checkactrepo"i |wc -l`
isalready=0
for diskid in `echo "$checkactrepo"`; do
        reponame=`ssh admin@$mgrhost -p 10000 show virtualdisk id=$diskid |grep "Repository Id =" |cut -d "[" -f2 |cut -d "]" -f1`
        if [ "$reponame" = "$repotarget" ]; then
                isalready=$(($isalready+1))
        fi
done

if [ $isalready -eq $countvdisks ] && [ $checkactvmcfg -eq 1 ]; then
        echo "==> VM $guest configuration file (vm.cfg) and all its vdisks are already on repository $repotarget"
	echo "==> Physical disks and Virtual Cd-Rom won't be touched"
        echo "==> No further operations will be executed"
        exit 1
fi

# Get sum of disk-space used by vdisks owned by the guest and verify free space on target repository
diskdetails=`echo "$vmdetails" |grep VmDiskMapping`
vdisksidtemp=`echo "$diskdetails" |cut -d "[" -f2 |cut -d "]" -f1| sed -e 's/Mapping for disk Id (//'| sed -e 's/)//'`
for vdisksidi in $vdisksidtemp; do
 if test -n "`echo ${vmdisks} | grep ${vdisksidi}`"; then
  vdisksid="${vdisksid} `echo ${vdisksidi}`"
 fi
done
sum_space_used=0
for diskid in `echo "$vdisksid"`; do
        tmp=`ssh admin@$mgrhost -p 10000 show virtualdisk id=$diskid |grep "Used (GiB) =" |cut -d "=" -f2 |awk '{print int($1+0.9)}'`
        sum_space_used=$(($sum_space_used + $tmp))
done

# refresh target-repo to verify free space
ssh admin@$mgrhost -p 10000 refresh repository name=$repotarget
filesystemid=`ssh admin@$mgrhost -p 10000 show repository name=$repotarget |grep "File System =" |cut -d "=" -f2 |cut -d " " -f2`
ssh admin@$mgrhost -p 10000 refresh filesystem id=$filesystemid
space_free_on_repo=`ssh admin@$mgrhost -p 10000 show repository name=$repotarget |grep "File System Free (GiB) =" |cut -d "=" -f2 |awk '{print int($1)}'`
if [ $space_free_on_repo -lt $sum_space_used ]; then
        echo "==> Unable to move VM $guest to repository $repotarget!"
        echo "==> There is not enough free space on repository $repotarget."
        echo "==> VM $guest needs, at least, $sum_space_used GB while on repository $repotarget free space is $space_free_on_repo GB."
        exit 1
fi

# Get sum of disk-space used by vdisks owned by the guest and verify free space on target repository
diskdetails=`echo "$vmdetails" |grep VmDiskMapping`
vdisksidtemp=`echo "$diskdetails" |cut -d "[" -f2 |cut -d "]" -f1| sed -e 's/Mapping for disk Id (//'| sed -e 's/)//'`
vdisksid="";
for vdisksidi in $vdisksidtemp; do
 if test -n "`echo ${vmdisks} | grep ${vdisksidi}`"; then
  vdisksid="${vdisksid} `echo ${vdisksidi}`"
 fi
done
sum_space_used=0
for diskid in `echo "$vdisksid"`; do
	tmp=`ssh admin@$mgrhost -p 10000 show virtualdisk id=$diskid |grep "Used (GiB) =" |cut -d "=" -f2 |awk '{print int($1+0.9)}'`
	sum_space_used=$(($sum_space_used + $tmp))
done

space_free_on_repo=`ssh admin@$mgrhost -p 10000 show repository name=$repotarget |grep "File System Free (GiB) =" |cut -d "=" -f2 |awk '{print int($1)}'`
if [ $space_free_on_repo -lt $sum_space_used ]; then
	echo "==> Unable to move VM $guest to repository $repotarget!"
	echo "==> There is not enough free space on repository $repotarget."
	echo "==> VM $guest needs, at least, $sum_space_used GB while on repository $repotarget there is only $space_free_on_repo GB free."
	exit 1
fi

# Check VM is running or not and shutdown if requested
running=`echo "$vmdetails" |grep -c "Status = Running"`
if [ $running -eq 1 ]; then
        if [ "$force" = "Y" ]; then
                ssh admin@$mgrhost -p 10000 stop vm name=$guest &
                # Wait until moveVmToRepository job completed
                each_cycle=5
                sleep $each_cycle
                job_id=`ssh admin@$mgrhost -p 10000 list job |grep -i "Stop Vm" |grep $guest |head -1 |cut -d ":" -f2|cut -d " " -f1`
                done=0
                i=$each_cycle
                while [ $done -lt 1 ]; do
                        echo "==> Waiting for Vm shutdown to complete......$i seconds"
                        let i=i+$each_cycle
                        sleep $each_cycle
                        done=`ssh admin@$mgrhost -p 10000 show job id=$job_id |grep -c "Summary Done = Yes"`
                done

                # Verify VM shutdown completed successfully
                ssh admin@$mgrhost -p 10000 show job id=$job_id > /tmp/$job_id-ovmm.out
                job_status=`cat /tmp/$job_id-ovmm.out |grep "Summary State" |cut -d "=" -f2`

                if [ "$job_status" = " Success" ]; then
                       echo "Virtual Machine $guest stopped successfully; here the details:"
                        cat /tmp/$job_id-ovmm.out
                        rm -f /tmp/$job_id-ovmm.out
                else
                        echo "Virtual Machine $guest error while stopping; here the details:"
                        cat /tmp/$job_id-ovmm.out
                        rm -f /tmp/$job_id-ovmm.out
                        exit 1
                fi
        else
                echo "==> Vm $guest is running and cannot be moved!"
                echo "==> Manually shutdown vm $guest and retry!"
                echo "==> If you want this script to stop the vm you can use the "Y" option!"
                exit 1
        fi
fi

# (1) Create a new temporary Clone Customizer for VM moving
ssh admin@$mgrhost -p 10000 create VmCloneCustomizer name=$guest-move-to-$repotarget-$today description=$guest-move-to-$repotarget-$today on Vm name=$guest

# (2) Prepare storage mappings for clone customizer created
DISK_IDS=`echo "$vmdetails" |grep VmDiskMapping |cut -d "[" -f2 |cut -d "]" -f1| sed -e 's/Mapping for disk Id (//'| sed -e 's/)//'`

for diskid in `echo "$DISK_IDS"`; do
	#isvirtual=`echo $diskid |grep -v ".iso" |grep -c ".img"`
	isvirtual=`echo "$vmdisks" | grep -c "$diskid"`
	diskmapping=`echo "$diskdetails"|grep $diskid|awk '{print $5}'`
	if [ $isvirtual -lt 1 ]; then
		# physical-disk or virtual-cdrom
		# DO NOTHING - Physical disk will continue to be the same - Virtual-CDROM will remain on the source-repo
		echo "==> DO NOTHING - Physical disk will continue to be the same - Virtual-CDROM will remain on the source-repo"
		# ssh admin@$mgrhost -p 10000 create VmCloneStorageMapping cloneType=SPARSE_COPY name=Storage_Mapping-$diskmapping vmDiskMapping=$diskmapping on VmCloneCustomizer name=$guest-move-to-$repotarget-$today
	else
		# virtual-disk
		reponame=`ssh admin@$mgrhost -p 10000 show virtualdisk id=$diskid |grep "Repository Id =" |cut -d "[" -f2 |cut -d "]" -f1`
        	if [ "$reponame" = "$repotarget" ]; then
                	echo "==> Virtual Disk $diskid is already on repository $repotarget"
        	else
		ssh admin@$mgrhost -p 10000 create VmCloneStorageMapping cloneType=$copytype name=Storage_Mapping-$diskmapping vmDiskMapping=$diskmapping repository=$repotarget on VmCloneCustomizer name=$guest-move-to-$repotarget-$today
		fi
	fi
done

# (3) Prepare network mappings for clone customizer created
NETWORK_IDS=`echo "$vmdetails" |grep "Vnic .* =" |cut -d "=" -f2 |cut -d "[" -f1 |sed -e 's/ //g'`
for vnicid in `echo "$NETWORK_IDS"`; do
	# get vnic-name(MAC) and vnic_network_id
	vnicdetails=`ssh admin@$mgrhost -p 10000 show vnic id=$vnicid`
	vnicname=`echo "$vnicdetails" |grep "Mac Address =" |cut -d "=" -f2 |sed -e 's/ //g'`
	vnicnetworkid=`echo "$vnicdetails" |grep "Network =" |cut -d "=" -f2 |cut -d "[" -f1 |sed -e 's/ //g'`
	# add to clone-customizer
	ssh admin@$mgrhost -p 10000 create VmCloneNetworkMapping name=NetworkMapping-$vnicid network=$vnicnetworkid vnic=$vnicid on VmCloneCustomizer name=$guest-move-to-$repotarget-$today
done

# (4) Move guest to target repository and delete Clone Customizer
ssh admin@$mgrhost -p 10000 moveVmToRepository Vm name=$guest CloneCustomizer=$guest-move-to-$repotarget-$today targetRepository=$repotarget &
each_cycle=10
sleep $each_cycle

# Wait until moveVmToRepository job completed

job_id=`ssh admin@$mgrhost -p 10000 list job |grep -i "Move Vm" |grep $guest |head -1 |cut -d ":" -f2|cut -d " " -f1`
done=0
i=$each_cycle
while [ $done -lt 1 ]; do
	echo "==> Waiting for Vm moving to complete......$i seconds"
	let i=i+$each_cycle
	sleep $each_cycle
	done=`ssh admin@$mgrhost -p 10000 show job id=$job_id |grep -c "Summary Done = Yes"`
done
	
# Verify VM moving completed successfully
ssh admin@$mgrhost -p 10000 show job id=$job_id > /tmp/$job_id-ovmm.out
job_status=`cat /tmp/$job_id-ovmm.out |grep "Summary State" |cut -d "=" -f2`

if [ "$job_status" = " Success" ]; then
        echo "==> Virtual Machine $guest moved successfully to repository $repotarget; here the details:"
	cat /tmp/$job_id-ovmm.out
	rm -f /tmp/$job_id-ovmm.out
else
	echo "==> Virtual Machine $guest moving job in error state; here the details:"
	cat /tmp/$job_id-ovmm.out
	rm -f /tmp/$job_id-ovmm.out
        exit 1
fi

ssh admin@$mgrhost -p 10000 delete VmCloneCustomizer name=$guest-move-to-$repotarget-$today

# (5) Start the moved vm and verify it's started
if [ "$restart" = "Y" ]; then
	ssh admin@$mgrhost -p 10000 start vm name=$guest
else
	echo "==> VM in stopped state, restart will have to be executed manually."
	exit 0
fi

each_cycle=1
sleep 5

# Wait until startVm job completed and report output

job_id=`ssh admin@$mgrhost -p 10000 list job |grep -i "start Vm" |grep $guest |head -1 |cut -d ":" -f2|cut -d " " -f1`
done=0
i=$each_cycle
while [ $done -lt 1 ]; do
        echo "==> Waiting for Vm starting to complete......$i seconds"
        let i=i+$each_cycle
        sleep $each_cycle
        done=`ssh admin@$mgrhost -p 10000 show job id=$job_id |grep -c "Summary Done = Yes"`
done

# Verify VM starting completed successfully
ssh admin@$mgrhost -p 10000 show job id=$job_id > /tmp/$job_id-ovmm.out
job_status=`cat /tmp/$job_id-ovmm.out |grep "Summary State" |cut -d "=" -f2`

if [ "$job_status" = " Success" ]; then
        echo "==> Virtual Machine $guest started successfully; here the details:"
        cat /tmp/$job_id-ovmm.out
        rm -f /tmp/$job_id-ovmm.out
else
        echo "==> Virtual Machine $guest starting job in error state; here the details:"
        cat /tmp/$job_id-ovmm.out
        rm -f /tmp/$job_id-ovmm.out
        exit 1
fi

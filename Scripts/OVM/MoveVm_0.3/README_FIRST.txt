=================
= COMPATIBILITY =
=================
Script compatible with:
	- Oracle VM 3.3
	- Oracle VM 3.4

================
= REQUIREMENTS =
================
1) expect installed on the Linux system executing the script
2) guest-vm able to reach port 10000 of Oracle VM Manager host

====================
= STEPS TO PROCEED =
====================

1) To setup self-authenticated connection to Oracle VM Manager (ssh-key exchange) execute script named "SetupSsh.sh"
	- the script is based on expect, so wait for a success message while installing it
1a) Syntax:

#####################################################################################
 You have to specify <guest id> or <guest name>:
 Use SetupSsh.sh <Oracle VM Manager host> <Linux oracle user password> <Oracle VM Manager Password>
 Example:
           SetupSsh.sh ovm-mgr.oracle.local oracle Welcome1
##########################################################################################

1b) Setup example:
[root@ovmm33 MoveVm_0.1]# ./SetupSsh.sh ovmm33.it.oracle.com oracle Welcome1
spawn ssh oracle@ovmm33.it.oracle.com
The authenticity of host 'ovmm33.it.oracle.com (10.169.233.26)' can't be established.
RSA key fingerprint is d3:7a:40:93:f6:ff:75:ca:50:ae:bb:3a:08:f3:cf:e7.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added 'ovmm33.it.oracle.com,10.169.233.26' (RSA) to the list of known hosts.
oracle@ovmm33.it.oracle.com's password:
Last login: Thu May 12 00:58:47 2016 from dhcp-ukc1-twvpn-1-vpnpool-10-175-179-25.vpn.oracle.com
[oracle@ovmm33 ~]$ umask 077
[oracle@ovmm33 ~]$ mkdir -p .ssh
[oracle@ovmm33 ~]$ spawn sleep 5
FKGFTn1ZJhm6Vy7WEajpo4swgPlBBodKXpEykW0UMNHr/8bBk2AFflq5Oml5vkwGlhBD365/pRKbl7YoQYYmkre0pMktxrFSOpIbZz8r8RPSGroM1XwiDVY8Wd8mKw2CK+dUt447UceEjs+jqTis0+hZN9mjB1klIpM3chsJ70PGDsaWqiSjwgLbqXN492fzy8bfwCZAK7nIzChkJHaR/tOEU/N3Q== root@ovmm33.it.oracle.com >> /home/oracle/.ssh/ovmcli_authorized_keys
[oracle@ovmm33 ~]$ spawn ssh -l admin ovmm33.it.oracle.com -p 10000
The authenticity of host '[ovmm33.it.oracle.com]:10000 ([10.169.233.26]:10000)' can't be established.
DSA key fingerprint is 60:86:c9:c4:25:c1:96:6e:3f:fc:a4:1e:2f:0b:5f:14.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '[ovmm33.it.oracle.com]:10000,[10.169.233.26]:10000' (DSA) to the list of known hosts.
admin@ovmm33.it.oracle.com's password:
## Starting Generated OVMCLI Script... ##


OVM> set OutputMode=Verbose
Command: set OutputMode=Verbose
Status: Success
Time: 2016-05-12 20:21:52,640 CEST
OVM> exit
Connection to ovmm33.it.oracle.com closed.
OVM> help
For Most Object Types:
    list <objectType>
    show <objectType> <instance>
    create <objectType> [(attribute1)="value1"] ... [on <objectType> <instance>]
    edit <objectType> <instance>  (attribute1)="value1" ...
    delete <objectType> <instance>
For Most Object Types with Children:
    add <objectType> <instance> to <objectType> <instance>
    remove <objectType> <instance> from <objectType> <instance>
Client Session Commands:
    set outputMode=[Verbose,XML,Sparse]
    set endLineChars=[CRLF,CR,LF]
    showobjtypes
    showallcustomcmds
    showcustomcmds <objectType>
    showversion
    exit
OVM> exit
OVMCLI Session successfully connected with key-based authentication!!!

2) enjoy MoveVm.sh script (further details available at https://blogs.oracle.com/scoter)

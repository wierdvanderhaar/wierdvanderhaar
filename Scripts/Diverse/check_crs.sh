#!/bin/bash
#
# Show the resource availability for Cluster instances
#
# Description:
# -  This script will validate the resource status in a cluster environments.
#
#
# Requirements:
#  - Make sure the Oracle Home is set to the CRS environment.
#
# Version:
#  - version 1.1
#  - Bernhard de Cock Buning
#     -> 1.1 Toevoegen van service status
#     -> 1.2 Toevoegen clusternaam + db en service config in een.
#  - www.rachelp.nl
#
#
# binloc=/u01/app/grid/11.2.0/gridinfra_1/bin

# set -x

initcrs ()
{
        # Initialization
        export ORA_CRS_HOME=/u01/app/grid/11.2.0/gridinfra_1
        export PATH=${ORA_CRS_HOME}/bin:$PATH
}

initdb ()
{
        # Initialization
        export ORACLE_HOME=/u01/app/oracle/product/10.2.0/db_1
        export PATH=${ORACLE_HOME}/bin:$PATH
}

clusternode ()
{
        initcrs
        echo "Cluster name:"
        ${ORA_CRS_HOME}/bin/cemutlo -n
        echo "Nodes in this Cluster:"
        ${ORA_CRS_HOME}/bin/olsnodes
        echo ""
}

clustercheck ()
{
        initcrs
        #Cluster status check
        echo "Cluster status local node `hostname`:"
        echo ""
        ${ORA_CRS_HOME}/bin/crsctl check crs
        echo ""
}


nodeapps ()
{
        initcrs
        # Node applications check
        # for i in `olsnodes`
        # do
        echo "Node application status:"
        ${ORA_CRS_HOME}/bin/srvctl status nodeapps
        echo ""
# done
}

asmstatus ()
{
        initcrs
        # ASM status check
        for i in `olsnodes`
        do
                echo "ASM instance status : $i"
                ${ORA_CRS_HOME}/bin/srvctl status asm -n ${i}
                echo ""
        done
}

databasestatus ()
{
        initdb
        # Database status check
        echo "Database status report:"
        for i in `${ORACLE_HOME}/bin/srvctl config`
        do
                echo "Database: $i"
                ${ORACLE_HOME}/bin/srvctl status database -d ${i}
                echo ""
        done
}

servicestatus ()
{
        initdb
        # Service status check
        echo "Service status report:"
        for i in `${ORACLE_HOME}/bin/srvctl config`
        do
                echo "Service for Database: $i"
                ${ORACLE_HOME}/bin/srvctl status service -d ${i}
                echo ""
        done
}

dbandservice ()
{
        initdb
        # Service status check
        echo "Database Instance and Service status report:"
        for i in `${ORACLE_HOME}/bin/srvctl config`
        do
                echo "Database and Service configuration: $i"
                ${ORACLE_HOME}/bin/srvctl status database -d ${i}
                echo ""
                echo "Service for Database: $i"
                ${ORACLE_HOME}/bin/srvctl config service -d ${i}
                ${ORACLE_HOME}/bin/srvctl status service -d ${i}
                echo ""
        done
}
usage ()
{
cat << ++EOM

Usage: ${0} -n -c -r -a -d -s -h

        -n      Nodes in this cluster
        -c      Local CRS process check
        -r      Nodes application resources status in the cluster
        -a      Asm instance status in the cluster
        -d      Database/instance status in the cluster
        -s      Services status in the cluster
        -x      combination of Database/instance and service status
        -h      This menu

The order should be (from scratch) -n, -c, -r, -a, -d, -s  and -h
If you don't define a flag, all the flags are used.

++EOM
}

if [ $# -eq 0 ]
then
        #Execute all status checks
        echo "Perform all the status checks"
        echo ""
        clusternode
        clustercheck
        nodeapps
        asmstatus
        databasestatus
        servicestatus
  exit 0
fi

set -- `getopt ncrdasxh $* 2> /dev/null`

if [ $? -ne 0 ]
then
  #
  # Usage message
  cat << ++EOM

Usage: ${0} -n -c -r -a -d -s -x -h

        -n      Nodes in this cluster
        -c      Local CRS process check
        -r      Nodes application resources status in the cluster
        -a      Asm instance status in the cluster
        -d      Database/instance status in the cluster
        -s      Services status in the cluster
        -x      combination of Database/instance and service status
        -h      This menu

The order should be (from scratch) -n, -c, -r, -a, -d, -s -x  and -h
If you don't define a flag, all the flags are used.
++EOM
exit 99
fi

while [ ${1} != "--" ]
do
   case ${1} in
     -n)        initcrs
                clusternode
                shift
        ;;
     -c)        initcrs
                clustercheck
                shift
        ;;
     -r)        initcrs
                nodeapps
                shift
        ;;
     -a)        initcrs
                asmstatus
                shift
        ;;
     -d)        initdb
                databasestatus
                shift
        ;;
     -s)        initdb
                servicestatus
                shift
        ;;
     -x)        initdb
                dbandservice
                shift
        ;;
     -h)        initdb
                usage
                shift
   esac
done

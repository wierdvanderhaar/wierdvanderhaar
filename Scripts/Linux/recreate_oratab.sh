#!/bin/bash

# Stel huidige oratab veilig.
export NU=`date +%Y%m%d`
cp /etc/oratab /etc/oratab.${NU}
echo "File recreated by script"                         > /etc/oratab
echo "+ASM:/u01/app/oracle/product/19.0.0/gridhome_1:N" >> /etc/oratab

# Set env op CRS_HOME
export ORACLE_SID=+ASM
export ORAENV_ASK=NO; . oraenv

# Onderstaande gepikt van Frits Hoogland. https://fritshoogland.wordpress.com/tag/recreate-oratab/
# Als je de DB_UNIQUE_NAME wilt gebruiken moet je GEN_USR_ORA_INST_NAME in db_name vervangen door DB_UNIQUE_NAME.

for resource in $(crsctl status resource -w "((TYPE = ora.database.type) AND (LAST_SERVER = $(hostname -s)))" | grep ^NAME | sed 's/.*=//'); do
    full_resource=$(crsctl status resource -w "((NAME = $resource) AND (LAST_SERVER = $(hostname -s)))" -f)
    db_name=$(echo "$full_resource" | grep ^GEN_USR_ORA_INST_NAME | awk -F= '{ print $2 }')
    ora_home=$(echo "$full_resource" | grep ^ORACLE_HOME= | awk -F= '{ print $2 }')
    printf "%s:%s:N\n" $db_name $ora_home >> /etc/oratab
done

cat /etc/oratab

== FOR STANDALONE GI

for resource in $(crsctl status resource -w "((TYPE = ora.database.type))" | grep ^NAME | sed 's/.*=//'); do
    full_resource=$(crsctl status resource -w "((NAME = $resource))" -f)
    db_name=$(echo "$full_resource" | grep ^GEN_USR_ORA_INST_NAME | awk -F= '{ print $2 }')
    ora_home=$(echo "$full_resource" | grep ^ORACLE_HOME= | awk -F= '{ print $2 }')
    printf "%s:%s:N\n" $db_name $ora_home
done
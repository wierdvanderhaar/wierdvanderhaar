#! /bin/bash
. ~/.bash_profile
#########################################################################
#                                                                       #
#               SET ENVIRONMENT                                         #
#                                                                       #
#########################################################################
# set -x
export PATH=/usr/local/bin:$ORACLE_HOME/bin:$PATH
export DATE=`date +%Y%m%d`

for dbhome in `cat /etc/oratab | grep -v ASM | sort |  egrep -v -e "^\*|^#|^$" | sort | cut -d \: -f2 | sort | uniq` ; do
# Check if sqlnet.ora is allready there. If so make a copy first then continue (re)creating again.
FILE=${dbhome}/network/admin/sqlnet.ora
if 	test -f "$FILE"; then
    echo "$FILE exists."
	echo "Making a copy of $FILE."
	cp ${FILE} ${FILE}.${DATE}
else
	echo "$FILE does not (yet) exists."
fi
# Create sqlnet.ora for the use of client-side enabled encryption 
echo "##########################################################  								> ${FILE}
echo "# File generated using enable_native_encryption.sh script.								>> ${FILE}
echo "# Server-side encryption is Requested. So encryption should be client-side enabled." 		>> ${FILE}
echo "##########################################################  								>> ${FILE}
echo "SQLNET.ENCRYPTION_SERVER=REQUESTED" 														>> ${FILE}
echo "SQLNET.ENCRYPTION_TYPES_SERVER=(AES256)"													>> ${FILE}
done




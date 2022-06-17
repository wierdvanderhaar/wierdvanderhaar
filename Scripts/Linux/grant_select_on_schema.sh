#! /bin/bash
. ~/.bash_profile
#########################################################################
#                                                                       #
#               SET ENVIRONMENT                                         #
# DBA.nl WH | 9-7-2020
# Roep scrip aan met Container en BronSchema naam.
# Zoals ./grant_select_to_ANOL.sh CPNBG NM_ODS_VIEW                     #
#########################################################################
# set -x
export PATH=/usr/local/bin:$ORACLE_HOME/bin:$PATH
export DATE=`date +%Y%m%d`
export SCRIPTDIR=/home/oracle/dbanl

export ORACLE_SID=$1
export BRONUSER=$2

ORAENV_ASK=NO ; . oraenv
$ORACLE_HOME/bin/sqlplus / as sysdba @${SCRIPTDIR}/pdb3.sql <<EOF
-- @${SCRIPTDIR}/pdb3.sql
-- exec GRANT_ANOL();
set serveroutput on
declare
cursor C1 is select 'grant select on '|| owner || '."' || segment_name || '" to ANOL ' as stat from dba_segments where segment_type in ('TABLE','VIEW') and owner='${BRONUSER}' and segment_name not like 'BIN\$%';
begin
for x in C1 loop
        dbms_output.put_line(x.stat);
        execute immediate x.stat;
END LOOP;
end;
/
EOF

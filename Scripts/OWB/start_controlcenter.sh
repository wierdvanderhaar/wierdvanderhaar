source ~/.profile
$ORACLE_HOME/bin/sqlplus /nolog <<EOF
connect owbsys/tommysys01
@/oracle/product/11.2.0/dbhome_2/owb/rtp/sql/start_service.sql
EOF

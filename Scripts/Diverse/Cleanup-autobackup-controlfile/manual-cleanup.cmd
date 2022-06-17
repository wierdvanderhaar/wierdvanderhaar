set DATESTAMP=%date:~6,8%-%date:~3,2%-%date:~0,2%
set SCRIPTDIR=D:\Oracle\rman_backupscripts
set LOGDIR=D:\Oracle\rman_backupscripts\logs\%DATESTAMP%
if not exist %LOGDIR% mkdir %LOGDIR%

set oracle_sid=jjprod1
set oracle_home=d:\oracle\product\12.2.0\dbhome_1
call d:\oracle\product\12.2.0\dbhome_1\bin\sqlplus / as sysdba @%SCRIPTDIR%\manual-cleanup.sql
call d:\oracle\product\12.2.0\dbhome_1\bin\rman target / @%SCRIPTDIR%\crosscheck_backup.rcv

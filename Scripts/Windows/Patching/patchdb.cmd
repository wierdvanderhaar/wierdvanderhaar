SET _tmp=%1
call net start %_tmp%
SET ORACLE_SID=%_tmp:OracleService=%
ECHO %ORACLE_SID%
call oraenv DB %ORACLE_SID%
call %ORACLE_HOME%\OPatch\datapatch -verbose -skip_upgrade_check
SET _tmp=%1
SET ORACLE_SID=%_tmp:OracleService=%
ECHO %ORACLE_SID%
call oraenv DB122 %ORACLE_SID%
call %ORACLE_HOME%\bin\sqlplus /nolog @D:\dbanl\scripts\checkup\get-database-memory.sql

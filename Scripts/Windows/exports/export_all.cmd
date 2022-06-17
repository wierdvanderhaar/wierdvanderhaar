@echo on
set SCRIPTDIR=E:\Scripts\exports
FOR /f %%F IN ('dir /b c:\oracle\admin') DO (
REM set ORACLE_SID=%%F
REM echo %ORACLE_SID%
call %SCRIPTDIR%\export.cmd %%F)


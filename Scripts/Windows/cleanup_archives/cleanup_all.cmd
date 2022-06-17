@echo on
set SCRIPTDIR=E:\Scripts\cleanup_archives
REM FOR /F %%F IN (dblist.txt) DO (goto :START)
FOR /f %%F IN ('dir /b d:\oraarch') DO (
REM set ORACLE_SID=%%F
REM echo %ORACLE_SID%
call %SCRIPTDIR%\cleanup.cmd %%F)


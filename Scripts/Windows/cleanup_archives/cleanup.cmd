set ORACLE_SID=%1
set ORACLE9=C:\oracle\ora92
set ORACLE10=C:\oracle\Ora1020
echo %ORACLE_SID%
IF (%ORACLE_SID%) == (stroomln) (goto :ORACLE9) ELSE (goto :ORACLE10)
:ORACLE9
set ORACLE_HOME=%ORACLE9%
call %ORACLE_HOME%\bin\rman nocatalog cmdfile=%SCRIPTDIR%\cleanup.rman log=%SCRIPTDIR%\logging\cleanup_%ORACLE_SID%.log
goto EOF
:ORACLE10
set ORACLE_HOME=%ORACLE10%
call %ORACLE_HOME%\bin\rman nocatalog cmdfile=%SCRIPTDIR%\cleanup.rman log=%SCRIPTDIR%\logging\cleanup_%ORACLE_SID%.log
goto EOF
:EOF

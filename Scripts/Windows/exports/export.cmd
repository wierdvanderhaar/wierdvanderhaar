set ORACLE_SID=%1
set ORACLE9=C:\oracle\ora92
set ORACLE10=C:\oracle\Ora1020
set USER=system
set PW=siptah
set BCKDIR=\\san\dumps\%ORACLE_SID%
echo %ORACLE_SID%

if not exist %BCKDIR% mkdir %BCKDIR%

IF (%ORACLE_SID%) == (stroomln) (goto :ORACLE9) ELSE (goto :ORACLE10)
:ORACLE9
set NLS_LANG=DUTCH_THE NETHERLANDS.WE8MSWIN1252
set ORACLE_HOME=%ORACLE9%
call %ORACLE_HOME%\bin\exp %USER%/%PW% file=%BCKDIR%\full_%ORACLE_SID%.dmp full=Y compress=Y consistent=Y statistics=NONE log=%BCKDIR%\full_%ORACLE_SID%.log
goto EOF
:ORACLE10
set NLS_LANG=DUTCH_THE NETHERLANDS.WE8MSWIN1252
set ORACLE_HOME=%ORACLE10%
call %ORACLE_HOME%\bin\exp %USER%/%PW% file=%BCKDIR%\full_%ORACLE_SID%.dmp full=Y compress=Y consistent=Y statistics=NONE log=%BCKDIR%\full_%ORACLE_SID%.log
goto EOF
:EOF

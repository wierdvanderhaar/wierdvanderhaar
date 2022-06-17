@echo off

rem  --------------------------------------------------------------------------------------------------
rem Bestandsnaam:  oraenv.bat	
rem Versie:        1
rem Doel:          Zetten Oracle omgevingsvariabelen. Plaats dit script bijv. in C:\Windows32		
rem Parameters:    1 Type Oracle Home
rem                2 Oracle SID
rem Gebruik:       oraenv.bat [OHTYPE] [ORACLE_SID]
rem
rem       [OH TYPE]:
rem           AGENT		: Oracle Home EM agent
rem           OMS		: Oracle Home OMS
rem           CRS		: Oracle Home Clusterware
rem           HTTP		: Oracle Home Apache Webserver
rem	      DB		: Oracle Home Database
rem           display 		: Display variables
rem           reset   		: Unset variables
rem           help    		: Display this message
rem       [ORACLE_SID]	        : Oracle database SID. Only in combination with OH_TYPE 'DB'
rem		
rem Auteur:			Gerben Lenderink
rem Historie:			09-09-09	G. Lenderink		1e versie
rem
rem ----------------------------------------------------------------------------------------------------

rem Script configuration
set DB1HOME=D:\app\oracle\product\12.2.0\dbhome_1
REM set DB2HOME=D:\app\oracle\product\11.2.0\db_2
REM set DB3HOME=D:\app\oracle\product\10.2.0\db_3
set AGENTHOME=D:\app\oracle\product\agent11g
set OMSHOME=
set HTTPHOME=
set CRSHOME=D:\app\grid\product\12.2.0\GIhome_1
if /I "%OLD_PATH%"=="" (set OLD_PATH=%PATH%)

rem Start setting parameters
set OHTYPE=%1%
set ORACLE_SID=%2%

if  /I "%OHTYPE%"=="AGENT" ( goto agent )
if  /I "%OHTYPE%"=="OMS" ( goto oms )
if  /I "%OHTYPE%"=="CRS" ( goto crs )
if  /I "%OHTYPE%"=="HTTP" ( goto http )
if  /I "%OHTYPE%"=="DB1" ( goto db1 )
if  /I "%OHTYPE%"=="DB2" ( goto db2 )
if  /I "%OHTYPE%"=="DB3" ( goto db3 )
if /I "%OHTYPE%"=="display" ( goto display )
if /I "%OHTYPE%"=="reset" ( goto reset )
if /I "%OHTYPE%"=="help" ( goto help )
if /I "%OHTYPE%"=="-?" ( goto help )
if /I "%OHTYPE%"=="" ( goto help )
goto error

rem
rem AGENT option
rem
:agent
echo.
set ORACLE_SID=AGENT
set ORACLE_HOME=%AGENTHOME%
set PATH=%ORACLE_HOME%\bin;%OLD_PATH%
goto display

rem
rem OMS option
rem
:oms
echo.
set ORACLE_SID=OMS
set ORACLE_HOME=%OMSHOME%
set PATH=%ORACLE_HOME%\bin;%OLD_PATH%
goto display

rem
rem CRS option
rem
:crs
echo.
set ORACLE_SID=+ASM
set ORACLE_HOME=%CRSHOME%
set PATH=%ORACLE_HOME%\bin;%OLD_PATH%
rem PERL5LIB moet in deze omgeving gezet worden omdat anders oa ASMCMD niet werkt.
set PERL5LIB=D:\app\grid\product\12.2.0\GIhome_1\perl\lib
goto display

rem
rem HTTP option
rem
:http
echo.
set ORACLE_SID=HTTP
set ORACLE_HOME=%HTTPHOME%
set PATH=%ORACLE_HOME%\bin;%OLD_PATH%
goto display

rem
rem DB1 option
rem
:db1
echo.
if /I "%ORACLE_SID%"=="" (
  echo ERROR:  An ORACLE_SID is required for this OH-type.
  echo.
  goto help )
set ORACLE_SID=%ORACLE_SID%
set ORACLE_HOME=%DB1HOME%
set PATH=%ORACLE_HOME%\bin;%OLD_PATH%
goto display

rem
rem DB2 option
rem
:db2
echo.
if /I "%ORACLE_SID%"=="" (
  echo ERROR:  An ORACLE_SID is required for this OH-type.
  echo.
  goto help )
set ORACLE_SID=%ORACLE_SID%
set ORACLE_HOME=%DB2HOME%
set PATH=%ORACLE_HOME%\bin;%OLD_PATH%
goto display

rem
rem DB3 option
rem
:db3
echo.
if /I "%ORACLE_SID%"=="" (
  echo ERROR:  An ORACLE_SID is required for this OH-type.
  echo.
  goto help )
set ORACLE_SID=%ORACLE_SID%
set ORACLE_HOME=%DB3HOME%
set PATH=%ORACLE_HOME%\bin;%OLD_PATH%
goto display

rem
rem DISPLAY command
rem
:display
echo ORACLE_SID   = %ORACLE_SID%
echo ORACLE_HOME  = %ORACLE_HOME%
echo PATH         = %PATH%
echo.
goto end

rem
rem RESET command
rem
:reset
set ORACLE_SID=
set ORACLE_HOME=
set PATH=%OLD_PATH%
echo.
goto display

rem
rem ERROR command
rem
:error
echo.
echo Error:  The parameter '%OHTYPE%' was not recognized as a valid Oracle Home type.
echo.         
goto help

rem
rem HELP Command
rem
:help
echo.
echo Usage:  oraenv.bat [OH TYPE][ORACLE_SID]
echo.
echo       [OH TYPE]:
echo          AGENT    : Oracle Home EM agent
echo          OMS      : Oracle Home OMS
echo          CRS      : Oracle Home Clusterware
echo          HTTP     : Oracle Home Apache Webserver
echo          DB1       : Oracle Home Database
echo          display  : Display variables
echo          reset    : Unset variables
echo          help     : Display this message
echo       [ORACLE_SID]: Oracle database SID. Only in combination with OH_TYPE 'DB'.
echo.
goto end

:end 
echo on
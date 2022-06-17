@echo off
REM 
REM dan start met het verzamelen van het geheugen in use van de database servers 
net start | findstr OracleService > ora_services.ora
for /F %%A in (ora_services.ora) DO (call D:\dbanl\Patches\patchdb.cmd %%A)
REM del ora_services.ora


@echo off
REM eerst geheugen in use van de server ophalen.
powershell D:\dbanl\scripts\checkup\get-memory.ps1
REM 
REM dan start met het verzamelen van het geheugen in use van de database servers 
net start | findstr OracleService > ora_services.ora
for /F %%A in (ora_services.ora) DO (call D:\dbanl\scripts\checkup\rundb.cmd %%A)
del ora_services.ora


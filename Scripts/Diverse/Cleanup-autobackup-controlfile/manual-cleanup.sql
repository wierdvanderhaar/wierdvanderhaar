set trimspool off
set lines 200
set pages 0
del D:\Oracle\rman_backupscripts\logs\file2delete.sql
spool D:\Oracle\rman_backupscripts\logs\file2delete.sql
select 'host del ' ||  fname from V_$BACKUP_FILES where fname is not null and file_type = 'PIECE' and trunc(COMPLETION_TIME) < trunc(SYSDATE-2);
spool off
@D:\Oracle\rman_backupscripts\logs\file2delete.sql
exit
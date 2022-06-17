select     db_name "Database",
	input_type "Type backup",
   to_char(start_time,'dd-Mon HH24:mi') "Start Backup",
   to_char(end_time,'dd-Mon HH24:mi') "Einde Backup",
   output_bytes_display "Grootte",
   status "Status"
from rman.rc_rman_backup_job_details
where session_key in (select max(session_key)
                   from rman.rc_rman_backup_job_details
                   group by db_key
                   )

				   
				   

set lines 80
set pages 250
ttitle "Daily Backup........"
select DB NAME,
NVL(TO_CHAR(max(backuptype_db),'DD/MM/YYYY HH24:MI'),'01/01/0001:00:00') DBBackup,
NVL(TO_CHAR(max(backuptype_arch),'DD/MM/YYYY HH24:MI'),'01/01/0001:00:00') ARCHBackup
from (
select a.name DB,dbid,
decode(b.bck_type,'D',max(b.completion_time),'I',
max(b.completion_time)) BACKUPTYPE_db,
decode(b.bck_type,'L',
max(b.completion_time)) BACKUPTYPE_arch
from rc_database a,bs b
where a.db_key=b.db_key
and b.bck_type is not null
and b.bs_key not in(Select bs_key from rc_backup_controlfile
where AUTOBACKUP_DATE is not null or AUTOBACKUP_SEQUENCE is not null)
and b.bs_key not in(select bs_key from rc_backup_spfile)
group by a.name,dbid,b.bck_type
) group by db
ORDER BY least(to_date(DBBackup,'DD/MM/YYYY HH24:MI'),
to_date(ARCHBackup,'DD/MM/YYYY HH24:MI'));
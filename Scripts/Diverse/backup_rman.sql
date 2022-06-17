-- BACKUP RAPPORTselect
select b.db_name "Database"
	 , to_char(b.start_time,'DD-MON-YY HH24:MI') "Start tijd"
	 , b.status "Status Job"
	 , max(b.time_taken_display) "Duur"
	 , sum(regexp_replace(b.output_bytes_display, '[[:alpha:]]', '')) "Grootte"
from rcat.rc_backup_set_details c
, rcat.rc_rman_backup_job_details b
where c.session_recid=b.session_recid
and c.session_stamp=b.session_stamp
and c.session_key=b.session_key
and c.controlfile_included='NONE'
and c.backup_type='D'
and c.INCREMENTAL_LEVEL='0'
group by b.db_name, to_char(b.start_time,'DD-MON-YY HH24:MI'), b.status
order by 1,2,3;

Overzicht RMAN backups afgelopen week:
select to_char(start_time, 'DD-MON-YYY HH24:MI') "Start tijd",
		 to_char(end_time, 'DD-MON-YYY HH24:MI') "Eind tijd",
		 input_type "Type Backup",
		 output_bytes_display "Grootte",
		 status "Status"
	from v$rman_backup_job_details
	where trunc(start_time) > trunc(SYSDATE-7) 
union all
select 'Geen Rman backups aanwezig!',null, null, null, null
from dual
where not exists ( select session_key
	 		 from v$rman_backup_job_details)
/


-----------------------------------------------------------------------------------
--
-- Bestandsnaam:	backup_rman.sql
-- Versie:		1.1
-- Doel:		Controleren van Rman backups
-- Parameters:	-
-- Gebruik:		-	
-- Auteur:		Gerben Lenderink
-- Historie:	Datum		Auteur			Wijzigingen
-- 			10-04-2008	G. Lenderink		1e versie
--			09-06-2008	G. Lenderink		Output bevat nu alle backups op max(start_time) en 
--									niet alleen de laatste 6.
--
-----------------------------------------------------------------------------------

set feedback off
set verify off
set echo off
set heading off
set markup html off
set pagesize 10000

-- spool backups.html

select '<H4>8. RMAN Backups </H4>'
from dual;

-- Vanaf versie 10.2
select '<H5>8.1 V$RMAN_BACKUP_JOB_DETAILS (Vanaf versie 10.2)</H5>'
from dual;

set markup html on table "width=auto border=1"
set heading on

select to_char(start_time, 'DD-MON-YYY HH24:MI') "Start tijd",
		 to_char(end_time, 'DD-MON-YYY HH24:MI') "Eind tijd",
		 input_type "Type Backup",
		 output_bytes_display "Grootte",
		 status "Status"
	from v$rman_backup_job_details
	where trunc(start_time)=(select max(trunc(start_time)) from v$rman_backup_job_details)
union all
select 'Geen Rman backups aanwezig!',null, null, null, null
from dual
where not exists ( select session_key
	 		 from v$rman_backup_job_details)
/

set markup html off
set heading off

-- Versie 10.1 en ouder
select '<H5>8.2 V$BACKUP_SET (Versie 9i en 10.1)</H5>'
from dual;

set markup html on table "width=auto border=1"
set heading on

select recid "Rec Id",
             to_char(start_time, 'DD-MON-YYYY HH24:MI') "Start tijd",
		 to_char(completion_time, 'DD-MON-YYYY HH24:MI') "Eind tijd",
		 decode(backup_type, 'D', 'Full', 'I','Incremental','L','Archivelogs') "Type backup"
	from v$backup_set
      where trunc(start_time)=(select max(trunc(start_time)) from v$backup_set)
union all
select null,'Geen Rman backups aanwezig!',null,null
from dual
where not exists ( select recid
	 		 from v$backup_set)
/

-- spool off
set markup html off
set feedback on
set verify on
set heading on

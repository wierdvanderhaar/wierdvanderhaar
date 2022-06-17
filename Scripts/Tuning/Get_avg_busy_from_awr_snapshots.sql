column stat_name format a20
column value format 9999999999999999999
column dag format a10
column tijd format a10
set pages 1000
spool c:\temp\%ORACLE_SID%_avg_busy.log
select snap.dag, snap.tijd, round(((busy.value/(busy.value + idle.value)) * 100),2) as Percent_busy from 
(select snap_id, stat_name, value from dba_hist_osstat where stat_name = 'BUSY_TIME' and instance_number = 1 group by snap_id, stat_name, value order by 1,2) busy,
(select snap_id, stat_name, value from dba_hist_osstat where stat_name ='IDLE_TIME' and instance_number = 1 group by snap_id, stat_name, value order by 1,2) idle,
(select snap_id,to_char(BEGIN_INTERVAL_TIME,'DD') dag,to_char(BEGIN_INTERVAL_TIME,'HH24') tijd from DBA_HIST_SNAPSHOT where instance_number =1 group by snap_id,BEGIN_INTERVAL_TIME order by 1,2) SNAP
where busy.snap_id = idle.snap_id
and busy.snap_id = snap.snap_id
and idle.snap_id = snap.snap_id;
spool off

Gemiddeld:
select round(avg(((busy.value/(busy.value + idle.value)) * 100)),2) as Percent_busy from 
(select snap_id, stat_name, value from dba_hist_osstat where stat_name = 'BUSY_TIME' and instance_number = 1 group by snap_id, stat_name, value order by 1,2) busy,
(select snap_id, stat_name, value from dba_hist_osstat where stat_name ='IDLE_TIME' and instance_number = 1 group by snap_id, stat_name, value order by 1,2) idle,
(select snap_id,to_char(BEGIN_INTERVAL_TIME,'DD') dag,to_char(BEGIN_INTERVAL_TIME,'HH24') tijd from DBA_HIST_SNAPSHOT where instance_number =1 group by snap_id,BEGIN_INTERVAL_TIME order by 1,2) SNAP
where busy.snap_id = idle.snap_id
and busy.snap_id = snap.snap_id
and idle.snap_id = snap.snap_id;

column stat_name format a20
column value format 9999
column aantal format 999
column dag format a10
column tijd format a10
set pages 1000
spool c:\temp\%ORACLE_SID%_sessions.log
select snap.dag, snap.tijd, ses.aantal from
(select snap_id, count(*) as aantal from dba_hist_active_sess_history group by snap_id order by 1) ses,
(select snap_id,to_char(BEGIN_INTERVAL_TIME,'DD') dag,to_char(BEGIN_INTERVAL_TIME,'HH24') tijd from DBA_HIST_SNAPSHOT group by snap_id,BEGIN_INTERVAL_TIME order by 1,2) SNAP
where ses.snap_id = snap.snap_id;
spool off




select avg(session_ID) as aantal from dba_hist_active_sess_history snaphist, 
(select snap_id from dba_hist_active_sess_history group by snap_id order by 1) snaps,
(select snap_id,count(session_id) as back from dba_hist_active_sess_history where SESSION_TYPE='BACKGROUND' group by snap_id) bckp, 
(select snap_id,count(session_id) as fore from dba_hist_active_sess_history where SESSION_TYPE='FOREGROUND' group by snap_id order by 1) frgrd
where snaphist.snap_id=snaps.snap_id
and snaphist.SESSION_TYPE='BACKGROUND'
group by snaphist.snap_id;

select avg(session_id) from dba_hist_active_sess_history;

SELECT  snap_id, count(*)
FROM 	dba_hist_active_sess_history ash, 
	gv$event_name evt
WHERE	ash.session_state = 'WAITING'
AND 	ash.event_id = evt.event_id
AND 	evt.wait_class = 'User I/O'
GROUP BY sql_id
ORDER BY COUNT(*) DESC;

select snap.dag, snap.tijd, round(((busy.value/(busy.value + idle.value)) * 100),2) as Percent_busy from 
(select snap_id, stat_name, value from dba_hist_osstat where stat_name = 'BUSY_TIME' group by snap_id, stat_name, value order by 1,2) busy,
(select snap_id, stat_name, value from dba_hist_osstat where stat_name ='IDLE_TIME' group by snap_id, stat_name, value order by 1,2) idle,
(select snap_id,to_char(BEGIN_INTERVAL_TIME,'DD') dag,to_char(BEGIN_INTERVAL_TIME,'HH24') tijd from DBA_HIST_SNAPSHOT where instance_number =1 group by snap_id,BEGIN_INTERVAL_TIME order by 1,2) SNAP
where busy.snap_id = idle.snap_id
and busy.snap_id = snap.snap_id
and idle.snap_id = snap.snap_id



select round(((avg(busy.value)/(avg(busy.value) + avg(idle.value))) * 100),2) as Percent_busy from 
(select snap_id, stat_name, value from dba_hist_osstat where stat_name = 'BUSY_TIME' group by snap_id, stat_name, value order by 1,2) busy,
(select snap_id, stat_name, value from dba_hist_osstat where stat_name ='IDLE_TIME' group by snap_id, stat_name, value order by 1,2) idle,
(select snap_id,to_char(BEGIN_INTERVAL_TIME,'DD') dag,to_char(BEGIN_INTERVAL_TIME,'HH24') tijd from DBA_HIST_SNAPSHOT group by snap_id,BEGIN_INTERVAL_TIME order by 1,2) SNAP
where busy.snap_id = idle.snap_id
and busy.snap_id = snap.snap_id
and idle.snap_id = snap.snap_id;


select round(avg(((busy.value/(busy.value + idle.value)) * 100)),2) as Percent_busy from 
(select snap_id, stat_name, value from dba_hist_osstat where stat_name = 'BUSY_TIME' and instance_number = 1 group by snap_id, stat_name, value order by 1,2) busy,
(select snap_id, stat_name, value from dba_hist_osstat where stat_name ='IDLE_TIME' and instance_number = 1 group by snap_id, stat_name, value order by 1,2) idle,
(select snap_id,to_char(BEGIN_INTERVAL_TIME,'DD') dag,to_char(BEGIN_INTERVAL_TIME,'HH24') tijd from DBA_HIST_SNAPSHOT where instance_number =1 group by snap_id,BEGIN_INTERVAL_TIME order by 1,2) SNAP
where busy.snap_id = idle.snap_id
and busy.snap_id = snap.snap_id
and idle.snap_id = snap.snap_id;



--Active Session Info
SELECT b.sid, b.serial#, a.spid, b.sql_id, b.program, b.osuser, b.machine,
b.TYPE, b.event, b.action, b.p1text, b.p2text, b.p3text, b.state, c.sql_text,b.logon_time
FROM v$process a, v$session b, v$sqltext c
WHERE a.addr=b.paddr
AND b.sql_hash_value = c.hash_value
AND b.STATUS = 'ACTIVE'
ORDER BY a.spid, c.piece
 
--Trace SQL Query Average Execution Time Using SQL ID
SELECT sql_id, child_number, plan_hash_value plan_hash, executions execs,
(elapsed_time/1000000)/decode(nvl(executions,0),0,1,executions) avg_etime,
buffer_gets/decode(nvl(executions,0),0,1,executions) avg_lio, sql_text
FROM v$sql s
WHERE s.sql_id='4n01r8z5hgfru'
 
--Get The Detail Explain Plan Using SQL ID
SELECT plan_table_output FROM TABLE(dbms_xplan.display_cursor('dtdqt19kfv6yx'))
 
--Session Elapsed Processing Time 
SELECT s.sid, s.username, s.module,
round(t.VALUE/1000000,2) "Elapsed Processing Time (Sec)"
FROM v$sess_time_model t, v$session s
WHERE t.sid = s.sid
AND t.stat_name = 'DB time'
AND s.username IS NOT NULL
AND t.VALUE/1000000 >= '1' --running more than 1 second
ORDER BY round(t.VALUE/1000000,2) DESC
 
--Session Elapsed Processing Time Statistic By SID
SELECT  a.sid, b.username, a.stat_name, ROUND((a.VALUE/1000000),2) "Time (Sec)"
FROM v$sess_time_model a, v$session b
WHERE a.sid = b.sid
AND b.sid = '194'  
ORDER BY ROUND((a.VALUE/1000000),2) DESC
 
--Use Longops To Check The Estimation Query Runtime
SELECT sid, serial#, opname, target, sofar, totalwork, units, start_time, 
last_update_time, time_remaining "REMAIN SEC", round(time_remaining/60,2) "REMAIN MINS", 
elapsed_seconds "ELAPSED SEC", round(elapsed_seconds/60,2) "ELAPSED MINS", 
round((time_remaining+elapsed_seconds)/60,2)"TOTAL MINS", message TIME 
FROM v$session_longops
WHERE sofar<>totalwork
AND time_remaining <> '0'
 
--Detect Blocking Session
SELECT sid, serial#, username, STATUS, state, event, 
blocking_session, seconds_in_wait, wait_time, action, logon_time
FROM gv$session 
WHERE state IN ('WAITING') 
AND wait_class != 'Idle'
AND event LIKE '%enq%'
AND TYPE='USER'
 
--Active Table Locking
SELECT b.sid, b.serial#, b.program, b.osuser, b.machine, b.TYPE, b.action,
c.sql_text,b.logon_time, e.owner, e.object_name "Table Lock"
FROM v$session b, v$sqltext c, v$locked_object d, dba_objects e
WHERE b.sql_address = c.address
AND b.sid = d.session_id
AND d.object_id = e.object_id
AND b.STATUS = 'ACTIVE'
ORDER BY b.sid, c.piece
 
--RAC Active Table Locking
SELECT b.sid, b.serial#, a.spid, b.program, b.osuser, b.machine, 
b.TYPE, b.event, b.action, b.p1text, b.p2text, b.p3text, 
b.state, c.sql_text,b.logon_time, 
b.STATUS,  e.owner, e.object_name "Table Lock"
FROM gv$process a, gv$session b, gv$sqltext c, gv$locked_object d, dba_objects e
WHERE a.addr=b.paddr
AND b.sql_address = c.address
AND b.sid = d.session_id
AND d.object_id = e.object_id
AND b.STATUS = 'ACTIVE'
ORDER BY a.spid, c.piece
 
--Monitor Top Waiting Event Using Active Session History (ASH)
SELECT h.event,
SUM(h.wait_time + h.time_waited) "Total Wait Time (ms)"
FROM v$active_session_history h, v$sqlarea SQL, dba_users u, v$event_name e 
WHERE h.sample_time BETWEEN sysdate - 1/24 AND sysdate --event in the last hour
AND h.sql_id = SQL.sql_id
AND h.user_id = u.user_id
AND h.event# = e.event#
GROUP BY h.event
ORDER BY SUM(h.wait_time + h.time_waited) DESC
 
--Monitor Highest SQL Wait Time Using Active Session History (ASH)
SELECT h.session_id, h.session_serial#, h.sql_id, h.session_state, 
h.blocking_session_status, h.event, e.wait_class, h.module, u.username, SQL.sql_text,
SUM(h.wait_time + h.time_waited) "Total Wait Time (ms)"
FROM v$active_session_history h, v$sqlarea SQL, dba_users u, v$event_name e 
WHERE h.sample_time BETWEEN sysdate - 1/24 AND sysdate --event in the last hour
AND h.sql_id = SQL.sql_id
AND h.user_id = u.user_id
AND h.event# = e.event#
GROUP BY h.session_id, h.session_serial#, h.sql_id, h.session_state, 
h.blocking_session_status, h.event, e.wait_class, h.module, u.username, SQL.sql_text
ORDER BY SUM(h.wait_time + h.time_waited) DESC
 
--Monitor Highest Object Wait Time Using Active Session History (ASH)
SELECT o.owner, o.object_name, o.object_type, h.session_id, h.session_serial#, 
h.sql_id, h.module, SUM(h.wait_time + h.time_waited) "Total Wait Time (ms)"
FROM v$active_session_history h, dba_objects o, v$event_name e 
WHERE h.sample_time BETWEEN sysdate - 1/24 AND sysdate --event in the last hour
AND h.current_obj# = o.object_id
AND e.event_id = h.event_id
GROUP BY  o.owner, o.object_name, o.object_type, h.session_id, h.session_serial#,
h.sql_id, h.module
ORDER BY SUM(h.wait_time + h.time_waited) DESC
 
--Monitor Highest Event Wait Time Using Active Session History (ASH)
SELECT h.event "Wait Event", SUM(h.wait_time + h.time_waited) "Total Wait Time (ms)"
FROM v$active_session_history h, v$event_name e
WHERE h.sample_time BETWEEN sysdate - 1/24 AND sysdate --event in the last hour
AND h.event_id = e.event_id
AND e.wait_class <> 'Idle'
GROUP BY h.event
ORDER BY SUM(h.wait_time + h.time_waited) DESC
 
--Database Time Model Statistic
SELECT wait_class, NAME, ROUND (time_secs, 2) "Time (Sec)",
ROUND (time_secs * 100 / SUM (time_secs) OVER (), 2) pct
FROM 
(SELECT n.wait_class, e.event NAME, e.time_waited / 100 time_secs
FROM v$system_event e, v$event_name n
WHERE n.NAME = e.event 
AND n.wait_class <> 'Idle'
AND time_waited > 0
UNION
SELECT 
'CPU', 
'Server CPU', 
SUM (VALUE / 1000000) time_secs
FROM v$sys_time_model
WHERE stat_name IN ('background cpu time', 'DB CPU'))
ORDER BY time_secs DESC;
 
--Monitor I/O On Data Files
SELECT vfs.file#, dbf.file_name, dbf.tablespace_name, dbf.bytes, vfs.phyrds/vfs.phywrts,
vfs.phyblkrd/vfs.phyblkwrt, vfs.readtim, vfs.writetim 
FROM v$filestat vfs, dba_data_files dbf
WHERE vfs.file# = dbf.file_id
 
--I/O Stats For Data Files & Temp Files
SELECT file_no,
filetype_name, 
small_sync_read_reqs "Synch Single Block Read Reqs",
small_read_reqs "Single Block Read Requests",
small_write_reqs "Single Block Write Requests",
round(small_sync_read_latency/1000,2) "Single Block Read Latency (s)",
large_read_reqs "Multiblock Read Requests",
large_write_reqs "Multiblock Write Requests",
asynch_io "Asynch I/O Availability"
FROM v$iostat_file
WHERE filetype_id IN (2,6) 
 
--I/O Stats By Functionality
SELECT function_name,
small_read_reqs "Single Block Read Requests",
small_write_reqs "Single Block Write Requests",
large_read_reqs "Multiblock Read Requests",
large_write_reqs "Multiblock Write Requests",
number_of_waits "I/O Waits",
round(wait_time/1000,2) "Total Wait Time (ms)"
FROM v$iostat_function
ORDER BY function_name
 
--Temporary Tablespace Usage By SID
SELECT tu.username, s.sid, s.serial#, s.sql_id, s.sql_address, tu.segtype, 
tu.extents, tu.blocks, SQL.sql_text
FROM v$tempseg_usage tu, v$session s, v$sql SQL
WHERE tu.session_addr = s.addr
AND tu.session_num = s.serial#
AND s.sql_id = SQL.sql_id
AND s.sql_address = SQL.address
 
--Monitor Overall Oracle Tablespace 
SELECT d.STATUS "Status",
d.tablespace_name "Name",
d.contents "Type",
d.extent_management "Extent Management",
d.initial_extent "Initial Extent",
TO_CHAR(NVL(a.bytes / 1024 / 1024, 0),'99,999,990.900') "Size (M)",
TO_CHAR(NVL(a.bytes - NVL(f.bytes, 0), 0)/1024/1024,'99,999,999.999') "Used (M)",
TO_CHAR(NVL((a.bytes - NVL(f.bytes, 0)) / a.bytes * 100, 0), '990.00') "Used %",
TO_CHAR(NVL(a.maxbytes / 1024 / 1024, 0),'99,999,990.900') "MaxSize (M)",
TO_CHAR(NVL((a.bytes - NVL(f.bytes, 0)) / a.maxbytes * 100, 0), '990.00') "Used % of Max"
FROM sys.dba_tablespaces d,
(SELECT tablespace_name, 
SUM(bytes) bytes, 
SUM(decode(autoextensible,'NO',bytes,'YES',maxbytes))
maxbytes FROM dba_data_files GROUP BY tablespace_name) a,
(SELECT tablespace_name, SUM(bytes) bytes FROM dba_free_space 
GROUP BY tablespace_name) f
WHERE d.tablespace_name = a.tablespace_name(+)
AND d.tablespace_name = f.tablespace_name(+)
ORDER BY 10 DESC;
 
--Cache Hit Ratio
SELECT ROUND(((1-(SUM(DECODE(name,
'physical reads', VALUE,0))/
(SUM(DECODE(name, 'db block gets', VALUE,0))+
(SUM(DECODE(name, 'consistent gets', VALUE, 0))))))*100),2)
|| '%' "Buffer Cache Hit Ratio"
FROM v$sysstat --Use gv$sysstat if running on RAC environment
 
--Library Cache Hit Ratio
SELECT SUM(pins) "Total Pins", SUM(reloads) "Total Reloads",
SUM(reloads)/SUM(pins) *100 libcache
FROM v$librarycache --Use v$librarycache if running on RAC environment
 
--DB Session Memory Usage
SELECT se.sid,n.name, MAX(se.VALUE) maxmem
FROM v$sesstat se, v$statname n
WHERE n.statistic# = se.statistic#
AND n.name IN ('session pga memory','session pga memory max',
'session uga memory','session uga memory max')
GROUP BY n.name, se.sid
ORDER BY MAX(se.VALUE) 
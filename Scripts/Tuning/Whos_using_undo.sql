SELECT TO_CHAR(s.sid)||','||TO_CHAR(s.serial#) sid_serial,
         NVL(s.username, 'None') orauser,
         s.program,
         r.name undoseg,
         round((t.used_ublk * TO_NUMBER(x.value)/1024/1024),2)||'M' "Undo"
    FROM sys.v_$rollname    r,
         sys.v_$session     s,
         sys.v_$transaction t,
         sys.v_$parameter   x
   WHERE s.taddr = t.addr
     AND r.usn   = t.xidusn(+)
     AND x.name  = 'db_block_size';


-- -----------------------------------------------------------------------------------
-- File Name    : http://www.oracle-base.com/dba/monitoring/session_undo.sql
-- Author       : DR Timothy S Hall
-- Description  : Displays undo information on relevant database sessions.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @session_undo
-- Last Modified: 29/03/2005
-- -----------------------------------------------------------------------------------
SET LINESIZE 200

COLUMN username FORMAT A15

SELECT s.username,
       s.sid,
       s.serial#,
       t.used_ublk,
       t.used_urec,
       rs.segment_name,
       r.rssize,
       r.status
FROM   v$transaction t,
       v$session s,
       v$rollstat r,
       dba_rollback_segs rs
WHERE  s.saddr = t.ses_addr
AND    t.xidusn = r.usn
AND    rs.segment_id = t.xidusn
ORDER BY t.used_ublk DESC;

-----
-- Undo Extent status
----
BREAK ON REPORT
COMPUTE SUM OF MB ON REPORT
COMPUTE SUM OF PERC ON REPORT
COMPUTE SUM OF FULL ON REPORT

select status,
 round(sum_bytes / (1024*1024), 0) as MB,
 round((sum_bytes / undo_size) * 100, 0) as PERC,
 decode(status, 'UNEXPIRED', round((sum_bytes / undo_size * factor) * 100, 0),
                'EXPIRED',   0,
                             round((sum_bytes / undo_size) * 100, 0)) FULL
from
(
 select status, sum(bytes) sum_bytes
 from dba_undo_extents
 group by status
),
(
 select sum(a.bytes) undo_size
 from dba_tablespaces c
 join v$tablespace b on b.name = c.tablespace_name
 join v$datafile a on a.ts# = b.ts#
 where c.contents = 'UNDO'
 and c.status = 'ONLINE'
),
(
 select tuned_undoretention, u.value, u.value/tuned_undoretention factor
 from v$undostat us
 join (select max(end_time) end_time from v$undostat) usm
    on usm.end_time = us.end_time
 join (select name, value from v$parameter) u
    on u.name = 'undo_retention'
);
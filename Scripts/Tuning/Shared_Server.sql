-- Aantal Shared Server processes
SELECT COUNT(*) "Shared Server Processes"
 FROM V$SHARED_SERVER
 WHERE STATUS != 'QUIT';

-- Shared Server Session information
SELECT MAXIMUM_CONNECTIONS "MAX CONN", MAXIMUM_SESSIONS
  "MAX SESS",SERVERS_STARTED "STARTED", SERVERS_TERMINATED
  "TERMINATED", SERVERS_HIGHWATER "HIGHWATER" FROM V$SHARED_SERVER_MONITOR;  

-- Get AVG_Busy voor Shared Server
select a.snap_id,
to_char(b.BEGIN_INTERVAL_TIME,'YYYY-MON-DD HH24:MI:SS'),
SAMPLED_TOTAL_CONN,
SAMPLED_ACTIVE_CONN,
SRV_BUSY,
SRV_IDLE,
100 * round((srv_busy/(srv_idle+srv_busy)),4) busy_percent
from DBA_HIST_SHARED_SERVER_SUMMARY A, DBA_HIST_SNAPSHOT b
where a.snap_id = b.snap_id
order by 2;


-- List dispatcher:
column messages     format 999,999,999,999
column bytes        format 999,999,999,999
column idle         format 999,999,999,999
column busy         format 999,999,999,999
column total_time   format 999,999,999,999
column busy_percent format 999.99
 
select
        name, /* network, */ messages, bytes,
        idle, busy,
        idle + busy total_time,
        100 * round(busy/nullif(idle+busy,0),4) busy_percent
from
        v$dispatcher;
-- Columm STATUS
/* 
STATUS	VARCHAR2(16)	Status of the dispatcher:
WAIT - Idle
SEND - Sending a message
RECEIVE - Receiving a message
CONNECT - Establishing a connection
DISCONNECT - Handling a disconnect request
BREAK - Handling a break
TERMINATE - In the process of terminating
ACCEPT - Accepting connections (no further information available)
REFUSE - Rejecting connections (no further information available)
*/
SELECT NAME "NAME", SUBSTR(NETWORK,1,23) "PROTOCOL", OWNED "Aantal Circuits", STATUS
  "STATUS", (BUSY/(BUSY + IDLE)) * 100 "%TIME BUSY" FROM V$DISPATCHER;

-- Gemiddeld wachtijd per request.
SELECT DECODE(TOTALQ, 0, 'No Requests',
 WAIT/TOTALQ || ' HUNDREDTHS OF SECONDS') "AVERAGE WAIT TIME PER REQUESTS"
 FROM V$QUEUE
 WHERE TYPE = 'COMMON';

-- Totaal geheugen (UGA) in gebruik voor alle sessies:
SELECT round((SUM(VALUE/1024/1024)),0) || ' MBYTES' "TOTAL MEMORY FOR ALL SESSIONS"
 FROM V$SESSTAT, V$STATNAME
 WHERE NAME = 'session uga memory'
 AND V$SESSTAT.STATISTIC# = V$STATNAME.STATISTIC#;

-- Maximaal geheugen (UGA) voor alle sessies:
SELECT round((SUM(VALUE/1024/1024)),0) || ' MBYTES' "TOTAL MAX MEM FOR ALL SESSIONS"
 FROM V$SESSTAT, V$STATNAME
 WHERE NAME = 'session uga memory max'
 AND V$SESSTAT.STATISTIC# = V$STATNAME.STATISTIC#;

-- Histogram aangaande reactie tijd a
select
    *
from
    v$reqdist
order by
    bucket
;
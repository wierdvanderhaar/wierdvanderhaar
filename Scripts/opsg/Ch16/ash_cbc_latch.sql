column program format a10
column username format a8
column module format a12
column object_name format a12
column time_ms format 999,999,999
column pct_of_time format 99.99
column sql_text format a70
column lock_type format a4 

set pages 1000
set lines 100
set echo on 
 
WITH ash_query AS (
     SELECT substr(event,6,2) lock_type,program, 
            h.module, h.action,   object_name,
            SUM(time_waited)/1000 time_ms, COUNT( * ) waits, 
            username, sql_text,
            RANK() OVER (ORDER BY SUM(time_waited) DESC) AS time_rank,
            ROUND(SUM(time_waited) * 100 / SUM(SUM(time_waited)) 
                OVER (), 2)             pct_of_time
      FROM  v$active_session_history h 
      JOIN  dba_users u  USING (user_id)
      LEFT OUTER JOIN dba_objects o
           ON (o.object_id = h.current_obj#)
      LEFT OUTER JOIN v$sql s USING (sql_id)
     WHERE event LIKE 'enq: %'
     GROUP BY substr(event,6,2) ,program, h.module, h.action, 
         object_name,  sql_text, username)
SELECT lock_type,module, username,  object_name, time_ms,pct_of_time,
         sql_text
FROM ash_query
WHERE time_rank < 11
ORDER BY time_rank; 
 

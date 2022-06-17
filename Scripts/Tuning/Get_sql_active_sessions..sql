-- Deze query haalt de users en het uitgevoerde statement op basis van active sessies. 
select a.username, count(*) as AANTAL_SESSIONS,b.sql_text,avg(b.DISK_READS) DSKRDS, avg(CPU_TIME) CPUTM
from v$session a, v$sql b 
where a.username is not null 
and a.status ='ACTIVE'
and a.username <> 'SYS'
and a.sql_id is not null
and b.sql_id = a.sql_id
group by a.username,b.sql_text
order by DSKRDS,CPUTM;


-- Spool "select * from table(dbms_xplan.display_cursor('SQL_ID'))" for active queries.
select 'select * from table(dbms_xplan.display_cursor(' || '''' || a.sql_id || '''' || '));' 
from v$session a, v$sql b 
where a.username is not null 
and a.status ='ACTIVE'
and a.username <> 'SYS'
and a.sql_id is not null
and b.sql_id = a.sql_id
group by a.sql_id;

TTittle 'What is a OS session Doing? ' 

col "OS Program" format a17
col "User Name" format a10


select p.spid "process id",
b.name "Background Process",
s.username "User Name",
s.osuser "OS User",
s.status "STATUS",
s.sid "Session ID",
s.serial# "Serial No.",
s.program "OS Program",
s.sql_id "SQL_ID",
s.event "Wait Event"
  from gv$process p, gv$bgprocess b, gv$session s
  where s.paddr = p.addr and b.paddr(+) = p.addr 
  and status='ACTIVE';


-- Welk statement wordt uitgevoerd door os session
set long 10000
select ses.username
,           ses.osuser
,           ses.program
,           ses.machine
,			sql.sql_id
,	    	sql.sql_text
,			wai.event
FROM 	    gv$session ses
,           gv$process proc
,           gv$sqlarea sql
,			gv$session_wait wai
WHERE 	    proc.spid = &process
AND	    	ses.paddr = proc.addr
AND	    	ses.sql_id = sql.sql_id
AND			ses.sid = wai.sid;



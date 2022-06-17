SELECT	p.spid,
		p.program, 
		a.sql_text,
		s.saddr, 
		s.sid, 
		s.serial#, 
		s.username,
		s.osuser, 
		s.machine, 
		s.program, 
		s.logon_time, 
		s.status
FROM 	v$session s, 
		v$process p,
		v$sqlarea a
WHERE 	s.username is not null
AND		s.paddr = p.addr
AND 	a.sql_text like 'select * from %'
order by s.logon_time,a.LAST_ACTIVE_TIME;
declare
v_numlog number(10);
v_logsize number(10);
v_lognum number (10) := 1;
-- cursor c1 is select max(group#) as "aantal", max(bytes) as "grote" from v$log;
cursor c2 is select group# from v$standby_log;
begin
-- Drop eerst de oude standby redologs
for i in c2 loop
-- execute immediate 'alter database drop logfile group ' || i.group#;
dbms_output.put_line ('alter database drop logfile group ' || i.group#);
end loop;
-- Creer de standby redologs met de juiste grote.
select max(group#), max(bytes) into v_numlog, v_logsize from v$log;
v_numlog := v_numlog + 1;
for x in 1..v_numlog loop
-- execute immediate 'alter database add standby logfile group ' || v_lognum || '''' || 'D:\oracle\oradata\@\redo1' || v_lognum || '.log size ' || v_logsize; 
dbms_output.put_line ('alter database add standby logfile group ' || v_lognum || '''' || 'D:\oracle\oradata\@\redo1' || v_lognum || '.log size ' || v_logsize);
v_lognum := v_lognum + 1;
end loop;
end;
/
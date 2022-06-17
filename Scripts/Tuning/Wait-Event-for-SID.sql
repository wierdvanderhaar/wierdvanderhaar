-- Get wait-event for SID.
select  a.sid, a.event, a.p1raw, a.seconds_in_wait, a.wait_time, a.sql_id
 FROM 	sys.v_$session a
--		, sys.v_$sql b
where a.sid in (7,15,173);
-- and a.sql_id = b.sql_id;

-- Get wait-event for OSUSER.
select  a.sid, a.event, a.p1raw, a.seconds_in_wait, a.wait_time, a.sql_id
 FROM 	sys.v_$session a
--		, sys.v_$sql b
where a.osuser = 'e.stok';
-- and a.sql_id = b.sql_id;

-- Get wait-event and SQL_TEXT for SID
select  a.sid, a.event, a.p1raw, a.seconds_in_wait, a.wait_time, a.sql_id, b.sql_text
 FROM 	sys.v_$session a
		, sys.v_$sql b
where a.sid in (7,15,173)
and a.sql_id = b.sql_id;

select  a.sid, a.event, a.p1raw, a.seconds_in_wait, a.wait_time, a.sql_id, b.sql_text
 FROM 	sys.v_$session a
		, sys.v_$sql b
where a.sql_id = b.sql_id;
declare
cursor c1 is select file#,block# from v$database_block_corruption order by file#; 
v_owner varchar2(10);
v_segment_name varchar2(50);
begin
for x in c1 loop
select owner,segment_name into v_owner, v_segment_name from dba_extents
where 	file_id=x.file# 
and 	x.block# between block_id AND block_id + blocks - 1;
dbms_output.put_line(v_owner || '.' || v_segment_name);
end loop;
end;
/
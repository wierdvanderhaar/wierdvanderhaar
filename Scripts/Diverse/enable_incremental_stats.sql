create or replace procedure enable_incremental_stats as 
cursor c1 is select a.text from (select 'DBMS_STATS.SET_TABLE_PREFS(' || '''' || owner || '''' || ',' || '''' || table_name || '''' || ',' || '''' || 'INCREMENTAL' || '''' || ',' || '''' || 'TRUE' || '''' || ');'  as text from dba_tables where partitioned = 'YES' and owner not in ('SYS','SYSTEM')) a;
v_string varchar2(255);
begin
for x in c1 loop
v_string := 'BEGIN ' || x.text || ' END;';
execute immediate v_string;
end loop;
end;
/
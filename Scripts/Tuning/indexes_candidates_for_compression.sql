### LET OP DAT PARALLEL REBUILDEN BETEKEND DAT ALLE INDEXEN OOK PARALLLEL WORDEN QUERIED.

SELECT 	a.object_name, 
	b.statistic_name, 
	b.value
FROM 	all_objects a, 
	v$segstat b
WHERE  	a.object_id = b.obj#
AND  	a.owner = '{your schema owner here}'
AND  	a.object_type = 'INDEX'
AND  	b.statistic_name = 'physical reads';

declare
cursor c1 is select index_name from dba_indexes where owner= 'VTA' and table_name='DECL';
begin
for x in c1 loop
dbms_output.put_line('analyze index VTA.' || x.index_name || ' validate structure;');
dbms_output.put_line('insert into index_stats_hist (select * from index_stats);');
end loop;
end;
/

select name, LF_ROWS, LF_BLKS, PRE_ROWS,PRE_ROWS_LEN,OPT_CMPR_COUNT, OPT_CMPR_PCTSAVE from index_Stats_hist where OPT_CMPR_PCTSAVE > 50;

create or replace procedure index_compression_candidates as
cursor c1 is select b.index_name 
from dba_indexes b
,index_Stats_hist a
where b.owner = 'DEVVANESSA' 
and b.UNIQUENESS = 'NONUNIQUE' 
and b.tablespace_name <> 'VANESSA_INDEX_32K'
and a.name <> b.index_name
group by b.index_name;
begin
for x in c1 loop
dbms_output.put_line ('Start validate structure ' || x.index_name || '!' );
execute immediate ('analyze index DEVVANESSA.' || x.index_name || ' validate structure');
execute immediate ('insert into index_stats_hist (select * from index_stats)');
commit;
end loop;
end;

create or replace procedure index_compression_candidates as
cursor c1 is select a.segment_name 
from dba_segments a, dba_indexes b
where a.owner='DEVVANESSA'
and a.segment_type = 'INDEX'
and a.TABLESPACE_NAME <> 'VANESSA_INDEX_32K'
and a.segment_name = b.index_name
and b.UNIQUENESS = 'NONUNIQUE' 
order by bytes;
begin
for x in c1 loop
dbms_output.put_line ('Start validate structure ' || x.segment_name || '!' );
execute immediate ('analyze index DEVVANESSA.' || x.segment_name || ' validate structure');
execute immediate ('insert into index_stats_hist (select * from index_stats)');
commit;
end loop;
end;

select 'alter index DEVVANESSA."'  || a.segment_name || '" rebuild tablespace VANESSA_INDEX_32K NOLOGGING;' 
from dba_segments a, dba_indexes b
where a.owner='DEVVANESSA'
and a.segment_type = 'INDEX'
and a.TABLESPACE_NAME <> 'VANESSA_INDEX_32K'
and a.segment_name = b.index_name
and b.UNIQUENESS = 'NONUNIQUE' 
order by bytes;


create or replace procedure rebuild_compressed_indexes as
-- rebuild alle nonunique indexen die nog niet in de nieuwe tablespace zijn gecreerd
cursor c1 is select b.index_name, a.OPT_CMPR_COUNT 
from index_Stats_hist a,
dba_indexes b
where a.OPT_CMPR_COUNT > 0 
and b.owner= 'DEVVANESSA' 
and b.UNIQUENESS = 'NONUNIQUE' 
and b.tablespace_name <> 'VANESSA_INDEX_32K'
and a.name = b.index_name
group by b.index_name,a.OPT_CMPR_COUNT;
begin
-- execute immediate ('truncate table index_stats_hist');
for x in c1 loop
-- dbms_output.put_line ('alter index DEVVANESSA."' || x.index_name || '" REBUILD COMPRESS ' || x.OPT_CMPR_COUNT || ' tablespace VANESSA_INDEX_32K parallel 4 NOLOGGING');
execute immediate ('alter index DEVVANESSA."' || x.index_name || '" REBUILD COMPRESS ' || x.OPT_CMPR_COUNT || ' tablespace VANESSA_INDEX_32K parallel 4 NOLOGGING');
end loop;
end;

create or replace procedure rebuild_noncompressed_indexes as
-- rebuild alle nonunique indexen die nog niet in de nieuwe tablespace zijn gecreerd
cursor c1 is select b.index_name
from index_Stats_hist a,
dba_indexes b
where a.OPT_CMPR_COUNT = 0 
and b.owner= 'DEVVANESSA' 
and b.UNIQUENESS = 'NONUNIQUE' 
and b.tablespace_name <> 'VANESSA_INDEX_32K'
and a.name = b.index_name
group by b.index_name;
begin
-- execute immediate ('truncate table index_stats_hist');
for x in c1 loop
dbms_output.put_line ('alter index DEVVANESSA."' || x.index_name || '" REBUILD tablespace VANESSA_INDEX_32K NOLOGGING');
-- execute immediate ('alter index DEVVANESSA."' || x.index_name || '" REBUILD tablespace VANESSA_INDEX_32K NOLOGGING');
end loop;
end;


create or replace procedure rebuild_noncompressed_indexes as
-- rebuild alle unique indexen die nog niet in de nieuwe tablespace zijn gecreerd
cursor c1 is select b.index_name
from dba_indexes b
where b.owner= 'DEVVANESSA' 
and b.UNIQUENESS = 'UNIQUE' 
and b.tablespace_name <> 'VANESSA_INDEX_32K'
group by b.index_name;
begin
-- execute immediate ('truncate table index_stats_hist');
for x in c1 loop
-- dbms_output.put_line ('alter index DEVVANESSA."' || x.index_name || '" REBUILD tablespace VANESSA_INDEX_32K parallel 4 NOLOGGING');
execute immediate ('alter index DEVVANESSA."' || x.index_name || '" REBUILD tablespace VANESSA_INDEX_32K parallel 4 NOLOGGING');
end loop;
end;



select name, LF_ROWS, LF_BLKS, PRE_ROWS,PRE_ROWS_LEN,OPT_CMPR_COUNT, OPT_CMPR_PCTSAVE from index_Stats;

select 'alter index DEVVANESSA.' || name || ' REBUILD COMPRESS ' || OPT_CMPR_COUNT || ';'  from index_Stats_hist where OPT_CMPR_PCTSAVE > 0 and OPT_CMPR_COUNT > 0;

select 'alter index DEVVANESSA.' || a.name || ' REBUILD COMPRESS ' || a.OPT_CMPR_COUNT || ';'  from index_Stats_hist a, dba_indexes b 
where b.tablespace_name = 'VANESSA_INDEX_32K
and a.name = b.index_name
and OPT_CMPR_COUNT > 0;

select 'alter index DEVVANESSA."'  || index_name || '" rebuild COMPRESS ' || a.OPT_CMPR_COUNT || ' tablespace VANESSA_INDEX_32K parallel 4 NOLOGGING;' 
from index_Stats_hist a,
dba_indexes b
where a.OPT_CMPR_COUNT > 0
and b.owner= 'DEVVANESSA' 
and b.UNIQUENESS = 'NONUNIQUE' 
and b.tablespace_name <> 'VANESSA_INDEX_32K'
and a.name = b.index_name;

select name 
from index_Stats_hist a
where a.OPT_CMPR_COUNT > 0;



declare
cursor c1 is select b.index_name 
from index_Stats_hist a,
dba_indexes b
where b.owner= 'DEVVANESSA' 
and b.UNIQUENESS = 'NONUNIQUE' 
and b.tablespace_name <> 'VANESSA_INDEX_32K'
and a.name <> b.index_name
group by b.index_name;
begin
-- execute immediate ('truncate table index_stats_hist');
for x in c1 loop
execute immediate ('analyze index DEVVANESSA.' || x.index_name || ' validate structure');
execute immediate ('insert into index_stats_hist (select * from index_stats)');
commit;
end loop;
end;



select b.index_name 
from index_Stats_hist a,
dba_indexes b
where b.owner= 'DEVVANESSA' 
and b.UNIQUENESS = 'NONUNIQUE' 
-- and b.tablespace_name <> 'VANESSA_INDEX_32K'
and a.name <> b.index_name
group by b.index_name;


select b.index_name, a.OPT_CMPR_COUNT 
from index_Stats_hist a,
dba_indexes b
where b.owner= 'DEVVANESSA' 
-- and b.UNIQUENESS = 'NONUNIQUE' 
and b.tablespace_name <> 'VANESSA_INDEX_32K'
and a.name = b.index_name
group by b.index_name,a.OPT_CMPR_COUNT;


select a.OPT_CMPR_COUNT, count(*) from index_Stats_hist a, dba_indexes b where b.owner= 'DEVVANESSA' and b.tablespace_name <> 'VANESSA_INDEX_32K'and a.name = b.index_name group by a.OPT_CMPR_COUNT


select 'alter index DEVVANESSA."'  || a.segment_name || '" rebuild tablespace VANESSA_INDEX_32K NOLOGGING;' 
from dba_segments a, dba_indexes b
where a.owner='DEVVANESSA'
and a.segment_type = 'INDEX'
and a.TABLESPACE_NAME <> 'VANESSA_INDEX_32K'
and a.segment_name = b.index_name
and b.UNIQUENESS = 'UNIQUE' 
order by bytes;

select 'alter index DEVVANESSA."' || b.index_name || '" rebuild tablespace VANESSA_INDEX_32K NOLOGGING;'
from index_Stats_hist a,
dba_indexes b
where a.OPT_CMPR_COUNT = 0 
and b.owner= 'DEVVANESSA' 
and b.UNIQUENESS = 'NONUNIQUE' 
and b.tablespace_name <> 'VANESSA_INDEX_32K'
and a.name = b.index_name
group by b.index_name,a.OPT_CMPR_COUNT;


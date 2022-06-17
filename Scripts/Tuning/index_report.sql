spool index_report.txt
--*************************************************
--  Index Report Section
--*************************************************
 
column nbr_scans  format 999,999,999
column num_rows   format 999,999,999
column tbl_blocks format 999,999,999
column owner      format a15;
column table_name format a30;
column index_name format a40;
set lines 300
ttitle 'Index full scans and counts'
select
   p.owner,
   d.table_name,
   p.name index_name,
   seg.blocks tbl_blocks,
   sum(s.executions) nbr_scans
from
   dba_segments seg,
   v$sqlarea s,
   dba_indexes d,
  (select distinct
     address, 
     object_owner owner,
     object_name name
   from
      v$sql_plan
   where
      operation = 'INDEX'
      and
      options = 'FULL SCAN') p
where
   d.index_name = p.name
   and
   s.address = p.address
   and
   d.table_name = seg.segment_name
   and
   seg.owner = p.owner
having
   sum(s.executions) > 9
group by
   p.owner, d.table_name, p.name, seg.blocks
order by
   sum(s.executions) desc;
 
ttitle 'Index range scans and counts'
select
   p.owner,
   d.table_name,
   p.name index_name,
   seg.blocks tbl_blocks,
   sum(s.executions) nbr_scans
from
   dba_segments seg,
   v$sqlarea s,
   dba_indexes d,
  (select distinct
     address, 
     object_owner owner,
     object_name name
   from
      v$sql_plan
   where
      operation = 'INDEX'
      and
      options = 'RANGE SCAN') p
where
   d.index_name = p.name
   and
   s.address = p.address
   and
   d.table_name = seg.segment_name
   and
   seg.owner = p.owner
having
   sum(s.executions) > 9
group by
   p.owner, d.table_name, p.name, seg.blocks
order by
   sum(s.executions) desc;
 
 
ttitle 'Index unique scans and counts'
select 
   p.owner, 
   d.table_name, 
   p.name index_name, 
   sum(s.executions) nbr_scans
from 
   v$sqlarea s,
   dba_indexes d,
  (select distinct 
     address, 
     object_owner owner, 
     object_name name
   from 
      v$sql_plan
   where 
      operation = 'INDEX'
      and
      options = 'UNIQUE SCAN') p
where 
   d.index_name = p.name
   and
   s.address = p.address
having
   sum(s.executions) > 9
group by 
   p.owner, d.table_name, p.name
order by 
   sum(s.executions) desc;
spool off
select
   'alter table '||p.owner||'.'||p.name||' storage (buffer_pool keep);'
from
   dba_tables t,
   dba_segments s,
   dba_hist_sqlstat a,
   (select distinct
     pl.sql_id,
     pl.object_owner owner,
     pl.object_name name
   from
      dba_hist_sql_plan pl
   where
      pl.operation = 'TABLE ACCESS'
      and
      pl.options = 'FULL') p
where
   a.sql_id = p.sql_id
   and
   t.owner = s.owner
   and
   t.table_name = s.segment_name
   and
   t.table_name = p.name
   and
   t.owner = p.owner
   and
   t.owner not in ('SYS','SYSTEM', 'SYSMAN','DBSNMP')
   and
   t.buffer_pool <> 'KEEP'
having
   s.blocks < 50
group by
   p.owner, p.name, t.num_rows, s.blocks
UNION
-- ***********************************************************
-- Next, get the index names
-- ***********************************************************
select
   'alter index '||owner||'.'||index_name||' storage (buffer_pool keep);'
from
   dba_indexes 
where
   owner||'.'||table_name in
(
select
   p.owner||'.'||p.name
from
   dba_tables        t,
   dba_segments      s,
   dba_hist_sqlstat    a,
   (select distinct
     pl.sql_id,
     pl.object_owner owner,
     pl.object_name name
   from
      dba_hist_sql_plan pl
   where
      pl.operation = 'TABLE ACCESS'
      and
      pl.options = 'FULL') p
where
   a.sql_id = p.sql_id
   and
   t.owner = s.owner
   and
   t.table_name = s.segment_name
   and
   t.table_name = p.name
   and
   t.owner = p.owner
   and
   t.owner not in ('SYS','SYSTEM', 'SYSMAN','DBSNMP')
   and
   t.buffer_pool <> 'KEEP'
having
   s.blocks < 50
group by
   p.owner, p.name, t.num_rows, s.blocks
)

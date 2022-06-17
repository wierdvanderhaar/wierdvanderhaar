select usedidx.index_name, round((a.bytes/1024/1024/1024),1) from
(select segment_name, bytes from dba_segments where segment_type='INDEX') a,
(select distinct b.index_name 
from 	dba_hist_sql_plan a, 
	dba_indexes b 
where 	a.object_owner='QS_DWH' 
and 	a.object_name=b.index_name 
order by 1) usedidx
where usedidx.index_name = a.segment_name
order by 2;


select table_owner, table_name, PARTITION_NAME, updates,deletes, inserts from   dba_tab_modifications
where table_name='C_CONSUMER_SALES'
order by PARTITION_NAME
/
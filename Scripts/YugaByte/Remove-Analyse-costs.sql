-- allow DDL on catalog
set yb_non_ddl_txn_for_sys_tables_allowed=on;
-- column statistics
delete from pg_statistic  
where starelid in (
select c.oid from pg_class c 
join pg_namespace n on n.oid = c.relnamespace
and relnamespace in 
(select oid from pg_namespace where nspname='ehr')
);
-- table statistics
update pg_class set reltuples=0 where relnamespace in 
(select oid from pg_namespace where nspname='ehr');
-- set back to default setting
set yb_non_ddl_txn_for_sys_tables_allowed=off;
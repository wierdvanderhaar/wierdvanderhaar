EMREP Maintenance
-- Kijken wat de hoeveelheden zijn VOOR de maintenance
select table_name,partitioning_type type, partition_count count, subpartitioning_type subtype from dba_part_tables 
where table_name='MGMT_METRICS_RAW';
select table_name,partitioning_type type, partition_count count, subpartitioning_type subtype from dba_part_tables 
where table_name='MGMT_METRICS_1HOUR'; 
select table_name,partitioning_type type, partition_count count, subpartitioning_type subtype from dba_part_tables 
where table_name='MGMT_METRICS_1DAY'; 


connect / as sysdba
alter system set job_queue_processes = 0;
connect sysman/<password>
exec emd_maintenance.remove_em_dbms_jobs;
exec emd_maintenance.partition_maintenance;
exec emd_maintenance.analyze_emd_schema('SYSMAN')
exec emd_maint_util.partition_maintenance
@C:\oracle\product\10.2.0\oms10g\sysman\admin\emdrep\sql\core\latest\admin\admin_recompile_invalid.sql SYSMAN
alter system set job_queue_processes = 10;
exec emd_maintenance.submit_em_dbms_jobs;


-- Kijken wat de hoeveelheden zijn NA de maintenance
select table_name,partitioning_type type, partition_count count, subpartitioning_type subtype from dba_part_tables 
where table_name='MGMT_METRICS_RAW';
select table_name,partitioning_type type, partition_count count, subpartitioning_type subtype from dba_part_tables 
where table_name='MGMT_METRICS_1HOUR'; 
select table_name,partitioning_type type, partition_count count, subpartitioning_type subtype from dba_part_tables 
where table_name='MGMT_METRICS_1DAY'; 
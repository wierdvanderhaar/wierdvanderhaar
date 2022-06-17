set lines 200
set pages 1000
set echo off
select database_name from v$database;
SELECT a.value||'_'||b.VALUE||'.'||c.VALUE FROM (select VALUE from nls_database_parameters where parameter = 'NLS_LANGUAGE') a, (select VALUE from nls_database_parameters where parameter = 'NLS_TERRITORY') b,(select VALUE from nls_database_parameters where parameter = 'NLS_CHARACTERSET') c;
select comp_name from dba_registry;
select name, DETECTED_USAGES, TOTAL_SAMPLES, CURRENTLY_USED from dba_feature_usage_statistics where DETECTED_USAGES <> 0 order by 1;
select 'create tablespace ' || 
		tablespace_name || 
		' datafile ' || 
		''''  || 
		lower(file_name) || 
		'''' || 
		' size ' || 
		round((sum(bytes/1024/1024)),0) || 
		'M autoextend on next 100M maxsize UNLIMITED extent management local segment space management auto;' 
from 	dba_data_files 
where	tablespace_name not in ('SYSTEM','UNDOTBS1','SYSAUX')
group 	by tablespace_name, file_name, bytes
order by tablespace_name;
/* Blok voor naar ASM.  
select 'create tablespace ' ||
		tablespace_name ||
		' datafile ' ||
		''''  ||
		'+DATA' ||
		'''' ||
		' size ' ||
		round((sum(bytes/1024/1024)),0) ||
		'M autoextend on next 100M maxsize UNLIMITED extent management local segment space management auto;'
from 	dba_data_files
where	tablespace_name not in ('SYSTEM','UNDOTBS1','SYSAUX')
group 	by tablespace_name
order by tablespace_name;
*/
select 'alter system set ' || name || '=' || value || ' scope=spfile;' from v$parameter where name in ('pga_aggregate_target','optimizer_index_caching','optimizer_index_cost_adj','cursor_sharing','open_cursors')
union
select 'alter system set nls_length_semantics=' || '''' || value || ''''|| ' scope=spfile;' from v$parameter where name = 'nls_length_semantics'
union
select 'alter system set sga_max_size=' || round(value/1024/1024,0) || 'M scope=spfile;' from v$parameter where name = 'sga_max_size'
union
select 'alter system set sga_target=' || round(value/1024/1024,0) || 'M scope=spfile;' from v$parameter where name = 'sga_max_size';
select * from  dba_db_links;
select owner, count(*) from dba_objects where status <> 'VALID' group by owner;

-- Queues
select 'exec DBMS_AQADM.START_QUEUE(queue_name => ' || '''' || owner || '.' || name || '''' || ');' from dba_queues 
where owner not in ('SYSTEM','WMSYS','SYS') 
and QUEUE_TYPE = 'NORMAL_QUEUE';

SYS privs
select 'grant ' || PRIVILEGE || ' on ' || grantor || '."' ||TABLE_NAME || '" to ' || GRANTEE || ';' 
from ALL_TAB_PRIVS_MADE 
where grantor = 'SYS'
and grantee not in ('PUBLIC','SYSTEM','WKSYS','OWF_MGR') 
and grantee not like '%SYS' 
and grantee not like '%ROLE'
and grantee not like '%DATABASE'
and grantee not like '%STATISTICS'
and grantee not like 'ORACLE%';


select 'grant ' || PRIVILEGE || ' on ' || grantor || '."' ||TABLE_NAME || '" to ' || GRANTEE || ';' 
from ALL_TAB_PRIVS_MADE
where  grantee  = 'NGM1';



select 'grant ' || PRIVILEGE || ' on ' || grantor || '."' ||TABLE_NAME || '" to ' || GRANTEE || ';' 
from ALL_TAB_PRIVS_MADE 
where grantor = 'SYS'
and grantee = 'DBANL';
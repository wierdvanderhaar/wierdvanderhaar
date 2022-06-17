@?/pdb3

----------------------------------------------------------------------------------------------------
-- Bestandsnaam:	dbconfig_html.sql	
-- Doel:			    Dit script verzamelt database informatie wat gebruikt kan worden voor het aanmaken van 
--								nieuwe database.
--				        
-- Parameters:		-
-- Gebruik:			@dbconfig_html.sql
-- Auteur:			  Henk Nap
-- Historie:			08-02-2016  H. Nap       1e versie 
--                17-02-2016  H. Nap       Max. size van TEMP tablespace(s).
--                24-02-2016  H. Nap       Total size of database add, formatting improved.
--                17-03-2016  H. Nap       FRA info added, Directory info added, AMM calculation added if AMM isn't used yet.
--                18-09-2019  H. Nap       DB_USERS.PASSWORD_VERSIONS 10G controle toegevoegd.
-------------------------------------------------------------------------------------------------------


-- aanmaken string tbv bestandsnaam html
set termout off
column filename new_value logfile
select 'DBINFO_'||upper(instance_name)||'_'||upper(host_name)||'.html' filename 
from v$instance;
set termout on
set feedback off


-------------------------------------------------------------------------------
--  Uitvoeren controle en voorbereidende werkzaamheden
-------------------------------------------------------------------------------
prompt Creating html...
set termout off

-- logfile voorbereiden met de benodigde html-tags
set markup html on spool on -
  preformat off entmap on -
  head "<title>Configuratie DB tbv export / import</title> <style type='text/css'> body {font:10pt Arial,Helvetica,sans-serif; color:black; background:White;} p {font:10pt Arial,Helvetica,sans-serif; color:black; background:White;} table,tr,td {font:10pt Arial,Helvetica,sans-serif; color:Black; background:#f7f7e7; padding:0px 0px 0px 0px; margin:0px 0px 0px 0px;} th {font:bold 10pt Arial,Helvetica,sans-serif; color:#336699; background:#cccc99; padding:0px 0px 0px 0px;} h1 {font:16pt Arial,Helvetica,Geneva,sans-serif; color:#336699; background-color:White; border-bottom:1px solid #cccc99; margin-top:0pt; margin-bottom:0pt; padding:0px 0px 0px 0px;} h2 {font:bold 10pt Arial,Helvetica,Geneva,sans-serif; color:#336699; background-color:White; margin-top:4pt; margin-bottom:0pt;} a {font:9pt Arial,Helvetica,sans-serif; color:#663300; background:#ffffff; margin-top:0pt; margin-bottom:0pt; vertical-align:top;}</style>"
spool '&logfile'
set markup html off

-------------------------------------------------------------------------------
--  Rapportage aanmaken
-------------------------------------------------------------------------------
--
-- Pagina Header
--
set heading off 
select '<H1 align=center>'||upper(instance_name)||'</H1>'
from v$instance;

-- Database name and domain
select '<H5>Database name and domain</H5>'
from dual;

set markup html on table "width=auto border=1"
set heading on

select name, value from v$parameter where name = 'db_name'
union all
select name, value from v$parameter where name = 'db_unique_name'
union all
select name, value from v$parameter where name = 'instance_name'
union all
select name, value from v$parameter where name = 'db_domain';

set heading off
set markup html off

-- Database versie en editie
select '<H5>Database versie en editie</H5>'
from dual;


set markup html on table "width=auto border=1"
set heading on
select banner
from v$version;

set heading off
set markup html off


-- Characterset informatie
select '<H5>Characterset informatie</H5>'
from dual;

set markup html on table "width=auto border=1"
set heading on
select Parameter "Parameter", Value "Value" 
from nls_database_parameters 
where parameter in ('NLS_CHARACTERSET','NLS_NCHAR_CHARACTERSET','NLS_TERRITORY','NLS_LANGUAGE');

set heading off
set markup html off


select '<H5>Componenten</H5>'
from dual;


set markup html on table "width=auto border=1"
set heading on
select comp_name "Component", version "Versie", status "Status"
from dba_registry;

set heading off
set markup html off

-- Tablespace max size en current size
select '<H5>Tablespace max size en current size</H5>'
from dual;

set markup html on table "width=auto border=1"
set heading on

select a.tablespace_name "Tablespace name",
       a.bytes_alloc/(1024*1024) "TOTAL ALLOC (MB)",
       a.physical_bytes/(1024*1024) "TOTAL PHYS ALLOC (MB)",
       nvl(b.tot_used,0)/(1024*1024) "USED (MB)",
       (nvl(b.tot_used,0)/a.bytes_alloc)*100 "% USED"
from ( select tablespace_name,
       sum(bytes) physical_bytes,
       sum(decode(autoextensible,'NO',bytes,'YES',maxbytes)) bytes_alloc
       from dba_data_files
       group by tablespace_name ) a,
     ( select tablespace_name, sum(bytes) tot_used
       from dba_segments
       group by tablespace_name ) b
where a.tablespace_name = b.tablespace_name (+)
and   a.tablespace_name not in (select distinct tablespace_name from dba_temp_files)
and   a.tablespace_name not like 'UNDO%'
order by 1;

set heading off
set markup html off

-- Temp tablespace max size en current size
select '<H5>Temp tablespace max size en current size</H5>'
from dual;

set markup html on table "width=auto border=1"
set heading on

SELECT   A.tablespace_name as "Tablespace name", D.mb_total as "MB Total",
         SUM (A.used_blocks * D.block_size) / 1024 / 1024  as "MB Used",
         d.mb_total - SUM (A.used_blocks * D.block_size) / 1024 / 1024 as "MB Free",
         T.mb_max as "MB Max Size", T.Files as "Files"
FROM     v$sort_segment A, 
         (
         SELECT   B.name, C.block_size, SUM (C.bytes) / 1024 / 1024 mb_total
         FROM     v$tablespace B, v$tempfile C
         WHERE    B.ts#= C.ts#
         GROUP BY B.name, C.block_size
         ) D, 
         (
         SELECT tablespace_name, count(1) Files, round(sum(maxbytes)/1024/1024) mb_max from dba_temp_files 
         group by tablespace_name
         ) T
WHERE    A.tablespace_name = D.name
         and A.tablespace_name=T.tablespace_name
GROUP by A.tablespace_name, D.mb_total, T.mb_max, T.Files;

REM Total DB size
select round(sum(bytes)/1024/1024/1024 , 1) "DB size in GB"
from dba_data_files;

set heading off
set markup html off

-- FRA info
select '<H5>FRA info</H5>'
from dual;

set markup html on table "width=auto border=1"
set heading on

select name, round(space_limit/1024/1024) "Space limit", round(space_used/1024/1024) "Space used", round(space_reclaimable/1024/1024) "Reclaimable" from v$recovery_file_dest;

set heading off
set markup html off

-- Redo log informatie
select '<H5>Redo log informatie</H5>'
from dual;

set markup html on table "width=auto border=1"
set heading on
archive log list;

select a.group# as "Group", a.member as "Member", b.bytes/1024/1024 as "Size" from v$logfile a, v$log b where a.group#=b.group#;

set heading off
set markup html off

-- Algemene parameter instellingen
select '<H5>Parameters</H5>'
from dual;

set markup html on table "width=auto border=1"
set heading on

select name, to_char(value/1024/1024) "Setting" from v$parameter where name = 'memory_max_target'
union all
select name, to_char(value/1024/1024) from v$parameter where name = 'memory_target'
union all
select name, to_char(value/1024/1024) from v$parameter where name = 'pga_aggregate_target'
union all
select name, to_char(value/1024/1024) from v$parameter where name = 'sga_max_size'
union all
select name, to_char(value/1024/1024) from v$parameter where name = 'sga_target'
union all
select name, value from v$parameter where name = 'db_block_size'
union all
select name, value from v$parameter where name = 'processes'
union all
select name, value from v$parameter where name = 'db_recovery_file_dest'
union all
select name, value from v$parameter where name = 'control_management_pack_access'
union all
select name, value from v$parameter where name = 'optimizer_index_caching'
union all
select name, value from v$parameter where name = 'optimizer_index_cost_adj'
union all
select name, value from v$parameter where name = 'cursor_sharing'
union all
select name, value from v$parameter where name = 'open_cursors'
union all
select name, value from v$parameter where name = 'nls_length_semantics'
union all
select name, value from v$parameter where name = 'audit_trail';

set heading off
set markup html off

-- Bepalen memory_target parameter als deze nog niet gebruikt wordt.

set serveroutput on

declare
memory_target_current number;
memory_target_new number;
BEGIN
select value into memory_target_current from v$spparameter where name = 'memory_target'; 
if memory_target_current is null
then
select round((select max(round(value/1024/1024)) from v$pgastat where name in ('maximum PGA allocated','aggregate PGA target parameter')) + (select bytes/1024/1024 from v$sgainfo where name = 'Maximum SGA Size')) into memory_target_new  from dual;
dbms_output.put_line('AMM nog niet in gebruik, aanbevolen setting: <B>' || memory_target_new || '</B>');
end if;
end;
/
set serveroutput off

-- Non default parameters
select '<H5>Non default parameters</H5>'
from dual;

set markup html on table "width=auto border=1"
set heading on

select name,VALUE,ISDEFAULT,ISMODIFIED from v$parameter where ISMODIFIED = 'SYSTEM_MOD';

set heading off
set markup html off

-- Password life time settings
select '<H5>Password life time</H5>'
from dual;

set markup html on table "width=auto border=1"
set heading on

select Profile, limit from dba_profiles where resource_name = 'PASSWORD_LIFE_TIME';

set heading off
set markup html off

-- Aantal invalid objects
select '<H5>Invalid objects</H5>'
from dual;
set markup html on table "width=auto border=1"
set heading on

select owner , count(*) "Aantal" from dba_objects where status <> 'VALID' group by owner;

set heading off
set markup html off

-- Overzicht databaselinks
select '<H5>Database links</H5>'
from dual;

set markup html on table "width=auto border=1"
set heading on

select * from  dba_db_links;

set heading off
set markup html off

-- Overzicht database directory's
select '<H5>Database directories</H5>'
from dual;

set markup html on table "width=auto border=1"
set heading on

select * from dba_directories where directory_name not in ('MEDIA_DIR', 'ORACLE_OCM_CONFIG_DIR', 'ORACLE_OCM_CONFIG_DIR2', 'XMLDIR');

set heading off
set markup html off

-- DDL tablespaces
select '<H5>DDL Tablespaces</H5>'
from dual;

set markup html on table "width=auto border=1"
set heading on

select 'create tablespace ' || 
		tablespace_name || 
		' datafile ' || 
		''''  || 
		lower(file_name) || 
		'''' || 
		' size ' || 
		round((sum(bytes/1024/1024)),0) || 
		'M autoextend on next 100M maxsize UNLIMITED extent management local segment space management auto;' as "Create tablespace statements"
from 	dba_data_files 
where	tablespace_name not in ('SYSTEM','UNDOTBS1','SYSAUX', 'USERS')
group 	by tablespace_name, file_name, bytes
order by tablespace_name;

set heading off
set markup html off

-- DDL Oracle Streams Advanced Queuing (AQ) configuration
select '<H5>DDL Oracle Streams Advanced Queuing (AQ) configuration</H5>'
from dual;

set markup html on table "width=auto border=1"
set heading on

select 'exec DBMS_AQADM.START_QUEUE(queue_name => ' || '''' || owner || '.' || name || '''' || ');' "DDL Streams (AQ) config." from dba_queues 
where owner not in ('SYSTEM','WMSYS','SYS') 
and QUEUE_TYPE = 'NORMAL_QUEUE';

set heading off
set markup html off

-- DDL Oracle spfile paraneters
select '<H5>DDL Oracle spfile parameters</H5>'
from dual;

set markup html on table "width=auto border=1"
set heading on

select 'alter system set ' || name || '=' || value || ' scope=spfile;' "Alter statements" from v$parameter where name in ('pga_aggregate_target','optimizer_index_caching','optimizer_index_cost_adj','cursor_sharing','open_cursors','control_management_pack_access','processes') 
union
select 'alter system set nls_length_semantics=' || '''' || value || ''''|| ' scope=spfile;' from v$parameter where name in ('nls_length_semantics','db_recovery_file_dest')
union
select 'alter system set sga_max_size=' || round(value/1024/1024,0) || 'M scope=spfile;' from v$parameter where name = 'sga_max_size'
union
select 'alter system set sga_target=' || round(value/1024/1024,0) || 'M scope=spfile;' from v$parameter where name = 'sga_max_size'
union
select 'alter system set memory_max_target=' || round(value/1024/1024,0) || 'M scope=spfile;' from v$parameter where name = 'memory_max_target'
union
select 'alter system set memory_target=' || round(value/1024/1024,0) || 'M scope=spfile;' from v$parameter where name = 'memory_max_target'
;

set heading off
set markup html off

-- Overzicht van users met 10G Password policy
select '<H5>Overzicht van users met 10G Password policy</H5>'
from dual;

set markup html on table "width=auto border=1"
set heading on

SELECT USERNAME, PASSWORD_VERSIONS FROM DBA_USERS WHERE PASSWORD_VERSIONS LIKE '10G ';

set heading off
set markup html off

select 'Gebruik SQLNET.ALLOWED_LOGON_VERSION_CLIENT / SQLNET.ALLOWED_LOGON_VERSION_SERVER als er 10g users zijn of pas de wachtwoorden aan van desbetreffende users.' from dual;

-- Einde DBconfig.sql script
spool off
set termout on
prompt Html created.
prompt Returning to shell/batch script.
Exit 0


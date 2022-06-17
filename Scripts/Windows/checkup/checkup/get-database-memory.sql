connect / as sysdba
set term off
set feed off
column filename new_val filename
select to_char(sysdate, 'yyyymmdd_') || a.name || '_memory_in_use.log' filename from dual, v$database a;
spool &&filename append;
select round(sum(sga.sgasum+pga.pgasum),0) as "Geheugen Totaal" from
(SELECT sum(PGA_ALLOC_MEM/(1024*1024)) as pgasum FROM V$PROCESS) pga,
(select sum(value)/1024/1024 as sgasum from v$sga) sga;
spool off
exit

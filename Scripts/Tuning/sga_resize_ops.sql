rem
rem Script:     sga_resize_ops.sql
rem Author:     Jonathan Lewis
rem Dated:      December 2006
rem Purpose:    
rem
rem Last tested 
rem     11.2.0.4
rem     11.1.0.7
rem     10.2.0.3
rem Not tested
rem Not relevant
rem      9.2.0.8
rem      8.1.7.4
rem
rem Notes:
rem Quick and Dirty for 10g
rem SGA resizing operations
rem
rem Watch out for rapid fluctuations
rem
rem In 10.2 check also v$sgastat for  KGH: NO ACCESS 
rem which is memory in a shared pool (or other) granule
rem slowly being acquired by the db cache.
rem
rem Will have to write a new version for 11g which
rem uses v$memory_resize_ops to deal with PGA/SGA
rem interaction (and ASM) as well
rem
rem Look at v$sga_dynamic_components (and in 11g the 
rem equivalent v$memory_dynamic_components) for summary
rem view of granule sizes (which implies a future option
rem for varying granule sizes).
rem
rem See also: V$SGA_DYNAMIC_FREE_MEMORY (x$ksge)
 
start setenv
set timing off
 
column component format a25
column parameter format a30 
 
column initial_size format 99,999,999,999 
column target_size  format 99,999,999,999 
column final_size   format 99,999,999,999 
 
column started_at format a15
column ended_at   format a15
 
set linesize 90 
set pagesize 60 
 
spool sga_resize_ops 
 
prompt  ============
prompt  Full History
prompt  ============
 
select 
        component, 
        oper_type, 
        oper_mode, 
        parameter, 
        initial_size, 
        target_size, 
        final_size, 
        status, 
        to_char(start_time,'dd-mon hh24:mi:ss') started_at, 
        to_char(end_time,'dd-mon hh24:mi:ss')   ended_at 
from 
        v$sga_resize_ops 
where
    initial_size != 0
or  target_size  != 0
or  final_size   != 0
order by 
        start_time 
; 
 
prompt  ==============
prompt  Since midnight
prompt  ==============
 
set linesize 120
set pagesize 60
 
break on starting_time skip 1
 
column oper_type format     a12
column component format     a25
column parameter format     a22
column timed_at  format     a10
 
select
    to_char(start_time,'hh24:mi:ss') timed_at,
    oper_type,
    component,
    parameter,
    oper_mode,
    initial_size,
    final_size
from
    v$sga_resize_ops
where
    start_time > trunc(sysdate)
order by
    start_time, component
;
 
 
spool off
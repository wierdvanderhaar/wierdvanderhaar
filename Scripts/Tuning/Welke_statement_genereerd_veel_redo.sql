select inst_id, round((sum(value)/1024/1024),0) redo_MB from sys.gv_$sysstat where name = 'redo size' group by inst_id;  

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

col machine for a15  
col username for a10  
col redo_MB for 999990 heading "Redo |Size MB" 
column sid_serial for a13;  
select b.inst_id,   
       lpad((b.SID || ',' || lpad(b.serial#,5)),11) sid_serial,   
       b.username,   
       machine,   
       b.osuser,   
       b.status,   
       a.redo_mb    
from (select n.inst_id, sid,   
             round((value/1024/1024),0) redo_mb  
        from gv$statname n, gv$sesstat s  
        where n.inst_id=s.inst_id  
              and n.name = 'redo size' 
              and s.statistic# = n.statistic#  
        order by value desc 
     ) a,  
     gv$session b  
where b.inst_id=a.inst_id  
  and a.sid = b.sid  
and   rownum <= 30  
order by a.redo_mb;  
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Which segments

SELECT to_char(begin_interval_time,'YY-MM-DD HH24') snap_time,  
        dhso.object_name,  
        sum(db_block_changes_delta) BLOCK_CHANGED  
  FROM dba_hist_seg_stat dhss,  
      dba_hist_seg_stat_obj dhso,  
       dba_hist_snapshot dhs  
  WHERE dhs.snap_id = dhss.snap_id  
    AND dhs.instance_number = dhss.instance_number  
    AND dhss.obj# = dhso.obj#  
    AND dhss.dataobj# = dhso.dataobj#  
    AND begin_interval_time BETWEEN to_date('16-06-08 10:00','YY-MM-DD HH24:MI')   
                                AND to_date('16-06-08 11:00','YY-MM-DD HH24:MI')  
  GROUP BY to_char(begin_interval_time,'YY-MM-DD HH24'),  
           dhso.object_name  
  HAVING sum(db_block_changes_delta) > 0  
ORDER BY sum(db_block_changes_delta) asc ; 

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

SELECT to_char(begin_interval_time,'YYYY_MM_DD HH24') WHEN,  
       dbms_lob.substr(sql_text,4000,1) SQL,  
       dhss.instance_number INST_ID,  
       dhss.sql_id,  
       executions_delta exec_delta,  
       rows_processed_delta rows_proc_delta  
  FROM dba_hist_sqlstat dhss,  
       dba_hist_snapshot dhs,  
       dba_hist_sqltext dhst  
  WHERE upper(dhst.sql_text) LIKE '%PAGEKEYWORDBINDING%' 
    AND ltrim(upper(dhst.sql_text)) NOT LIKE 'SELECT%' 
    AND dhss.snap_id=dhs.snap_id  
    AND dhss.instance_number=dhs.instance_number  
    AND dhss.sql_id=dhst.sql_id   
    AND begin_interval_time BETWEEN to_date('11-11-22 13:00','YY-MM-DD HH24:MI')   
                                AND to_date('11-11-22 14:00','YY-MM-DD HH24:MI')  
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

SELECT when, sql, SUM(sx) executions, sum (sd) rows_processed  
FROM (  
      SELECT to_char(begin_interval_time,'YYYY_MM_DD HH24') when,  
             dbms_lob.substr(sql_text,4000,1) sql,  
             dhss.instance_number inst_id,  
             dhss.sql_id,  
             sum(executions_delta) exec_delta,  
             sum(rows_processed_delta) rows_proc_delta  
        FROM dba_hist_sqlstat dhss,  
             dba_hist_snapshot dhs,  
             dba_hist_sqltext dhst  
        WHERE upper(dhst.sql_text) LIKE '%Z_PLACENO%'  
          AND ltrim(upper(dhst.sql_text)) NOT LIKE 'SELECT%' 
          AND dhss.snap_id=dhs.snap_id  
          AND dhss.instance_Number=dhs.instance_number  
          AND dhss.sql_id = dhst.sql_id   
          AND begin_interval_time BETWEEN to_date('11-01-25 14:00','YY-MM-DD HH24:MI')   
                                      AND to_date('11-01-25 15:00','YY-MM-DD HH24:MI')  
        GROUP BY to_char(begin_interval_time,'YYYY_MM_DD HH24'),  
             dbms_lob.substr(sql_text,4000,1),  
             dhss.instance_number,  
             dhss.sql_id  
)  
group by when, sql; 

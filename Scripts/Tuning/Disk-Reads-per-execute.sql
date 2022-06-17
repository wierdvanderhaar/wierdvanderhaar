set linesize 200
col sql_text for a80
SELECT cast(disk_reads/(executions+1) as integer) as reads_per_exec
       , disk_reads
       , executions
       , sql_text
  FROM V$SQLAREA
  WHERE disk_reads/(executions+1) > 1
  AND executions > 1
  AND ROWNUM<=10
  ORDER BY disk_reads/(executions+1) desc;
SET PAUSE ON
SET PAUSE 'Press Return to Continue'
SET PAGESIZE 60
SET LINESIZE 300
 
COLUMN sql_text FORMAT A120
COLUMN sql_id FORMAT A13
COLUMN bind_name FORMAT A10
COLUMN bind_value FORMAT A26
 
SELECT 
  sql_id,
  t.sql_text sql_text,  
  b.name bind_name,
  b.value_string bind_value 
FROM
  v$sql t 
JOIN
  v$sql_bind_capture b  using (sql_id)
WHERE
  b.value_string is not null  
AND
  sql_id='&sqlid'
/
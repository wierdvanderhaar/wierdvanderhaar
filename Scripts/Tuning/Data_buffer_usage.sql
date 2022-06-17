column object_name format a40
column number_of_blocks format 999,999,999,999

column object_name      format a40
column number_of_blocks format 999,999,999,999
 
SELECT 
   o.object_name, 
   COUNT(1) number_of_blocks
FROM 
   DBA_OBJECTS o, 
   V$BH bh
WHERE 
   o.object_id  = bh.objd
AND 
   o.owner != 'SYS'
GROUP BY 
   o.object_name
ORDER BY 
   count(1) asc;

select b.* from v$sqlarea a ,table(version_rpt(null,a.hash_value)) b where loaded_versions>=100;
SELECT address, hash_value, version_count ,users_opening ,users_executing,substr(sql_text,1,40) "SQL" FROM v$sqlarea WHERE version_count > 10;

SELECT substr(sql_text,1,40) "Stmt", count(*),
       sum(sharable_mem)    "Mem",
       sum(users_opening)   "Open",
       sum(executions)      "Exec"
FROM 	v$sql
GROUP BY substr(sql_text,1,40)
HAVING sum(sharable_mem) > &memsize;
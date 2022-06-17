SELECT name,value,unit,time_computed,to_char(sysdate,'DD-MON-YY HH24:MI:SS') current_time
from v$dataguard_stats where name like '%lag';
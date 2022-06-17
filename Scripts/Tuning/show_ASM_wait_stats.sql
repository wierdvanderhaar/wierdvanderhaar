select EVENT, TOTAL_WAITS t_wait, TOTAL_TIMEOUTS t_timeout,
       TIME_WAITED t_waittm, AVERAGE_WAIT a_waittm,
       WAIT_CLASS
from v$system_event
where WAIT_CLASS <> 'Idle'
and   TIME_WAITED > 0
order by 4 desc;
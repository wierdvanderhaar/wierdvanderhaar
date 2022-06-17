select child_number,executions,parse_calls,loads,invalidations
from v$sql where sql_id = '--';

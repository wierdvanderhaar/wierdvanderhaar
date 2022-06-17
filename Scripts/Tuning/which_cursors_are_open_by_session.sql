select c.user_name, c.sid, sql.sql_text
from v$open_cursor c, v$sql sql
where c.sql_id=sql.sql_id  -- for 9i and earlier use: c.address=sql.address
and c.sid=&sid
;
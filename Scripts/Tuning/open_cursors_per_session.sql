select a.value, s.username, s.sid, s.serial#
from v$sesstat a, v$statname b, v$session s
where a.statistic# = b.statistic#  and s.sid=a.sid
and b.name = 'opened cursors current'
order by 1;

--totaal opened --
select sum(a.value) from v$sesstat a, v$statname b, v$session s
where a.statistic# = b.statistic#  and s.sid=a.sid
and b.name = 'opened cursors current'
order by 1;  2    3    4



select a.value, s.username, s.sid, s.serial#
from v$sesstat a, v$statname b, v$session s
where a.statistic# = b.statistic#  and s.sid=a.sid
and b.name = 'session cursor cache count' 
order by 1;

select cach.value cache_hits, prs.value all_parses, 
prs.value-cach.value sess_cur_cache_not_used
from v$sesstat cach, v$sesstat prs, v$statname nm1, v$statname nm2
where cach.statistic# = nm1.statistic#  
and nm1.name = 'session cursor cache hits' 
and prs.statistic#=nm2.statistic#
and nm2.name= 'parse count (total)'
and cach.sid= &sid and prs.sid= cach.sid ;


select
  'session_cached_cursors'  parameter,
  lpad(value, 5)  value,
  decode(value, 0, '  n/a', to_char(100 * used / value, '990') || '%')  usage
from
  ( select
      max(s.value)  used
    from
      v$statname  n,
      v$sesstat  s
    where
      n.name = 'session cursor cache count' and
      s.statistic# = n.statistic#
  ),
  ( select
      value
    from
      v$parameter
    where
      name = 'session_cached_cursors'
  )
union all
select
  'open_cursors',
  lpad(value, 5),
  to_char(100 * used / value,  '990') || '%'
from
  ( select
      max(sum(s.value))  used
    from
      v$statname  n,
      v$sesstat  s
    where
      n.name in ('opened cursors current', 'session cursor cache count') and
      s.statistic# = n.statistic#
    group by
      s.sid
  ),
  ( select
      value
    from
      v$parameter
    where
      name = 'open_cursors'
  )
/
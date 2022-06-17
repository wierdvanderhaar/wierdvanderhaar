-- Execute als user.sql <schema> <outputfile.sql>
-- @user.sql DBANL DBANL.sql

whenever sqlerror   exit failure rollback

set echo            off
set heading         off
set newpage         0
set termout         off
set feedback        off
set linesize        256
set pagesize        0
set pause           off
set verify          off
set time            off
set wrap            on
set long            10000
set longc           10000

ttitle              off
btitle              off

clear               column
clear               break
clear               compute

column              c1  noprint                             new_value user

select              decode('&1',
                           '','%',
                           '&1')                            c1
from                sys.dual
;

column              c1  noprint                             new_value spoolfile

select              decode('&2',
                           '','user.sql',
                           '&2')                            c1
from                sys.dual
;
define Exclusers="'SYS','SYSTEM','DBSNMP','OUTLN','CIOBADM','PERFSTAT'"

spool               &spoolfile

Rem column              c1  noprint                             format A30
Rem column              c2  noprint                             format A03

select              'drop user ' || username || ' cascade;'||chr(10)
from                sys.dba_users
where               username like upper('&user')
and                 username not in (&Exclusers)
;

select DBMS_METADATA.GET_DDL('USER', upper ('&user') ) || ';' from dual where upper('&user') not in (&Exclusers);


column              c1  noprint                             format A30
column              c2  noprint                             format A30
column              c3  noprint                             format A03

select              username                                c1
,                   tablespace_name                         c2
,                   '01'                                    c3
,                   ' '
from                sys.dba_ts_quotas
where               username like upper('&user')
and                 username not in (&Exclusers)
union all
select              username
,                   tablespace_name
,                   '02'
,                   'alter user          '||
                    lower(username)
from                sys.dba_ts_quotas
where               username like upper('&user')
and                 username not in (&Exclusers)
union all
select              username
,                   tablespace_name
,                   '03'
,                   'quota               unlimited'
from                sys.dba_ts_quotas
where               username like upper('&user')
and                 username not in (&Exclusers)
and                 max_bytes = -1
union all
select              username
,                   tablespace_name
,                   '03'
,                   'quota               '||
                    max_bytes
from                sys.dba_ts_quotas
where               username like upper('&user')
and                 username not in (&Exclusers)
and                 max_bytes > -1
and                 max_bytes < 1024
union all
select              username
,                   tablespace_name
,                   '03'
,                   'quota               '||
                    max_bytes/1024||
                    'K'
from                sys.dba_ts_quotas
where               username like upper('&user')
and                 username not in (&Exclusers)
and                 max_bytes >= 1024
union all
select              username
,                   tablespace_name
,                   '04'
,                   'on                  '||
                    lower(tablespace_name)
from                sys.dba_ts_quotas
where               username like upper('&user')
and                 username not in (&Exclusers)
and                 max_bytes >= -1
union all
select              username
,                   tablespace_name
,                   '05'
,                   ';'
from                sys.dba_ts_quotas
where               username like upper('&user')
and                 username not in (&Exclusers)
and                 max_bytes >= -1
union all
select              username
,                   tablespace_name
,                   '06'
,                   ' '
from                sys.dba_ts_quotas
where               username like upper('&user')
and                 username not in (&Exclusers)
and                 max_bytes >= -1
order by            1
,                   2
,                   3
;

column              c1  noprint                             format A30
column              c2  noprint                             format A03
column              c3  noprint                             format A30

select              grantee                                 c1
,                   '01'                                    c2
,                   ' '                                     c3
,                   ' '
from                sys.dba_sys_privs                       p1
where               p1.grantee like upper('&user')
and                 p1.grantee not in (&Exclusers)
and                 privilege =
(
select              min(privilege)
from                sys.dba_sys_privs                       p2
where               p1.grantee = p2.grantee
)
union all
select              grantee
,                   '02'
,                   ' '
,                   'grant               '||
                    lower(p1.privilege)
from                sys.dba_sys_privs                       p1
where               p1.grantee like upper('&user')
and                 p1.grantee not in (&Exclusers)
and                 privilege =
(
select              min(privilege)
from                sys.dba_sys_privs                       p2
where               p1.grantee = p2.grantee
)
union all
select              grantee
,                   '03'
,                   p1.privilege
,                   ',                   '||
                    lower(p1.privilege)
from                sys.dba_sys_privs                       p1
where               p1.grantee like upper('&user')
and                 p1.grantee not in (&Exclusers)
and                 privilege >
(
select              min(privilege)
from                sys.dba_sys_privs                       p2
where               p1.grantee = p2.grantee
)
union all
select              grantee
,                   '04'
,                   ' '
,                   'to                  '||
                    lower(grantee)
from                sys.dba_sys_privs                       p1
where               p1.grantee like upper('&user')
and                 p1.grantee not in (&Exclusers)
and                 privilege =
(
select              min(privilege)
from                sys.dba_sys_privs                       p2
where               p1.grantee = p2.grantee
)
union all
select              grantee
,                   '05'
,                   ' '
,                   'with                admin option'
from                sys.dba_sys_privs                       p1
where               p1.grantee like upper('&user')
and                 p1.grantee not in (&Exclusers)
and                 admin_option = 'YES'
and                 privilege =
(
select              min(privilege)
from                sys.dba_sys_privs                       p2
where               p1.grantee = p2.grantee
)
union all
select              grantee
,                   '06'
,                   ' '
,                   ';'
from                sys.dba_sys_privs                       p1
where               p1.grantee like upper('&user')
and                 p1.grantee not in (&Exclusers)
and                 privilege =
(
select              min(privilege)
from                sys.dba_sys_privs                       p2
where               p1.grantee = p2.grantee
)
order by            1
,                   2
,                   3
;

column              c1  noprint                             format A30
column              c2  noprint                             format A30
column              c3  noprint                             format A03

select              grantee                                 c1
,                   granted_role                            c2
,                   '01'                                    c3
,                   ' '
from                sys.dba_role_privs
where               grantee like upper('&user')
and                 grantee not in (&Exclusers)
union all
select              grantee
,                   granted_role
,                   '02'
,                   'grant               '||
                    lower(granted_role)
from                sys.dba_role_privs
where               grantee like upper('&user')
and                 grantee not in (&Exclusers)
union all
select              grantee
,                   granted_role
,                   '03'
,                   'to                  '||
                    lower(grantee)
from                sys.dba_role_privs
where               grantee like upper('&user')
and                 grantee not in (&Exclusers)
union all
select              grantee
,                   granted_role
,                   '04'
,                   'with                admin option'
from                sys.dba_role_privs
where               grantee like upper('&user')
and                 grantee not in (&Exclusers)
and                 admin_option = 'YES'
union all
select              grantee
,                   granted_role
,                   '05'
,                   ';'
from                sys.dba_role_privs
where               grantee like upper('&user')
and                 grantee not in (&Exclusers)
order by            1
,                   2
,                   3
;

select              'exit' from dual
;

spool               off
/

exit

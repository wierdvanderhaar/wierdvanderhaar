Rem
Rem    Generate Database Links DDL
Rem
select 'connect b8/b8' from dual;
select 'create database link ' || a.name || chr(10) ||
       'connect to ' || a.userid || ' identified by ' || a.password || ' using ''' ||
       a.host || ''';'
from   sys.link$ a, dba_users b
where  a.owner#=b.user_id
and b.username = 'B8'
/
select 'connect bo6/bo6' from dual;
select 'create database link ' || a.name || chr(10) ||
       'connect to ' || a.userid || ' identified by ' || a.password || ' using ''' ||
       a.host || ''';'
from   sys.link$ a, dba_users b
where  a.owner#=b.user_id
and b.username = 'BO6'
/


-- roep dit script aan in sqlplus met als variable de username waarvan de userddl gegeneerd moet worden.
-- @generate_user_ddl.sql <USERNAME>
-- LET OP DAT IN HET GE_GENEREERDE BESTAND DE UITVOER TEKENS (/ of ;) ACHTER ELKE REGEL!!!
set head off
set pages 0
set long 9999999
spool create_user.sql
select dbms_metadata.get_ddl('USER', username) || '/' DDL
from dba_users where username = '&&1'
UNION ALL
SELECT DBMS_METADATA.GET_GRANTED_DDL('ROLE_GRANT', USERNAME) || '/' DDL
FROM DBA_USERS where username = '&&1'
UNION ALL
SELECT DBMS_METADATA.GET_GRANTED_DDL('SYSTEM_GRANT', USERNAME) || '/' DDL
FROM DBA_USERS where username = '&&1'
UNION ALL
SELECT DBMS_METADATA.GET_GRANTED_DDL('OBJECT_GRANT', USERNAME) || '/' DDL
FROM DBA_USERS where username = '&&1';
spool off
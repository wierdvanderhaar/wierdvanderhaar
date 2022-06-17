REM $Header: coe_create_user_coecbostats.sql 11.1 465787.1 2008/05/28 csierra $
--SET ECHO ON;
SPO COE_CREATE_USER_COECBOSTATS.TXT

WHENEVER SQLERROR EXIT SQL.SQLCODE;
BEGIN
  IF USER != 'SYS' THEN
    RAISE_APPLICATION_ERROR(-20100, 'Connect as SYS, not as '||USER);
  END IF;
END;
/
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ".,";

PRO Specify COECBOSTATS password
PRO &&coecbostats_password

BEGIN
  IF '&&coecbostats_password' IS NULL THEN
    RAISE_APPLICATION_ERROR(-20102, 'Install failed - No password specified for COECBOSTATS user');
  END IF;
END;
/
CREATE USER coecbostats IDENTIFIED BY &&coecbostats_password;

GRANT ALTER  SESSION                           TO coecbostats;
GRANT ANALYZE ANY                              TO coecbostats;
--GRANT ANALYZE ANY DICTIONARY                   TO coecbostats;
GRANT CREATE SESSION                           TO coecbostats;
GRANT CREATE TABLE                             TO coecbostats;
--GRANT CREATE JOB                               TO coecbostats;
GRANT SELECT_CATALOG_ROLE                      TO coecbostats;
GRANT EXECUTE_CATALOG_ROLE                     TO coecbostats;
GRANT GATHER_SYSTEM_STATISTICS                 TO coecbostats;

PRO
PRO Below are the list of online tablespaces in this database.
PRO Decide which tablespace you wish to create the COECBOSTATS table
PRO
PRO Specifying the SYSTEM tablespace will result in the installation
PRO FAILING, as using SYSTEM for tools data is not supported.
PRO wait...

SELECT t.tablespace_name,
       (SELECT NVL(ROUND(SUM(f.bytes)/1024/1024, 3), 0)
          FROM sys.dba_free_space f
         WHERE f.tablespace_name = t.tablespace_name) free_space_mb
  FROM sys.dba_tablespaces t
 WHERE t.tablespace_name <> 'SYSTEM'
   AND t.status = 'ONLINE'
   AND t.contents <> 'TEMPORARY'
 ORDER BY t.tablespace_name;

PRO
PRO Specify COECBOSTATS user's default tablespace
PRO Using &&default_tablespace for the default tablespace

BEGIN
  IF UPPER('&&default_tablespace') = 'SYSTEM' THEN
    RAISE_APPLICATION_ERROR(-20104, 'Install failed - SYSTEM tablespace specified for DEFAULT tablespace');
  END IF;
END;
/

ALTER USER coecbostats DEFAULT TABLESPACE &&default_tablespace;
ALTER USER coecbostats QUOTA UNLIMITED ON &&default_tablespace;

PRO
PRO Choose the COECBOSTATS user's temporary tablespace.
PRO
PRO Specifying the SYSTEM tablespace will result in the installation
PRO FAILING, as using SYSTEM for the temporary tablespace is not recommended.
PRO wait...

SET SERVEROUT ON SIZE 1000000
DECLARE
  TYPE cursor_type IS REF CURSOR;
  c_temp_table_spaces cursor_type;
  rdbms_release NUMBER;
  my_tablespace VARCHAR2(32767);
  my_sql VARCHAR2(32767);
BEGIN
  SELECT TO_NUMBER(SUBSTR(version, 1, INSTR(version, '.', 1, 2) - 1))
    INTO rdbms_release
    FROM v$instance;

  IF rdbms_release < 10 THEN
    my_sql := 'SELECT tablespace_name '||
              '  FROM sys.dba_tablespaces '||
              ' WHERE tablespace_name <> ''SYSTEM'' '||
              '   AND status = ''ONLINE'' '||
              '   AND contents = ''TEMPORARY'' '||
              ' ORDER BY tablespace_name ';
  ELSE
    my_sql := 'SELECT t.tablespace_name '||
              '  FROM sys.dba_tablespaces t '||
              ' WHERE t.tablespace_name <> ''SYSTEM'' '||
              '   AND t.status = ''ONLINE'' '||
              '   AND t.contents = ''TEMPORARY'' '||
              '   AND NOT EXISTS ( '||
              'SELECT NULL '||
              '  FROM sys.dba_tablespace_groups tg '||
              ' WHERE t.tablespace_name = tg.tablespace_name ) '||
              ' UNION '||
              'SELECT tg.group_name '||
              '  FROM sys.dba_tablespaces t, '||
              '       sys.dba_tablespace_groups tg '||
              ' WHERE t.tablespace_name <> ''SYSTEM'' '||
              '   AND t.status = ''ONLINE'' '||
              '   AND t.contents = ''TEMPORARY'' '||
              '   AND t.tablespace_name = tg.tablespace_name ';
  END IF;

  DBMS_OUTPUT.PUT_LINE('TABLESPACE_NAME');
  DBMS_OUTPUT.PUT_LINE('------------------------------');

  OPEN c_temp_table_spaces FOR my_sql;
  LOOP
    FETCH c_temp_table_spaces INTO my_tablespace;
    EXIT WHEN c_temp_table_spaces%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(my_tablespace);
  END LOOP;
END;
/

PRO
PRO Specify COECBOSTATS user's temporary tablespace.
PRO Using &&temporary_tablespace for the temporary tablespace
PRO

BEGIN
  IF UPPER('&&temporary_tablespace') = 'SYSTEM' THEN
    RAISE_APPLICATION_ERROR(-20105, 'Install failed - SYSTEM tablespace specified for TEMPORARY tablespace');
  END IF;
END;
/

ALTER USER coecbostats TEMPORARY TABLESPACE &&temporary_tablespace;

EXEC DBMS_STATS.CREATE_STAT_TABLE(ownname => 'COECBOSTATS', stattab => 'COE$_STATTAB');

WHENEVER SQLERROR CONTINUE;
SPOOL OFF;

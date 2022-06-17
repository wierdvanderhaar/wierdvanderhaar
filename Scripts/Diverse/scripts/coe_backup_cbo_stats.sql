REM $Header: coe_backup_cbo_stats.sql 11.1 465787.1 2008/05/28 csierra $
SET ECHO ON;
SPO COE_BACKUP_CBO_STATS.TXT
SET SERVEROUT ON SIZE 1000000;

WHENEVER SQLERROR EXIT SQL.SQLCODE;
BEGIN
  IF USER != 'SYS' THEN
    RAISE_APPLICATION_ERROR(-20100, 'Connect as SYS, not as '||USER);
  END IF;
END;
/
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ".,";

COL v_statid NOPRI NEW_V v_statid FOR A30;
SELECT 'COE'||TO_CHAR(SYSDATE, 'YYYYMMDDHH24MI') v_statid FROM DUAL;

DECLARE
  my_statid VARCHAR2(30) := '&&v_statid';
BEGIN
  DBMS_OUTPUT.PUT_LINE('*** STATID: '||my_statid);
  BEGIN
    DBMS_STATS.EXPORT_SYSTEM_STATS (
      stattab => 'COE$_STATTAB',
      statid  => my_statid||'SBK',
      statown => 'COECBOSTATS' );
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SUBSTR('*** SKIP export of SYSTEM_STATS: '||SQLERRM, 1, 255));
  END;
  DBMS_OUTPUT.PUT_LINE('*** '||TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI')||' Exported SYSTEM_STATS');
  FOR i IN (SELECT DISTINCT owner FROM dba_tables WHERE num_rows IS NOT NULL ORDER BY owner)
  LOOP
    DBMS_STATS.EXPORT_SCHEMA_STATS (
      ownname => i.owner,
      stattab => 'COE$_STATTAB',
      statid  => my_statid||'TBK',
      statown => 'COECBOSTATS' );
    DBMS_OUTPUT.PUT_LINE(TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI')||' Exported CBO Stats for: '||i.owner);
  END LOOP;
END;
/

WHENEVER SQLERROR CONTINUE;
DECLARE
  my_statid VARCHAR2(30) := '&&v_statid';
  rdbms_release NUMBER;
BEGIN
  SELECT TO_NUMBER(SUBSTR(version, 1, INSTR(version, '.', 1, 2) - 1))
    INTO rdbms_release
    FROM v$instance;

  IF rdbms_release >= 10 THEN
    DBMS_STATS.EXPORT_FIXED_OBJECTS_STATS (
      stattab => 'COE$_STATTAB',
      statid  => my_statid||'FOBK',
      statown => 'COECBOSTATS' );
    DBMS_OUTPUT.PUT_LINE('*** '||TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI')||' Exported FIXED_OBJECTS_STATS');
  END IF;
END;
/
PRO *** IGNORE THIS ERROR ON 9i: PLS-00302: component 'EXPORT_FIXED_OBJECTS_STATS' must be declared

SPO OFF;

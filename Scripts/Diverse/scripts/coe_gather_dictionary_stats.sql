REM $Header: coe_gather_dictionary_stats.sql 11.1 465787.1 2008/05/28 csierra $
SET ECHO ON;
SPO COE_GATHER_DICTIONARY_STATS.TXT
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
  rdbms_release NUMBER;

  PROCEDURE gather_schema_stats (
    p_ownname VARCHAR2 )
  IS
  BEGIN /* gather_schema_stats */
    DBMS_STATS.EXPORT_SCHEMA_STATS (
      ownname => p_ownname,
      stattab => 'COE$_STATTAB',
      statid  => my_statid||'DBEFORE',
      statown => 'COECBOSTATS' );
    DBMS_STATS.GATHER_SCHEMA_STATS (
      ownname          => p_ownname,
      estimate_percent => 100,
      method_opt       => 'FOR ALL COLUMNS SIZE 1',
      cascade          => TRUE,
      statid           => my_statid,
      options          => 'GATHER' );
    DBMS_STATS.EXPORT_SCHEMA_STATS (
      ownname => p_ownname,
      stattab => 'COE$_STATTAB',
      statid  => my_statid||'DAFTER',
      statown => 'COECBOSTATS' );
    DBMS_OUTPUT.PUT_LINE(TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI')||' Gathered CBO Stats for: '||p_ownname);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(SUBSTR('*** SKIP: '||p_ownname||' REASON: '||SQLERRM, 1, 255));
  END gather_schema_stats;

BEGIN
  SELECT TO_NUMBER(SUBSTR(version, 1, INSTR(version, '.', 1, 2) - 1))
    INTO rdbms_release
    FROM v$instance;

  IF rdbms_release < 10 THEN
    DBMS_OUTPUT.PUT_LINE('*** STATID: '||my_statid);
    gather_schema_stats('WMSYS');
    gather_schema_stats('MDSYS');
    gather_schema_stats('CTXSYS');
    gather_schema_stats('XDB');
    gather_schema_stats('WKSYS');
    gather_schema_stats('LBACSYS');
    gather_schema_stats('OLAPSYS');
    gather_schema_stats('DMSYS');
    gather_schema_stats('ODM');
    gather_schema_stats('ORDSYS');
    gather_schema_stats('ORDPLUGINS');
    gather_schema_stats('SI_INFORMTN_SCHEMA');
    gather_schema_stats('OUTLN');
    gather_schema_stats('DBSNMP');
    gather_schema_stats('SYSTEM');
    gather_schema_stats('SYS');
  END IF;
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
    DBMS_OUTPUT.PUT_LINE('*** STATID: '||my_statid);
    BEGIN
      DBMS_STATS.EXPORT_DICTIONARY_STATS (
        stattab => 'COE$_STATTAB',
        statid  => my_statid||'DBEFORE',
        statown => 'COECBOSTATS' );
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SUBSTR('*** SKIP export before gathering: '||SQLERRM, 1, 255));
    END;
    DBMS_STATS.GATHER_DICTIONARY_STATS (
      comp_id          => NULL,
      estimate_percent => 100,
      method_opt       => 'FOR ALL COLUMNS SIZE 1',
      cascade          => TRUE,
      statid           => my_statid,
      options          => 'GATHER' );
    DBMS_STATS.EXPORT_DICTIONARY_STATS (
      stattab => 'COE$_STATTAB',
      statid  => my_statid||'DAFTER',
      statown => 'COECBOSTATS' );
    DBMS_OUTPUT.PUT_LINE(TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI')||' Gathered CBO Stats for DICTIONARY');
  END IF;
END;
/
PRO *** IGNORE THIS ERROR ON 9i: PLS-00302: component 'EXPORT_DICTIONARY_STATS' must be declared

SPO OFF;

set heading on
set lines 300
set pages 1000
select 'SELECT ' || '''' || table_name || '.' || column_name || '''' || ' as OBJECT,' || 'MAX(DBMS_LOB.GETLENGTH(' || column_name || '))/1024 as "MaxlobLength in Kbytes", AVG(DBMS_LOB.GETLENGTH(' || column_name || '))/1024 as "AvgLobLength in Kbytes" from DEVVANESSA.' || table_name || ';' from dba_lobs where owner='&1';
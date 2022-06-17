# Draai dit script voordat er een migratie van single-byte naar double-byte wordt omgezet.
CREATE OR REPLACE PROCEDURE BYTE2CHAR (v_owner IN VARCHAR2) AS
-- declare
cursor cur1 is select owner, table_name, column_name, DATA_TYPE, DATA_LENGTH 
from dba_tab_columns 
where owner=v_owner
and data_type in ('VARCHAR2','CHAR');
collength number(5);
begin
for x in cur1 loop
EXECUTE IMMEDIATE 'alter session set nls_length_semantics=CHAR';
dbms_output.put_line(x.data_length);
collength := x.data_length;
dbms_output.put_line(collength);
EXECUTE IMMEDIATE 'alter table ' || x.owner || '.' || x.table_name || ' modify ( ' || x.column_name || ' ' || x.DATA_TYPE || '(' || collength || '))';  
collength := NULL;
end loop;
end;
/

-- Check welke  schema's byte columns hebben.
select owner,CHAR_USED, count(*)
from dba_tab_columns 
where owner like '%PLUS'
and data_type in ('VARCHAR2','CHAR')
group by owner,CHAR_USED order by 1,2;
# Draai dit script voordat er een migratie van single-byte naar double-byte wordt omgezet.
CREATE OR REPLACE PROCEDURE VRCHR2x2 (v_owner IN VARCHAR2) AS
-- declare
cursor cur1 is select owner, table_name, column_name, DATA_TYPE, DATA_LENGTH from dba_tab_columns where owner=v_owner and data_type='VARCHAR2';
collength number(5);
begin
for x in cur1 loop
dbms_output.put_line(x.data_length);
collength := x.data_length * 2;
dbms_output.put_line(collength);
-- EXECUTE IMMEDIATE 'alter table ' || x.owner || '.' || x.table_name || ' modify ( ' || x.column_name || ' ' || x.DATA_TYPE || '(' || collength || '))';  
collength := NULL;
end loop;
end;
/


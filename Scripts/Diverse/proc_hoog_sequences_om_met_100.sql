create or replace procedure update_sequences is
v_val number;
v_incr number;
cursor seq1 is select sequence_owner ownname, sequence_name seqname, increment_by incr, last_number lstnmbr from dba_sequences where sequence_owner='DEVVANESSA';
begin
for x in seq1 loop
v_val := 0;
v_incr := x.incr;
-- dbms_output.put_line('alter sequence ' || x.ownname || '.'  || x.seqname || ' increment by 100');
execute immediate 'alter sequence ' || x.ownname || '.'  || x.seqname || ' increment by 100' ;
-- dbms_output.put_line('select ' || x.ownname || '.' || x.seqname || '.nextval from dual');
execute immediate 'select ' || x.ownname || '.'  || x.seqname || '.nextval from dual' INTO v_val; 
dbms_output.put_line('alter sequence ' || x.ownname || '.'  || x.seqname || ' increment by ' || v_incr);
-- execute immediate 'alter sequence ' || x.ownname || '.'  || x.seqname || ' increment by ' || v_incr;
end loop;
end;
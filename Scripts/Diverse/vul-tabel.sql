create table test (c1 number(10), c2 date);

create or replace procedure vultabel is
begin
for x in 10 loop
insert into test values (x,sysdate);
commit;
end loop;
end;
/
SQL> select min(SNAP_TIME), max(SNAP_TIME) from stats$snapshot where snap_time < TRUNC(SYSDATE-28);

create or replace procedure SNAPPURGE (purgetime IN number default 28)
IS
losnapid number (5) :=0; 
hisnapid number (5) :=0; 
--purgetime number (3) := 28;
begin
statspack.snap(5);
dbms_output.put_line (purgetime);
select min(SNAP_ID), max(SNAP_ID) into losnapid, hisnapid from stats$snapshot where snap_time < TRUNC(SYSDATE-purgetime);
statspack.purge( i_begin_snap      => losnapid, i_end_snap        => hisnapid, i_snap_range      => true, i_extended_purge  => false);
exception
when others then
 null;
end;
/


create or replace procedure SNAPPURGE (purgetime IN number)
IS
-- Geef de aantal dagen waarna gepurged moet worden mee bij de aanroep van de procedure. Dus exec SNAPPURGE(28) als de snapshots na 28 dagen moeten worden gepurged. 
losnapid number (5) :=0; 
hisnapid number (5) :=0; 
begin
statspack.snap(5);
select min(SNAP_ID), max(SNAP_ID) into losnapid, hisnapid from stats$snapshot where snap_time <= TRUNC(SYSDATE-purgetime);
dbms_output.put_line(losnapid);
dbms_output.put_line(hisnapid);
if losnapid <> 0 then
statspack.purge( i_begin_snap  => losnapid, i_end_snap => hisnapid, i_snap_range => true, i_extended_purge  => false);
end if; 
end;
/


select min(SNAP_ID), max(SNAP_ID)  from stats$snapshot where snap_time >= TRUNC(SYSDATE-1);

declare
losnapid number (5) :=0; 
hisnapid number (5) :=0; 
begin
statspack.snap(5);
select min(SNAP_ID), max(SNAP_ID) into losnapid, hisnapid from stats$snapshot where snap_time >= TRUNC(SYSDATE-purgetime);
-- dbms_output.put_line(losnapid);
-- dbms_output.put_line(hisnapid);
if losnapid <> 0 then
statspack.purge( i_begin_snap  => losnapid, i_end_snap => hisnapid, i_snap_range => true, i_extended_purge  => false);
end if; 
end;
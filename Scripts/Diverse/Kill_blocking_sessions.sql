SELECT 'ALTER SYSTEM KILL SESSION ' || '''' || s.sid || ',' || s.serial# || '''' || 'IMMEDIATE;' AS ddl
FROM   gv$session s
WHERE  s.blocking_session IS NOT NULL
AND    s.username LIKE 'BVA%'


BEGIN
    FOR r IN (
        SELECT 'ALTER SYSTEM KILL SESSION ''' || s.sid || ',' || s.serial# || ''' IMMEDIATE' AS ddl
        FROM   v$session s
        AND    s.blocking_session IS NOT NULL
        AND    s.username LIKE 'TRAIN%'
    )
    LOOP
        DBMS_OUTPUT.PUT_LINE(r.ddl);
        EXECUTE IMMEDIATE r.ddl
    END LOOP;
END;


create or replace procedure dbanl.killsession (usrname IN VARCHAR2)
as
usrname varchar2(25);
BEGIN
    FOR r IN (
        SELECT 'ALTER SYSTEM KILL SESSION ''' || s.sid || ',' || s.serial# || ',@' || s.inst_id || ''' IMMEDIATE' AS ddl
        FROM   	gv$session s
        WHERE 	s.blocking_session IS NOT NULL
        AND    	s.username LIKE to_upper (usrname)
    )
    LOOP
        DBMS_OUTPUT.PUT_LINE(r.ddl);
        EXECUTE IMMEDIATE r.ddl;
    END LOOP;
EXCEPTION
WHEN NO_DATA_FOUND THEN
dbms_output.put_line('The SID ' || to_upper (usrname) || ' does not exist or cannot be killed');
END;
/
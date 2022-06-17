REM       GENERATES THE STATEMENTS TO CALCULATE AVERAGE ROW SIZE FOR ALL
REM   TABLES IN THE CURRENT SCHEMA
SET HEADING OFF
SET SERVEROUTPUT ON
ACCEPT filename PROMPT 'Enter the Path and File Name for the Script => '
PROMPT
PROMPT Generating script for calculating Average Row Size.....
SET TERMOUT OFF
SPOOL &&filename
DECLARE
 i INT;
 colid INT;
 maxcolid INT;
 tabname VARCHAR2(30);
 colname VARCHAR2(30);
 vsizestmt varchar2(1000);
 CURSOR tabs_cur IS SELECT table_name from user_tables;
 CURSOR cols_cur(tname VARCHAR2) IS SELECT column_name,column_id FROM
    user_tab_columns WHERE table_name=tname ORDER BY column_id;
BEGIN
 dbms_output.enable(1000000);
 dbms_output.put_line('SET SERVEROUTPUT ON');
 dbms_output.put_line('SET FEEDBACK OFF');
     OPEN tabs_cur;
         LOOP
           FETCH tabs_cur INTO tabname;
         EXIT WHEN tabs_cur%NOTFOUND;
         BEGIN
            SELECT MAX(column_id) INTO maxcolid FROM user_tab_columns WHERE
               table_name=tabname;
            OPEN cols_cur(tabname);
                vsizestmt:='SELECT ';
                dbms_output.put_line('REM Start '||tabname);
                dbms_output.put_line('REM *******************************************************');
                dbms_output.put_line('PROMPT Table: '||tabname);
                dbms_output.put_line(vsizestmt);
              LOOP
                FETCH cols_cur INTO colname,colid;
                EXIT WHEN cols_cur%NOTFOUND;
                  vsizestmt:='DECODE(AVG(VSIZE('||colname||')),NULL,0,AVG(VSIZE('||colname||')))'||'+';
                  IF colid < maxcolid  THEN
                        dbms_output.put_line(vsizestmt);
                ELSE
                BEGIN
                        dbms_output.put_line(substr(vsizestmt,1,(length(vsizestmt)-1)));
                END;
                END IF;
             END LOOP;
            CLOSE cols_cur;
                vsizestmt:='AVERAGE_ROW_SIZE FROM '||tabname||';';
                dbms_output.put_line(vsizestmt);
                dbms_output.put_line('REM End '||tabname);
                dbms_output.put_line('REM ******************************************************');
        END;
        END LOOP;
    CLOSE tabs_cur;
 dbms_output.put_line('SET HEADING ON');
 dbms_output.put_line('SET FEEDBACK ON');
 dbms_output.put_line('SET TERMOUT ON');
END;
/

SPOOL OFF
SET FEEDBACK ON
SET HEADING ON
SET TERMOUT ON
PROMPT
PROMPT Generated script &&filename
PROMPT Run the file &&filename to calculate Average Row Size
PROMPT
UNDEF filename
UNDEF tabname

-- Dit moet er nog worden ingeklust.
-- nvl(dbms_lob.getlength(
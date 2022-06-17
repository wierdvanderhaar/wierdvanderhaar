SET PAUSE on
SET PAUSE 'Press Return to Continue'
SET PAGESIZE 60
SET LINE 300
COLUMN COMPONENT for a26
COLUMN OPER_TYPE for a12
COLUMN OPER_MODE for a9
COLUMN PARAMETER for a30
COLUMN S_SIZ_MB for 999,999
COLUMN T_SIZ_MB for 999,999
COLUMN E_SIZ_MB for 999,999

SELECT
       COMPONENT,
       OPER_TYPE,
       OPER_MODE,
       PARAMETER,
       TO_CHAR(INITIAL_SIZE/1024/1024,'999,999') as S_SIZ_MB,
       TO_CHAR(TARGET_SIZE/1024/1024,'999,999') as T_SIZ_MB,
       TO_CHAR(FINAL_SIZE/1024/1024,'999,999') as E_SIZ_MB,
       STATUS,
       TO_CHAR(START_TIME,'DD-MON-YY HH24:MI:SS') as STIME,
       TO_CHAR(END_TIME,'DD-MON-YY HH24:MI:SS') as ETIME
     FROM
       V$SGA_RESIZE_OPS
/
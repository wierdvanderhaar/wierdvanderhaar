-- Vind tabellen en referende colums 
SELECT t.owner CHILD_OWNER,
  t.table_name CHILD_TABLE,
  t.constraint_name FOREIGN_KEY_NAME,
  r.owner PARENT_OWNER,
  r.table_name PARENT_TABLE,
  r.constraint_name PARENT_CONSTRAINT
FROM DBA_constraints t,
  DBA_constraints r
WHERE t.r_constraint_name = r.constraint_name
AND t.r_owner             = r.owner
AND t.constraint_type     ='R'
AND t.table_name          = 'SERVICELINEITEM';

-- Vind constraint die referenen aan een column van een bepaalde tabel.
SELECT t.owner CHILD_OWNER,
  t.table_name CHILD_TABLE,
  t.constraint_name FOREIGN_KEY_NAME,
  r.owner PARENT_OWNER,
  r.table_name PARENT_TABLE,
  r.constraint_name PARENT_CONSTRAINT
FROM DBA_constraints t,
  DBA_constraints r
WHERE t.r_constraint_name = r.constraint_name
AND t.r_owner             = r.owner
AND t.constraint_type     ='R'
AND r.table_name          = 'SERVICELINEITEM';



SELECT DECODE(c.status,'ENABLED','C','c') t,
  SUBSTR(c.constraint_name,1,31) relation,
  SUBSTR(cc.column_name,1,24) columnname,
  SUBSTR(p.table_name,1,20) tablename
FROM dba_cons_columns cc,
  dba_constraints p,
  dba_constraints c
WHERE c.owner          = upper('INTERSHOP')
AND c.table_name       = upper('PRODUCTLINEITEM')
AND c.constraint_type  = 'R'
AND p.owner            = c.r_owner
AND p.constraint_name  = c.r_constraint_name
AND cc.owner           = c.owner
AND cc.constraint_name = c.constraint_name
AND cc.table_name      = c.table_name
UNION ALL
SELECT DECODE(c.status,'ENABLED','P','p') t,
  SUBSTR(c.constraint_name,1,31) relation,
  SUBSTR(cc.column_name,1,24) columnname,
  SUBSTR(c.table_name,1,20) tablename
FROM dba_cons_columns cc,
  dba_constraints p,
  dba_constraints c
WHERE p.owner           = upper('INTERSHOP')
AND p.table_name        = upper('PRODUCTLINEITEM')
AND p.constraint_type  IN ('P','U')
AND c.r_owner           = p.owner
AND c.r_constraint_name = p.constraint_name
AND c.constraint_type   = 'R'
AND cc.owner            = c.owner
AND cc.constraint_name  = c.constraint_name
AND cc.table_name       = c.table_name
ORDER BY 1, 4, 2, 3
/

-- Vind alle Foreign-keys en of ze al dan niet zijn geindexeerd.
SET linesize 121 
col status format a6 
col columns format a30 word_wrapped 
col table_name format a30 word_wrapped
SELECT DECODE(b.table_name, NULL, '****', 'Ok' ) STATUS,
  a.table_name,
  a.columns,
  b.columns
FROM
  (SELECT SUBSTR(a.table_name,1,30) table_name,
    SUBSTR(a.constraint_name,1,30) constraint_name,
    MAX(DECODE(position, 1, SUBSTR(column_name,1,30), NULL))
    || MAX(DECODE(position, 2,', '
    || SUBSTR(column_name,1,30),NULL))
    || MAX(DECODE(position, 3,', '
    || SUBSTR(column_name,1,30),NULL))
    || MAX(DECODE(position, 4,', '
    || SUBSTR(column_name,1,30),NULL))
    || MAX(DECODE(position, 5,', '
    || SUBSTR(column_name,1,30),NULL))
    || MAX(DECODE(position, 6,', '
    || SUBSTR(column_name,1,30),NULL))
    || MAX(DECODE(position, 7,', '
    || SUBSTR(column_name,1,30),NULL))
    || MAX(DECODE(position, 8,', '
    || SUBSTR(column_name,1,30),NULL))
    || MAX(DECODE(position, 9,', '
    || SUBSTR(column_name,1,30),NULL))
    || MAX(DECODE(position,10,', '
    || SUBSTR(column_name,1,30),NULL))
    || MAX(DECODE(position,11,', '
    || SUBSTR(column_name,1,30),NULL))
    || MAX(DECODE(position,12,', '
    || SUBSTR(column_name,1,30),NULL))
    || MAX(DECODE(position,13,', '
    || SUBSTR(column_name,1,30),NULL))
    || MAX(DECODE(position,14,', '
    || SUBSTR(column_name,1,30),NULL))
    || MAX(DECODE(position,15,', '
    || SUBSTR(column_name,1,30),NULL))
    || MAX(DECODE(position,16,', '
    || SUBSTR(column_name,1,30),NULL)) columns
  FROM dba_cons_columns a,
    dba_constraints b
  WHERE b.owner='TAFKAT_LIS'
  AND a.constraint_name = b.constraint_name
  AND constraint_type     = 'R'
  GROUP BY SUBSTR(a.table_name,1,30),
    SUBSTR(a.constraint_name,1,30)
  ) a,
  (SELECT SUBSTR(table_name,1,30) table_name,
    SUBSTR(Index_Name,1,30) Index_Name,
    MAX(DECODE(Column_Position, 1, SUBSTR(column_name,1,30),NULL))
    || MAX(DECODE(column_position, 2,', '
    ||SUBSTR(column_name,1,30),NULL))
    || MAX(DECODE(column_position, 3,', '
    ||SUBSTR(column_name,1,30),NULL))
    || MAX(DECODE(column_position, 4,', '
    ||SUBSTR(column_name,1,30),NULL))
    || MAX(DECODE(column_position, 5,', '
    ||SUBSTR(column_name,1,30),NULL))
    || MAX(DECODE(column_position, 6,', '
    ||SUBSTR(column_name,1,30),NULL))
    || MAX(DECODE(column_position, 7,', '
    ||SUBSTR(column_name,1,30),NULL))
    || MAX(DECODE(column_position, 8,', '
    ||SUBSTR(column_name,1,30),NULL))
    || MAX(DECODE(column_position, 9,', '
    ||SUBSTR(column_name,1,30),NULL))
    || MAX(DECODE(column_position,10,', '
    ||SUBSTR(column_name,1,30),NULL))
    || MAX(DECODE(column_position,11,', '
    ||SUBSTR(column_name,1,30),NULL))
    || MAX(DECODE(column_position,12,', '
    ||SUBSTR(column_name,1,30),NULL))
    || MAX(DECODE(column_position,13,', '
    ||SUBSTR(column_name,1,30),NULL))
    || MAX(DECODE(column_position,14,', '
    ||SUBSTR(column_name,1,30),NULL))
    || MAX(DECODE(column_position,15,', '
    ||SUBSTR(column_name,1,30),NULL))
    || MAX(DECODE(column_position,16,', '
    ||SUBSTR(column_name,1,30),NULL)) columns
  FROM dba_ind_columns
  where table_owner= 'TAFKAT_LIS'
  GROUP BY SUBSTR(table_name,1,30),
    SUBSTR(index_name,1,30)
  ) b
WHERE a.table_name = b.table_name (+)
AND b.columns (+) LIKE a.columns
  || '%';
  
  
  
  
   select index_name, column_name, column_position from dba_ind_columns where table_owner='LOCUS' and table_name = 'TASKTRS'  and column_name = 'CONTID';

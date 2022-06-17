
set heading off
set lines 200
spool /tmp/supl_logging_P.sql
-- Select all Tables with primary key constraint --
select 'ALTER TABLE DEVVANESSA."' || cols.table_name || '" ADD SUPPLEMENTAL LOG DATA (PRIMARY KEY) COLUMNS;' 
from  dba_constraints cons, dba_cons_columns cols
WHERE 	cons.constraint_type = 'P'
and	cons.owner = 'DEVVANESSA'
AND cons.constraint_name = cols.constraint_name
AND cons.owner = cols.owner
group by cols.table_name
ORDER BY cols.table_name;
spool off

set heading off
set lines 200
spool /tmp/supl_logging_U.sql
-- Select all Tables with unique key constraint --
select 'ALTER TABLE DEVVANESSA."' || cols.table_name || '" ADD SUPPLEMENTAL LOG DATA (UNIQUE) COLUMNS;' 
from  dba_constraints cons, dba_cons_columns cols
WHERE 	cons.constraint_type <> 'P'
AND	cons.constraint_type = 'U'
and	cons.owner = 'DEVVANESSA'
AND cons.constraint_name = cols.constraint_name
AND cons.owner = cols.owner
group by cols.table_name
ORDER BY cols.table_name;
spool off

set heading off
set lines 200
spool /tmp/supl_logging_ALL.sql
-- Select all tables without primary or unique constraints -
select 'ALTER TABLE DEVVANESSA."' || tabs.table_name || '" ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;' 
from (select distinct table_name from dba_tables where owner = 'DEVVANESSA' minus select distinct table_name from dba_constraints where owner = 'DEVVANESSA') tabs;
spool off
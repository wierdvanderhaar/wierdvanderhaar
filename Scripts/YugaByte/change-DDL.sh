-- https://dev.to/yugabyte/copy-progression-in-yugabytedb-4ghb

awk '
# gather primary key definitions in pk[] and cancel lines that adds it later
/^ALTER TABLE ONLY/{last_alter_table=$NF}
/^ *ADD CONSTRAINT .* PRIMARY KEY /{sub(/ADD /,"");sub(/;$/,"");pk[last_alter_table]=$0",";$0=$0"\\r"}
# second pass (i.e when NR>FNR): add primary key definition to create table
NR > FNR && /^CREATE TABLE/{ print $0,pk[$3] > "schema_with_pk.sql" ; next}
# disable backfill for faster create index on empty tables
/^CREATE INDEX/ || /^CREATE UNIQUE INDEX/ { sub("INDEX","INDEX NONCONCURRENTLY") }
NR > FNR { print > "schema_with_pk.sql" }
' schema.sql schema.sql
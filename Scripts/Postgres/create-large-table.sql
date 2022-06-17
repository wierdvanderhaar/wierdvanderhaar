CREATE TABLE Departments (code VARCHAR(4), UNIQUE (code));
CREATE TABLE Towns (
  id SERIAL UNIQUE NOT NULL,
  code VARCHAR(10) NOT NULL, -- not unique
  article TEXT,
  name TEXT NOT NULL, -- not unique
  department VARCHAR(4)
--  UNIQUE (code, department)
);

insert into towns (
    code, article, name, department
)
select
    left(md5(i::text), 10),
    md5(random()::text),
    md5(random()::text),
    left(md5(random()::text), 4)
from generate_series(1, 1000000) s(i);




SELECT pg_size_pretty( pg_database_size('postgres'));


CREATE TABLE towns1 (
  id SERIAL UNIQUE NOT NULL,
  code VARCHAR(10) NOT NULL, -- not unique
  article TEXT,
  name TEXT NOT NULL, -- not unique
  department VARCHAR(4)
--  UNIQUE (code, department)
);

-- 1 Biljon rows 
insert into towns1 (
    code, article, name, department
)
select
    left(md5(i::text), 10),
    md5(random()::text),
    md5(random()::text),
    left(md5(random()::text), 4)
from generate_series(1, 1000000000) s(i);


postgres=# SELECT pg_size_pretty( pg_database_size('postgres'));
 pg_size_pretty 
----------------
 130 GB
(1 row)


create table towns
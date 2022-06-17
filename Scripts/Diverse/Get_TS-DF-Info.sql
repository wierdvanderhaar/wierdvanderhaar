col container_name format a10
set lines 200
set pages 1000
select y.name container_name
     , x.tablespace_name tbname
     , x.aantal_dbf
     , x.totalspace total_mb
     , x.totalspace - y.totalfreespace used_mb
     , y.totalfreespace free_mb
     , round (y.totalfreespace / x.totalspace * 100 ) pct_free
     , x.maxspace
    , round( 100 - (( x.totalspace - y.totalfreespace ) / x.maxspace) * 100 )  pct_max_free
from ( select tablespace_name
            , count(*) aantal_dbf
            , round(sum(bytes) / 1048576) totalspace
            , round(sum(decode(maxbytes,0,bytes,maxbytes)) / 1048576) maxspace
       from cdb_data_files
       group by tablespace_name
       union
       select tablespace_name
            , count(*) aantal_dbf
            , round(sum(bytes) / 1048576) totalspace
            , round(sum(decode(maxbytes,0,bytes,maxbytes)) / 1048576) maxspace
       from cdb_temp_files
       group by tablespace_name
     ) x
   , ( select c.name
            , f.tablespace_name
            , round(sum(f.bytes)/1048576) totalfreespace
       from v$containers c
          , cdb_free_space f
       group by c.name, f.tablespace_name
       union
       select c.name
            , f.tablespace_name
            , round(sum(f.free_space)/1048576) totalfreespace
       from v$containers c
          , cdb_temp_free_space f
       group by c.name, f.tablespace_name
     ) y
where x.tablespace_name = y.tablespace_name
order by 1,2;

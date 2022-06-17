column OBJECT_NAME format a50
SELECT   ds.BUFFER_POOL,
         Substr(do.object_name,1,50) object_name,
         ds.blocks                  object_blocks,
         Count(* )                  cached_blocks
FROM     dba_objects do,
         dba_segments ds,
         v$bh v
WHERE    do.data_object_id = v.objd
         AND do.owner = ds.owner (+)
         AND do.object_name = ds.segment_name (+)
         AND do.object_type = ds.segment_type (+)
         AND ds.BUFFER_POOL IN ('KEEP','RECYCLE')
GROUP BY ds.BUFFER_POOL,
         do.object_name,
         ds.blocks
ORDER BY do.object_name,
         ds.BUFFER_POOL; 


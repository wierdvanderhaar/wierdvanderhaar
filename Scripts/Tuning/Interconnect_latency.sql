select b1.inst_id, b2.value "GCS CR BLOCKS RECEIVED",
 b1.value "GCS CR BLOCK RECEIVE TIME",
 ((b1.value / b2.value) * 10) "AVG CR BLOCK RECEIVE TIME (ms)"
 from gv$sysstat b1, gv$sysstat b2
 where b1.name = 'global cache cr block receive time' and
 b2.name = 'global cache cr blocks received' and b1.inst_id = b2.inst_id
 or b1.name = 'gc cr block receive time' and
 b2.name = 'gc cr blocks received' and b1.inst_id = b2.inst_id;
 
 select b1.inst_id, b2.value "GCS CR BLOCKS RECEIVED",
 b1.value "GCS CR BLOCK RECEIVE TIME" 
  from gv$sysstat b1, gv$sysstat b2
 where b1.name = 'global cache cr block receive time' and
 b2.name = 'global cache cr blocks received' and b1.inst_id = b2.inst_id
 or b1.name = 'gc cr block receive time' and
 b2.name = 'gc cr blocks received' and b1.inst_id = b2.inst_id;
select min(object_id), max(object_id), count(object_id), wb
    from (
  select object_id,
         width_bucket( object_id,
                       (select min(object_id)-1 from all_objects),
                       (select max(object_id)+1 from all_objects), 5 ) wb
    from all_objects
         )
   group by wb
/

SELECT Rownum AS Rank,
       Seg_Lio.*
  FROM (SELECT St.Owner,
               St.Obj#,
               St.Object_Type,
               St.Object_Name,
               St.VALUE,
               'LIO' AS Unit
          FROM V$segment_Statistics St
         WHERE St.Statistic_Name = 'logical reads'
         ORDER BY St.VALUE DESC) Seg_Lio
 WHERE Rownum <= 10
UNION ALL
SELECT Rownum AS Rank,
       Seq_Pio_r.*
  FROM (SELECT St.Owner,
               St.Obj#,
               St.Object_Type,
               St.Object_Name,
               St.VALUE,
               'PIO Reads' AS Unit
          FROM V$segment_Statistics St
         WHERE St.Statistic_Name = 'physical reads'
         ORDER BY St.VALUE DESC) Seq_Pio_r
 WHERE Rownum <= 10
UNION ALL
SELECT Rownum AS Rank,
       Seq_Pio_w.*
  FROM (SELECT St.Owner,
               St.Obj#,
               St.Object_Type,
               St.Object_Name,
               St.VALUE,
               'PIO Writes' AS Unit
          FROM V$segment_Statistics St
         WHERE St.Statistic_Name = 'physical writes'
         ORDER BY St.VALUE DESC) Seq_Pio_w
 WHERE Rownum <= 10;


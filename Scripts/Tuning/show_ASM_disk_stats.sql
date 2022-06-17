TTITLE 'ASM disk statistics (From v$asm_disk_stat)'

select PATH, READS, WRITES, READ_TIME, WRITE_TIME,
       READ_TIME/decode(READS,0,1,READS) "avgrdtime ",
       WRITE_TIME/decode(WRITES,0,1,WRITES) "avgwrtime"
from v$asm_disk_stat;
select b.* from v$sqlarea a ,table(version_rpt(null,a.hash_value)) b where loaded_versions>=100;

select b.* from v$sqlarea a ,table(version_rpt(a.sql_id)) b where loaded_versions >=100;


select  sql_text,
        version_count,
        executions,
        address
from    v$sqlarea where version_count>= (select        max(version_count) -5
                                          from          v$sqlarea)
order   by version_count
/


select  *
from    v$sql_shared_cursor
where   KGLHDPAR =
        (select address
         from   v$sqlarea
         where  version_count=(select   max(version_count)
                               from     v$sqlarea))
/


Wat is de reden dat statements veel versies hebben. 
select version_count,address,hash_value,parsing_schema_name,reason,sql_text from (
select
 address,''
 ||decode(max(                UNBOUND_CURSOR),'Y',               ' UNBOUND_CURSOR')
 ||decode(max(             SQL_TYPE_MISMATCH),'Y',            ' SQL_TYPE_MISMATCH')
 ||decode(max(            OPTIMIZER_MISMATCH),'Y',           ' OPTIMIZER_MISMATCH')
 ||decode(max(              OUTLINE_MISMATCH),'Y',             ' OUTLINE_MISMATCH')
 ||decode(max(            STATS_ROW_MISMATCH),'Y',           ' STATS_ROW_MISMATCH')
 ||decode(max(              LITERAL_MISMATCH),'Y',             ' LITERAL_MISMATCH')
 ||decode(max(            SEC_DEPTH_MISMATCH),'Y',           ' SEC_DEPTH_MISMATCH')
 ||decode(max(           EXPLAIN_PLAN_CURSOR),'Y',          ' EXPLAIN_PLAN_CURSOR')
 ||decode(max(         BUFFERED_DML_MISMATCH),'Y',        ' BUFFERED_DML_MISMATCH')
 ||decode(max(             PDML_ENV_MISMATCH),'Y',            ' PDML_ENV_MISMATCH')
 ||decode(max(           INST_DRTLD_MISMATCH),'Y',          ' INST_DRTLD_MISMATCH')
 ||decode(max(             SLAVE_QC_MISMATCH),'Y',            ' SLAVE_QC_MISMATCH')
 ||decode(max(            TYPECHECK_MISMATCH),'Y',           ' TYPECHECK_MISMATCH')
 ||decode(max(           AUTH_CHECK_MISMATCH),'Y',          ' AUTH_CHECK_MISMATCH')
 ||decode(max(                 BIND_MISMATCH),'Y',                ' BIND_MISMATCH')
 ||decode(max(             DESCRIBE_MISMATCH),'Y',            ' DESCRIBE_MISMATCH')
 ||decode(max(             LANGUAGE_MISMATCH),'Y',            ' LANGUAGE_MISMATCH')
 ||decode(max(          TRANSLATION_MISMATCH),'Y',         ' TRANSLATION_MISMATCH')
 ||decode(max(        ROW_LEVEL_SEC_MISMATCH),'Y',       ' ROW_LEVEL_SEC_MISMATCH')
 ||decode(max(                  INSUFF_PRIVS),'Y',                 ' INSUFF_PRIVS')
 ||decode(max(              INSUFF_PRIVS_REM),'Y',             ' INSUFF_PRIVS_REM')
 ||decode(max(         REMOTE_TRANS_MISMATCH),'Y',        ' REMOTE_TRANS_MISMATCH')
 ||decode(max(     LOGMINER_SESSION_MISMATCH),'Y',    ' LOGMINER_SESSION_MISMATCH')
 ||decode(max(          INCOMP_LTRL_MISMATCH),'Y',         ' INCOMP_LTRL_MISMATCH')
 ||decode(max(         OVERLAP_TIME_MISMATCH),'Y',        ' OVERLAP_TIME_MISMATCH')
 ||decode(max(         SQL_REDIRECT_MISMATCH),'Y',        ' SQL_REDIRECT_MISMATCH')
 ||decode(max(         MV_QUERY_GEN_MISMATCH),'Y',        ' MV_QUERY_GEN_MISMATCH')
 ||decode(max(       USER_BIND_PEEK_MISMATCH),'Y',      ' USER_BIND_PEEK_MISMATCH')
 ||decode(max(           TYPCHK_DEP_MISMATCH),'Y',          ' TYPCHK_DEP_MISMATCH')
 ||decode(max(           NO_TRIGGER_MISMATCH),'Y',          ' NO_TRIGGER_MISMATCH')
 ||decode(max(              FLASHBACK_CURSOR),'Y',             ' FLASHBACK_CURSOR')
 ||decode(max(        ANYDATA_TRANSFORMATION),'Y',       ' ANYDATA_TRANSFORMATION')
 ||decode(max(             INCOMPLETE_CURSOR),'Y',            ' INCOMPLETE_CURSOR')
 ||decode(max(          TOP_LEVEL_RPI_CURSOR),'Y',         ' TOP_LEVEL_RPI_CURSOR')
 ||decode(max(         DIFFERENT_LONG_LENGTH),'Y',        ' DIFFERENT_LONG_LENGTH')
 ||decode(max(         LOGICAL_STANDBY_APPLY),'Y',        ' LOGICAL_STANDBY_APPLY')
 ||decode(max(                DIFF_CALL_DURN),'Y',               ' DIFF_CALL_DURN')
 ||decode(max(                BIND_UACS_DIFF),'Y',               ' BIND_UACS_DIFF')
 ||decode(max(        PLSQL_CMP_SWITCHS_DIFF),'Y',       ' PLSQL_CMP_SWITCHS_DIFF')
 ||decode(max(         CURSOR_PARTS_MISMATCH),'Y',        ' CURSOR_PARTS_MISMATCH')
 ||decode(max(           STB_OBJECT_MISMATCH),'Y',          ' STB_OBJECT_MISMATCH')
 ||decode(max(             ROW_SHIP_MISMATCH),'Y',            ' ROW_SHIP_MISMATCH')
 ||decode(max(             PQ_SLAVE_MISMATCH),'Y',            ' PQ_SLAVE_MISMATCH')
 ||decode(max(        TOP_LEVEL_DDL_MISMATCH),'Y',       ' TOP_LEVEL_DDL_MISMATCH')
 ||decode(max(             MULTI_PX_MISMATCH),'Y',            ' MULTI_PX_MISMATCH')
 ||decode(max(       BIND_PEEKED_PQ_MISMATCH),'Y',      ' BIND_PEEKED_PQ_MISMATCH')
 ||decode(max(           MV_REWRITE_MISMATCH),'Y',          ' MV_REWRITE_MISMATCH')
 ||decode(max(         ROLL_INVALID_MISMATCH),'Y',        ' ROLL_INVALID_MISMATCH')
 ||decode(max(       OPTIMIZER_MODE_MISMATCH),'Y',      ' OPTIMIZER_MODE_MISMATCH')
 ||decode(max(                   PX_MISMATCH),'Y',                  ' PX_MISMATCH')
 ||decode(max(          MV_STALEOBJ_MISMATCH),'Y',         ' MV_STALEOBJ_MISMATCH')
 ||decode(max(      FLASHBACK_TABLE_MISMATCH),'Y',     ' FLASHBACK_TABLE_MISMATCH')
 ||decode(max(          LITREP_COMP_MISMATCH),'Y',         ' LITREP_COMP_MISMATCH')
 reason
from 
   v$sql_shared_cursor 
group by 
   address 
) join v$sqlarea using(address) where version_count>&versions
order by version_count desc,address
;

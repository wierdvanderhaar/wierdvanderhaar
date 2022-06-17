REM ****************************************************************************************
REM  *                                       Copyright NedGraphics B.V., Utrecht, Netherlands
REM  * SYSTEM     : NEDBROWSER
REM  * PROGRAM    : Update Oracle Spatial SRID
REM  * FILE       : nbg_upd_oracle_srid.sql
REM  *
REM  * PURPOSE    : Generic script to update SRID in both data and metadata (user_sdo_geom_metadata)
REM  * NOTES      : The script does the following
REM  *              - update USER_SDO_GEOM_METADATA
REM  *              - drop spatial index XXX
REM  *              - update SDO_SRID in de geometrie kolom
REM  *              - create spatial index XXX
REM  *              If spatial index XXX did not exist, a spatial index with name "tablename_S_I" is created.
REM  *              For "tablename" the first 26 characters are taken.
REM  *
REM  *              Further steps to execute after this script:
REM  *              MapXtreme:          update of table MAPINFO.MAPINFO_CATALOG
REM  *              MapGuide/MapXtreme: update of USER_SDO_GEOM_METADATA for all spatial views
REM  *
REM  *
REM  * CREATION   : 09-06-2004
REM  * AUTHOR     : Ron Lindhoudt
REM  *
REM  *
REM  ****************************************************************************************

SET serveroutput ON SIZE 100000
set lines 80
set verify off

DECLARE

    CURSOR c_col is
        SELECT col.table_name,
               col.column_name
          FROM user_tab_columns col,
               user_tables tab          -- to make sure views are not selected!
         WHERE col.data_type = 'SDO_GEOMETRY' and tab.table_name in (select table_name from user_sdo_geom_metadata where srid=90112)
           AND tab.table_name = col.table_name 
      ORDER BY col.table_name, col.column_name;

    CURSOR c_ind (b_table_name VARCHAR2, b_column_name VARCHAR2) is
        SELECT index_name
          FROM user_ind_columns ind 
         WHERE ind.table_name = b_table_name
           AND ind.column_name = b_column_name; 

    v_index_name    user_ind_columns.index_name%TYPE;
    v_statement     VARCHAR2(2000);
BEGIN
    FOR r_col IN c_col LOOP
        dbms_output.put_line('table='||r_col.table_name||', column='||r_col.column_name);

        v_index_name := NULL;
        OPEN c_ind (r_col.table_name, r_col.column_name);
        FETCH c_ind INTO v_index_name;
        CLOSE c_ind;

        IF v_index_name IS NOT NULL THEN
            v_statement := 'DROP INDEX '||v_index_name;
            dbms_output.put_line(v_statement||';');
            EXECUTE IMMEDIATE v_statement;
        END IF;

        IF v_index_name IS NULL THEN
            v_index_name := SUBSTR(r_col.table_name,1,26) || '_S_I';
        END IF;

        v_statement := 'CREATE INDEX '||v_index_name||' ON '||r_col.table_name||
                       '('||r_col.column_name||') indextype is mdsys.spatial_index' ||
                       ' parameters(''sdo_max_memory=2000000'')';
        dbms_output.put_line(v_statement||';');
        EXECUTE IMMEDIATE v_statement;       
    END LOOP;
END;
/


COMMIT;
SET SERVEROUTPUT ON SIZE 100000
SET LINES 80

-- Accept min_x prompt 'Minimum X-coordinaat: '
-- Accept max_x prompt 'Maximum X-coordinaat: '
-- Accept min_y prompt 'Minimum Y-coordinaat: '
-- Accept max_y prompt 'Maximum Y-coordinaat: '

SET VERIFY OFF

ALTER SESSION SET NLS_TERRITORY=AMERICA;

DECLARE
    v_insert_sdo_metadata1 VARCHAR2(2000) :=
        'insert into USER_SDO_GEOM_METADATA values (
         ''$TABLE_NAME$''
        ,''$COLUMN_NAME$''
        ,mdsys.sdo_dim_array(mdsys.sdo_dim_element(''X'',''$LLX$'',''$URX$'',0.00005)
                            ,mdsys.sdo_dim_element(''Y'',''$LLY$'',''$URY$'',0.00005))
        ,90112)';

    v_insert_sdo_metadata       VARCHAR2(2000);
    v_num_tables                NUMBER := 0;

    CURSOR c_col is
        SELECT table_name,
               column_name
          FROM user_tab_columns col 
         WHERE col.data_type = 'SDO_GEOMETRY'
         ORDER BY col.table_name, col.column_name;

    CURSOR c_col_exists (b_table_name VARCHAR2, b_column_name VARCHAR2) is
        SELECT 'TRUE'
          FROM user_tab_columns col 
         WHERE col.table_name  = b_table_name
         AND col.column_name = b_column_name;

min_x number(10);
max_x number(10);
min_y number(10);
max_y number(10);
BEGIN
    FOR r_col IN c_col LOOP
	min_x := 12000;
	max_x := 305000;
	min_y := 280000;
	max_y := 620000;

        v_num_tables := v_num_tables + 1;

        DELETE
          FROM USER_SDO_GEOM_METADATA
         WHERE table_name  = r_col.table_name
           AND column_name = r_col.column_name;

        v_insert_sdo_metadata := REPLACE(v_insert_sdo_metadata1, '$TABLE_NAME$', r_col.table_name);
        v_insert_sdo_metadata := REPLACE(v_insert_sdo_metadata, '$COLUMN_NAME$', r_col.column_name);
        v_insert_sdo_metadata := REPLACE(v_insert_sdo_metadata, '$LLX$', &&min_x);
        v_insert_sdo_metadata := REPLACE(v_insert_sdo_metadata, '$LLY$', &&max_x);
        v_insert_sdo_metadata := REPLACE(v_insert_sdo_metadata, '$URX$', &&min_y);
        v_insert_sdo_metadata := REPLACE(v_insert_sdo_metadata, '$URY$', &&max_y);                        
        
        DBMS_OUTPUT.PUT_LINE('table='||r_col.table_name||', column='||r_col.column_name);

        EXECUTE IMMEDIATE v_insert_sdo_metadata;
    END LOOP;

END;
/

COMMIT;
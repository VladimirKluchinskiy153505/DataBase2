CREATE OR REPLACE PROCEDURE compare_schemas (
    dev_schema_name IN VARCHAR2,
    prod_schema_name IN VARCHAR2
)
AS
    CURSOR dev_tables_cur IS
        SELECT table_name
        FROM all_tables
        WHERE owner = dev_schema_name;
    
    CURSOR prod_tables_cur IS
        SELECT table_name
        FROM all_tables
        WHERE owner = prod_schema_name;
        
    dev_table_name VARCHAR2(100);
    prod_table_name VARCHAR2(100);
    table_exists BOOLEAN := FALSE;
    loop_detected BOOLEAN := FALSE;
    recursion_depth NUMBER := 0;
    
      TYPE tables_names_arr IS TABLE OF VARCHAR2(100);
     visited_arr tables_names_arr:=tables_names_arr();
    
    
    PROCEDURE detect_loop (
        start_table_name IN VARCHAR2,
        current_table_name IN VARCHAR2,
        depth IN NUMBER
    )
    IS
        CURSOR fk_cur IS
            SELECT b.table_name as table_name, b.constraint_name, b.column_name
            FROM all_constraints a 
            JOIN all_cons_columns b ON a.r_constraint_name = b.constraint_name 
            WHERE a.constraint_type = 'R' 
            AND a.table_name = current_table_name
            AND a.owner = dev_schema_name;
        next_table_name VARCHAR2(100);
    BEGIN
        visited_arr.EXTEND;
        visited_arr(visited_arr.COUNT):=current_table_name;
        
        FOR fk_rec IN fk_cur LOOP
            next_table_name := fk_rec.table_name;
             DBMS_OUTPUT.PUT_LINE('Table Name from constraint'|| next_table_name);
            IF next_table_name = start_table_name THEN
                loop_detected := TRUE;
                DBMS_OUTPUT.PUT_LINE('Circular dependency detected: ' || start_table_name || ' -> ' || current_table_name || ' -> ' || next_table_name || ' depth:3');
                RETURN;
            ELSE
                detect_loop(start_table_name, next_table_name, depth + 1);
            END IF;
        END LOOP;
    END detect_loop;
    
    FUNCTION column_exists_in_table(
    column_name IN VARCHAR2,
    table_name IN VARCHAR2,
    schema_name IN VARCHAR2
    ) RETURN BOOLEAN
    IS
        v_count NUMBER;
    BEGIN
    -- Проверяем количество записей, соответствующих заданным критериям
        SELECT COUNT(*)
        INTO v_count
        FROM all_tab_columns
        WHERE column_name = column_exists_in_table.column_name
        AND table_name = column_exists_in_table.table_name
        AND owner = column_exists_in_table.schema_name;

    -- Если количество записей больше 0, значит колонка существует
        IF v_count > 0 THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
        -- Обрабатываем случай, когда не найдены данные
            RETURN FALSE;
        WHEN OTHERS THEN
        -- Обрабатываем другие ошибки
            RETURN FALSE;
    END;
    
    FUNCTION compare_table_structure(
        dev_schema_name IN VARCHAR2,
        prod_schema_name IN VARCHAR2,
        table_name0 IN VARCHAR2
    ) RETURN BOOLEAN
    IS
        tables_equal BOOLEAN := TRUE;
    BEGIN
        FOR dev_col_rec IN (SELECT column_name as cl FROM all_tab_columns WHERE table_name = table_name0 AND owner = dev_schema_name) LOOP
        -- Проверяем, существует ли колонка в таблице из dev_schema_name также и в таблице из prod_schema_name
            IF column_exists_in_table(dev_col_rec.cl, table_name0, prod_schema_name) THEN
                DBMS_OUTPUT.PUT_LINE('Column ' || dev_col_rec.cl || ' exists in both Dev and Prod schemas.');
            ELSE
            -- Если колонка не существует в таблице из prod_schema_name, устанавливаем флаг в FALSE
                tables_equal := FALSE;
                DBMS_OUTPUT.PUT_LINE('Column ' || dev_col_rec.cl || ' exists in Dev schema but not in Prod schema.');
                RETURN tables_equal;
            END IF;
        END LOOP;
        FOR prod_col_rec IN (SELECT column_name as cl FROM all_tab_columns WHERE table_name = table_name0 AND owner = prod_schema_name) LOOP
        -- Проверяем, существует ли колонка в таблице из dev_schema_name также и в таблице из prod_schema_name
            IF column_exists_in_table(prod_col_rec.cl, table_name0, dev_schema_name) THEN
                DBMS_OUTPUT.PUT_LINE('Column ' || prod_col_rec.cl || ' exists in both Dev and Prod schemas.');
            ELSE
            -- Если колонка не существует в таблице из prod_schema_name, устанавливаем флаг в FALSE
                tables_equal := FALSE;
                DBMS_OUTPUT.PUT_LINE('Column ' || prod_col_rec.cl || ' exists in Dev schema but not in Prod schema.');
                RETURN tables_equal;
            END IF;
        END LOOP;

        RETURN tables_equal;
    END compare_table_structure;
    
BEGIN
    -- Loop through tables in dev schema
    FOR dev_rec IN dev_tables_cur LOOP
        dev_table_name := dev_rec.table_name;
         DBMS_OUTPUT.PUT_LINE('CurrentTableInCycle: '||dev_table_name);
        table_exists := FALSE;
        
        -- Check if the table exists in prod schema
        FOR prod_rec IN prod_tables_cur LOOP
            IF dev_table_name = prod_rec.table_name THEN
                table_exists := TRUE;
                EXIT;
            END IF;
        END LOOP;
        
        -- If table doesn't exist in prod schema
        IF NOT table_exists THEN
            DBMS_OUTPUT.PUT_LINE('Table ' || dev_table_name || ' exists in Dev schema but not in Prod schema.');
        ELSE
            -- Check for structural differences
        
            IF compare_table_structure(dev_schema_name, prod_schema_name, dev_table_name) THEN
                DBMS_OUTPUT.PUT_LINE('Tables ' || dev_table_name || ' are equal.');
            ELSE
                DBMS_OUTPUT.PUT_LINE('Table ' || dev_table_name || ' has structural differences between Dev and Prod schemas.');
            END IF;
        
        END IF;
        
        -- Check for circular dependencies
        loop_detected := FALSE;
        IF (dev_table_name NOT MEMBER OF visited_arr) THEN
            recursion_depth := 0;
            detect_loop(dev_table_name, dev_table_name, recursion_depth);
        
        END IF;
        DBMS_OUTPUT.PUT_LINE('CycleEnded: '||dev_table_name);
    END LOOP;
    
    -- Close cursor
    IF dev_tables_cur%ISOPEN THEN
        CLOSE dev_tables_cur;
    END IF;
    IF prod_tables_cur%ISOPEN THEN
        CLOSE prod_tables_cur;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        -- Handle errors
        DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
END;


DROP PROCEDURE compare_schemas;
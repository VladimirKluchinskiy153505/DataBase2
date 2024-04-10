GRANT ALL PRIVILEGES TO DEVUSER;
GRANT CONNECT, RESOURCE TO DEVUSER;
GRANT CREATE VIEW TO DEVUSER;

--GRANT ALL PRIVILEGES TO PRODUSER;
--GRANT SELECT_CATALOG_ROLE TO DEVUSER;
--GRANT SELECT_CATALOG_ROLE TO PRODUSER;
CREATE OR REPLACE PROCEDURE different_schemas (dev_schema_name VARCHAR2, prod_schema_name VARCHAR2) AUTHID CURRENT_USER
AS
    TYPE tables_names_arr IS TABLE OF VARCHAR2(100);
    different_t tables_names_arr := tables_names_arr();
    dev_t tables_names_arr;
    prod_t tables_names_arr;
    same_t tables_names_arr;
    not_prod_t tables_names_arr;
    current_table VARCHAR2(100);
    recursion_level INTEGER;
    i INTEGER;

    PROCEDURE add_table(name_t VARCHAR2)
    AS
        parent_tables tables_names_arr := tables_names_arr();
        cycle_error EXCEPTION;
        i INT;
    BEGIN 
        IF (recursion_level > 100) THEN
            dbms_output.put_line('Cycle in ' || name_t);
            RAISE cycle_error;
        END IF;
        IF (name_t MEMBER OF different_t OR name_t NOT MEMBER OF not_prod_t) THEN
            RETURN;
        END IF;

        SELECT c_pk.table_name
            BULK COLLECT INTO parent_tables
            FROM all_cons_columns a
            JOIN all_constraints c
                ON a.OWNER = c.OWNER
                AND a.constraint_name = c.constraint_name
            JOIN all_constraints c_pk
                ON c.r_owner = c_pk.OWNER
                AND c.r_constraint_name = c_pk.constraint_name   
            WHERE
                c.constraint_type = 'R'
                AND a.table_name = name_t
                AND a.OWNER = dev_schema_name;


        IF (parent_tables.COUNT > 0) THEN 
            i := parent_tables.FIRST;
            WHILE (i IS NOT NULL)
            LOOP   
                recursion_level := recursion_level + 1;
                add_table(parent_tables(i));
                recursion_level := recursion_level - 1;
                i := parent_tables.NEXT(i);
            END LOOP;
        END IF;

        different_t.EXTEND;
        different_t(different_t.COUNT) := name_t;
        dbms_output.put_line('Dev has unique table "' || name_t || '"');
    END;

BEGIN
    SELECT table_name BULK COLLECT INTO dev_t FROM all_tables WHERE OWNER=dev_schema_name;
    SELECT table_name BULK COLLECT INTO prod_t FROM all_tables WHERE OWNER=prod_schema_name;

    not_prod_t := dev_t MULTISET EXCEPT prod_t;
    i := not_prod_t.FIRST;
    WHILE i IS NOT NULL 
    LOOP
        current_table := not_prod_t(i);
        
        IF (current_table MEMBER OF different_t) THEN
            i := not_prod_t.NEXT(i);
            CONTINUE;
        END IF;

        recursion_level := 0;
        add_table(current_table);
        i := not_prod_t.NEXT(i);
    END LOOP;

    same_t := dev_t MULTISET INTERSECT prod_t;
    i := same_t.FIRST;
    
    WHILE i IS NOT NULL 
    LOOP
        current_table := same_t(i);
        
        IF (dbms_metadata_diff.compare_alter(
            'TABLE', current_table, current_table, dev_schema_name, prod_schema_name
        ) = EMPTY_CLOB() ) 
        THEN
            dbms_output.put_line('    Dev and Prod has absolutly same "' || current_table || '"');
        ELSIF (dbms_metadata_diff.compare_alter(
            'TABLE', current_table, current_table, dev_schema_name, prod_schema_name
        ) IS NOT NULL) 
        THEN
            different_t.EXTEND;
            different_t(different_t.COUNT) := current_table;
            dbms_output.put_line('Dev and Prod has difference in "' || current_table || '"');        
        END IF;
    
        i:= same_t.NEXT(i);
    END LOOP;
    
END;
/

-- вызов процедуры
BEGIN
    different_schemas('DEVUSER', 'PRODUSER');
END; 
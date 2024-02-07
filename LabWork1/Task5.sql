CREATE OR REPLACE PROCEDURE INSERT_INTO_MYTABLE(
new_val NUMBER,
new_id NUMBER DEFAULT NULL) IS
    saved_id NUMBER := 0;
    exist_flag NUMBER := 0;
BEGIN
    IF new_id IS NULL THEN
        INSERT INTO MyTable (val)
        VALUES (new_val)
        RETURNING id into saved_id;
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Successfully inserted id: ' || saved_id || ' val: '||new_val );
    ELSE
        IF new_id <=0 THEN
        DBMS_OUTPUT.PUT_LINE('ID must be positive!');
        ELSE
            SELECT COUNT(*)
            INTO exist_flag
            FROM MYTABLE
            WHERE id = new_id;
        
            IF exist_flag > 0 THEN
                DBMS_OUTPUT.PUT_LINE('Element with this id is already exists!');
            ELSE
                INSERT INTO MyTable (id, val)
                VALUES (new_id, new_val)
                RETURNING id into saved_id;
                COMMIT;
                DBMS_OUTPUT.PUT_LINE('Successfully inserted id: ' || saved_id || ' val: '||new_val );
            END IF;
        END IF;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error occured while insertion');
END INSERT_INTO_MYTABLE;
-- 4Task
CREATE OR REPLACE PROCEDURE MAKE_INSERTION_COMMAND(new_id NUMBER) IS
    new_val NUMBER;
    exist_flag NUMBER := 0;
BEGIN
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
            new_val := ROUND(DBMS_RANDOM.VALUE(1, 1000));
            DBMS_OUTPUT.PUT_LINE('INSERT INTO MyTable (id, val)');
            DBMS_OUTPUT.PUT_LINE('VALUES (' || new_id || ', ' || new_val || ');');
        END IF;
    END IF;
    RETURN;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error occured!');
END MAKE_INSERTION_COMMAND;
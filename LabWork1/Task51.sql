CREATE OR REPLACE PROCEDURE UPDATE_MYTABLE(
new_val NUMBER,
current_id NUMBER
) IS
    saved_id NUMBER := 0;
    exist_flag NUMBER := 0;
BEGIN
    IF current_id <=0 THEN
        DBMS_OUTPUT.PUT_LINE('ID must be positive!');
    ELSE
        SELECT COUNT(*)
        INTO exist_flag
        FROM MYTABLE
        WHERE id = current_id;
        
        IF exist_flag != 1 THEN
            DBMS_OUTPUT.PUT_LINE('Element with this id does not exist!');
        ELSE
            UPDATE MYTABLE
            SET val = new_val
            WHERE id = current_id
            RETURNING id into saved_id;
            COMMIT;
            DBMS_OUTPUT.PUT_LINE('Successfully udpated id: ' || saved_id || ' val: '||new_val );
        END IF;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error occured while updating');
END UPDATE_MYTABLE;
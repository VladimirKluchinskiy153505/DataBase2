CREATE OR REPLACE PROCEDURE DELETE_FROM_MYTABLE(
current_id NUMBER
) IS
    deleted_id NUMBER := 0;
    deleted_val NUMBER:= 0;
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
            DELETE FROM MYTABLE
            WHERE id = current_id
            RETURNING id into deleted_id;
            COMMIT;
            DBMS_OUTPUT.PUT_LINE('Successfully deleted id: ' || deleted_id );
        END IF;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error occured while DELETING');
END DELETE_FROM_MYTABLE;
-- 2Task
DECLARE
    v_id NUMBER;
    error_message VARCHAR2(20) := 'Error occured!';
BEGIN
    FOR i IN 1..10000 LOOP
        v_id := i;
        INSERT INTO MyTable (id, val) VALUES (v_id, ROUND(DBMS_RANDOM.VALUE(1, 10000)));
    END LOOP;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error occured!');
END;
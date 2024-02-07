DROP TABLE MyTable;
-- 1Task
CREATE TABLE MyTable(
    id NUMBER,
    val NUMBER
);

-- 2Task
DECLARE
    v_id NUMBER;
    error_message VARCHAR2 := 'Error occured!';
BEGIN
    FOR i IN 1..10000 LOOP
        v_id := i;
        INSERT INTO MyTable (id, val) VALUES (v_id, ROUND(DBMS_RANDOM.VALUE(1, 1000)));
    END LOOP;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('Error occured!');
END;


CREATE OR REPLACE FUNCTION CHECK_EVEN_NUM_COUNT RETURN VARCHAR2 IS
    even_count NUMBER :=0;
    odd_count NUMBER := 0;
    --error_message VARCHAR2 := 'Error occured!';
BEGIN
    FOR item in (SELECT val FROM MYTABLE) LOOP
        IF MOD(item.val, 2) = 0 THEN
            even_count := even_count + 1;
        ELSE
            odd_count := odd_count + 1;
        END IF;
    END LOOP;
    --dbms_output.put_line('EVEN count: ' || even_count);
    --dbms_output.put_line('ODD count: ' || odd_count);
    IF even_count > odd_count THEN
        RETURN 'TRUE';
    ELSIF even_count < odd_count THEN
        RETURN 'FALSE';
    ELSE
        RETURN 'EQUAL';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('Error occured!');
        --RETURN 'Error occured!';
END;

DECLARE
    result VARCHAR2(10);
BEGIN
    result := CHECK_EVEN_NUM_COUNT();
    dbms_output.put_line('Result: ' || result);
END;

-- 4Task
CREATE OR REPLACE FUNCTION MAKE_INSERTION_COMMAND(new_id NUMBER) RETURN VOID IS
    new_val NUMBER;
    exist_flag BOOLEAN := FALSE;
    error_message VARCHAR2 := 'Error occured!';
BEGIN
    IF new_id <=0 THEN
        dbms_output.put_line('ID must be positive!');
    ELSE
        SELECT COUNT(*)
        INTO exist_flag
        FROM MYTABLE
        WHERE id = new_id;
        
        IF exist_flag THEN
            dbms_output.put_line('Element with this id is already exists!');
        ELSE
            new_val := ROUND(DBMS_RANDOM.VALUE(1, 1000));
            DBMS_OUTPUT.PUT_LINE('INSERT INTO MyTable (id, val)');
            DBMS_OUTPUT.PUT_LINE('VALUES (' || new_id || ', ' || new_val || ');');
        END IF;
    END IF;
    RETURN;
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line(error_message);
END;
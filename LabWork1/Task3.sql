--Task3
CREATE OR REPLACE FUNCTION CHECK_EVEN_NUM_COUNT RETURN VARCHAR2 IS
    even_count NUMBER :=0;
    odd_count NUMBER := 0;
    error_message VARCHAR2(20) := 'Error occured!';
BEGIN
    FOR item in (SELECT val FROM MYTABLE) LOOP
        IF MOD(item.val, 2) = 0 THEN
            even_count := even_count + 1;
        ELSE
            odd_count := odd_count + 1;
        END IF;
    END LOOP;
    --DBMS_OUTPUT.PUT_LINE('EVEN count: ' || even_count);
    --DBMS_OUTPUT.PUT_LINE('ODD count: ' || odd_count);
    IF even_count > odd_count THEN
        RETURN 'TRUE';
    ELSIF even_count < odd_count THEN
        RETURN 'FALSE';
    ELSE
        RETURN 'EQUAL';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        --DBMS_OUTPUT.PUT_LINE('Error occured!');
        RETURN error_message;
END CHECK_EVEN_NUM_COUNT;

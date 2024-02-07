DECLARE
    result VARCHAR2(10);
BEGIN
    result := CHECK_EVEN_NUM_COUNT();
    dbms_output.put_line('Result: ' || result);
END;
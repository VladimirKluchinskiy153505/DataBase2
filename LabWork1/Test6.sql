DECLARE
    result FLOAT;
BEGIN
    result := COUNT_ANNUAL_REWARD(254.365, 36);
    DBMS_OUTPUT.PUT_LINE('Result: ' || result);
END;
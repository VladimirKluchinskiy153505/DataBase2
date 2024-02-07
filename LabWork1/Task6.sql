CREATE OR REPLACE FUNCTION COUNT_ANNUAL_REWARD(
salary NUMBER, deposit_percent_rate NUMBER)
RETURN FLOAT
IS
deposit_rate FLOAT;
reward NUMBER :=0 ;
month_count INTEGER := 12;
BEGIN
    IF salary < 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'Salary must be positive!');
    END IF;
    IF deposit_percent_rate < 0 OR deposit_percent_rate > 100 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Percentage rate must be in range(0..100]');
    END IF;
    
    deposit_rate := deposit_percent_rate/100;
    reward := (1 + deposit_rate)*month_count*salary;
    return reward;
EXCEPTION
    WHEN OTHERS THEN
        --DBMS_OUTPUT.PUT_LINE('Error occured!');
        RAISE_APPLICATION_ERROR(-20003, 'Eror occured!: ' || SQLERRM);
END COUNT_ANNUAL_REWARD;

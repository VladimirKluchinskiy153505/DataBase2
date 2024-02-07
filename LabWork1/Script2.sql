DECLARE
    count_credits NUMBER;
    nom_dog VARCHAR(10);
    date_dog DATE;
BEGIN
    SELECT COUNT(*)
    INTO count_credits
    FROM Credits
    WHERE CLIENTID = 104;
    
    DBMS_OUTPUT.put_line('Кол-во кредитов: ' || count_credits);
END;

DECLARE
    client_id NUMBER;
    num_count NUMBER;
BEGIN
    client_id := 106;
    SELECT COUNT(*)
    INTO num_count
    FROM mytable
    WHERE val < 200;
    
    DBMS_OUTPUT.put_line('Кол-во кредитов: ' || num_count);
    IF num_count > 100000 THEN
        dbms_output.put_line('Good');
    ELSE
        dbms_output.put_line('Bad');
    END IF;
END;

CREATE OR REPLACE FUNCTION CHECK_EVEN_NUM_COUNT RETURN VARCHAR2 IS
    even_count NUMBER :=0;
    odd_count NUMBER := 0;
BEGIN
    SELECT COUNT(*)
    INTO even_count
    FROM mytable
    WHERE MOD(val,2) = 0;
    
     dbms_output.put_line('EVEN count: ' || even_count);
END;
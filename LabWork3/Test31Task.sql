BEGIN
    COMPARE_SCHEMAS('DEVUSER', 'PRODUSER');
END;
BEGIN
    COMPARE_SCHEMAS('PRODUSER', 'DEVUSER');
END;

DECLARE
  v_table_name VARCHAR2(100) := 'STUDENTS';
  v_owner_name VARCHAR2(100) := 'DEVUSER';
BEGIN
  FOR fk_rec IN (SELECT ac.table_name, ac.r_constraint_name
                 FROM all_constraints ac
                 JOIN all_cons_columns acc ON ac.constraint_name = acc.constraint_name
                 WHERE ac.constraint_type = 'R'
                 AND ac.owner = v_owner_name
                 AND acc.table_name = v_table_name)
  LOOP
    DBMS_OUTPUT.PUT_LINE('Table ' || fk_rec.table_name || ' is referenced by foreign key ' || fk_rec.r_constraint_name);
  END LOOP;
END;

BEGIN
SELECT ac.table_name, acc.column_name
FROM all_constraints ac
JOIN all_cons_columns acc ON ac.constraint_name = acc.constraint_name
WHERE ac.constraint_type = 'R'
AND ac.owner = 'DEVUSER' -- Замените OWNER_NAME на имя владельца внешнего ключа
AND ac.constraint_name = 'SYS_C007480'; 
END;
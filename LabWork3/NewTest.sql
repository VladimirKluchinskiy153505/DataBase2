BEGIN
SELECT a.table_name 
FROM all_constraints a 
JOIN all_cons_columns b ON a.constraint_name = b.constraint_name 
WHERE a.constraint_type = 'R' 
AND b.table_name = 'STUDENTS' 
AND a.owner = 'DEVUSER';

SELECT a.table_name, b.constraint_name, b.column_name
FROM all_constraints a 
JOIN all_cons_columns b ON a.r_constraint_name = b.constraint_name 
WHERE a.constraint_type = 'R' 
AND b.table_name = 'STUDENT_GROUPS'
AND a.owner = 'DEVUSER';
--return son

SELECT b.table_name, b.constraint_name, b.column_name
FROM all_constraints a 
JOIN all_cons_columns b ON a.r_constraint_name = b.constraint_name 
WHERE a.constraint_type = 'R' 
AND a.table_name = 'STUDENT_GROUPS'
AND a.owner = 'DEVUSER';
--return father
SELECT table_name, r_constraint_name
            FROM all_constraints
            WHERE constraint_type = 'R'
            AND owner = dev_schema_name
            AND table_name = current_table_name;
            
SELECT b.TABLE_NAME
FROM ALL_CONS_COLUMNS b
JOIN

'STUDENTS'
'STUDENT_GROUPS'
'ACADEMIC_STREAMS'

SELECT a.table_name 
FROM all_constraints a 
JOIN all_cons_columns b ON a.constraint_name = b.constraint_name 
WHERE a.constraint_type = 'R' 
AND a.r_constraint_name IN (SELECT constraint_name FROM all_constraints WHERE table_name = 'STUDENTS' AND owner = 'DEVUSER')
AND a.owner = 'DEVUSER';
END;
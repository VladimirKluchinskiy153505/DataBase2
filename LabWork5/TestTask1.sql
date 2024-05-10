DELETE FROM STUDENTS;
DELETE FROM LESSONS;
DELETE FROM EXAMS;

DELETE FROM logs_students;
DELETE FROM logs_lessons;
DELETE FROM logs_exams;

DELETE FROM logs_scripts;


DECLARE
    input_tables string_array;
BEGIN
    input_tables := string_array('students', 'exams', 'lessons');
    restore_pkg.db_rollback(to_timestamp('2024-05-11 00:16:35', 'YYYY-MM-DD HH24:MI:SS'), input_tables);
    --restore_pkg.db_rollback(600000, input_tables);
END;

DECLARE
    input_tables string_array;
    resultl VARCHAR2(10000);
BEGIN
    input_tables := string_array('students', 'exams', 'lessons');
    resultl := create_html_report(input_tables,to_timestamp('2024-05-11 00:11:39', 'YYYY-MM-DD HH24:MI:SS'));
    dbms_output.put_line(resultl);
END;
    
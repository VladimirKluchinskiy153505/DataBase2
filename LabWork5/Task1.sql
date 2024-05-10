DROP TABLE STUDENTS;
DROP TABLE LESSONS;
DROP TABLE EXAMS;

DROP TABLE logs_students;
DROP TABLE logs_lessons;
DROP TABLE logs_exams;

DROP TABLE logs_scripts;


CREATE TABLE students (
    id   NUMBER PRIMARY KEY,
    name VARCHAR(100),
    age  NUMBER
);

CREATE TABLE lessons (
    id      NUMBER PRIMARY KEY,
    teacher VARCHAR2(100),
    name    VARCHAR2(100)
);

CREATE TABLE exams (
    id        NUMBER PRIMARY KEY,
    exam_date DATE,
    lesson_id NUMBER,
    CONSTRAINT fk_lessons FOREIGN KEY ( lesson_id )
        REFERENCES lessons ( id )
            ON DELETE CASCADE
);

CREATE TABLE logs_students (
    id             NUMBER,
    name           VARCHAR(100),
    age            NUMBER,
    prev_id        NUMBER,
    prev_name      VARCHAR(100),
    prev_age       NUMBER,
    operation_kind VARCHAR(15),
    datetime       TIMESTAMP,
    is_reverted    NUMBER
);

CREATE TABLE logs_lessons (
    id             NUMBER,
    teacher        VARCHAR2(100),
    name           VARCHAR2(100),
    prev_id        NUMBER,
    prev_teacher   VARCHAR2(100),
    prev_name      VARCHAR(100),
    operation_kind VARCHAR(15),
    datetime       TIMESTAMP,
    is_reverted    NUMBER
);

CREATE TABLE logs_exams (
    id             NUMBER,
    exam_date      DATE,
    lesson_id      NUMBER,
    prev_id        NUMBER,
    prev_exam_date DATE,
    prev_lesson_id NUMBER,
    operation_kind VARCHAR(15),
    datetime       TIMESTAMP,
    is_reverted    NUMBER
);

CREATE OR REPLACE TRIGGER arch_students BEFORE
    DELETE OR INSERT OR UPDATE ON students
    FOR EACH ROW
BEGIN
    IF inserting THEN
        INSERT INTO logs_students (
            id,
            name,
            age,
            operation_kind,
            datetime,
            is_reverted
        ) VALUES (
            :new.id,
            :new.name,
            :new.age,
            'INSERT',
            current_timestamp,
            0
        );

    ELSIF updating THEN
        INSERT INTO logs_students (
            id,
            name,
            age,
            prev_id,
            prev_name,
            prev_age,
            operation_kind,
            datetime,
            is_reverted
        ) VALUES (
            :new.id,
            :new.name,
            :new.age,
            :old.id,
            :old.name,
            :old.age,
            'UPDATE',
            current_timestamp,
            0
        );

    ELSIF deleting THEN
        INSERT INTO logs_students (
            prev_id,
            prev_name,
            prev_age,
            operation_kind,
            datetime,
            is_reverted
        ) VALUES (
            :old.id,
            :old.name,
            :old.age,
            'DELETE',
            current_timestamp,
            0
        );

    END IF;
END;
/

CREATE OR REPLACE TRIGGER arch_lessons BEFORE
    DELETE OR INSERT OR UPDATE ON lessons
    FOR EACH ROW
BEGIN
    IF inserting THEN
        INSERT INTO logs_lessons (
            id,
            name,
            teacher,
            operation_kind,
            datetime,
            is_reverted
        ) VALUES (
            :new.id,
            :new.name,
            :new.teacher,
            'INSERT',
            current_date,
            0
        );

    ELSIF updating THEN
        INSERT INTO logs_lessons (
            id,
            name,
            teacher,
            prev_id,
            prev_name,
            prev_teacher,
            operation_kind,
            datetime,
            is_reverted
        ) VALUES (
            :new.id,
            :new.name,
            :new.teacher,
            :old.id,
            :old.name,
            :old.teacher,
            'UPDATE',
            current_date,
            0
        );

    ELSIF deleting THEN
        INSERT INTO logs_lessons (
            prev_id,
            prev_name,
            prev_teacher,
            operation_kind,
            datetime,
            is_reverted
        ) VALUES (
            :old.id,
            :old.name,
            :old.teacher,
            'DELETE',
            current_date,
            0
        );

    END IF;
END;
/

CREATE OR REPLACE TRIGGER arch_exams BEFORE
    DELETE OR INSERT OR UPDATE ON exams
    FOR EACH ROW
BEGIN
    IF inserting THEN
        INSERT INTO logs_exams (
            id,
            exam_date,
            lesson_id,
            operation_kind,
            datetime,
            is_reverted
        ) VALUES (
            :new.id,
            :new.exam_date,
            :new.lesson_id,
            'INSERT',
            current_date,
            0
        );

    ELSIF updating THEN
        INSERT INTO logs_exams (
            id,
            exam_date,
            lesson_id,
            prev_id,
            prev_exam_date,
            prev_lesson_id,
            operation_kind,
            datetime,
            is_reverted
        ) VALUES (
            :new.id,
            :new.exam_date,
            :new.lesson_id,
            :old.id,
            :old.exam_date,
            :old.lesson_id,
            'UPDATE',
            current_date,
            0
        );

    ELSIF deleting THEN
        INSERT INTO logs_exams (
            prev_id,
            prev_exam_date,
            prev_lesson_id,
            operation_kind,
            datetime,
            is_reverted
        ) VALUES (
            :old.id,
            :old.exam_date,
            :old.lesson_id,
            'DELETE',
            current_date,
            0
        );

    END IF;
END;
/

SET SERVEROUTPUT ON SIZE UNLIMITED

CREATE OR REPLACE TYPE string_array AS
    VARRAY(3) OF VARCHAR2(10);
/

CREATE OR REPLACE FUNCTION get_dependent_tables (
    in_table_name IN VARCHAR2
) RETURN string_array AS
    dependent_tables string_array := string_array();
    i                NUMBER;
BEGIN
    FOR relation IN (
        SELECT
            p.table_name,
            ch.table_name child
        FROM
                 user_cons_columns p
            JOIN user_constraints ch ON p.constraint_name = ch.r_constraint_name
        WHERE
            p.table_name = in_table_name
    ) LOOP
        dependent_tables.extend;
        i := i + 1;
        dependent_tables(i) := relation.child;
    END LOOP;

    RETURN dependent_tables;
END;
/

CREATE OR REPLACE PROCEDURE restore_data (
    input_tables IN string_array,
    input_ts     IN TIMESTAMP
) AS
BEGIN
    FOR i IN 1..input_tables.count LOOP
        EXECUTE IMMEDIATE '
            BEGIN
                 restore_'
                          || input_tables(i)
                          || '(TO_TIMESTAMP('''
                          || to_char(input_ts, 'YYYY/MM/DD HH24:MI:SS')
                          || ''', ''YYYY/MM/DDHH24:MI:SS''));
            END;
        ';
    END LOOP;
END;
/

CREATE OR REPLACE PROCEDURE restore_child (
    table_name    IN VARCHAR2,
    restore_until TIMESTAMP
) AS
    child_array string_array;
BEGIN
    child_array := get_dependent_tables(table_name);
    restore_data(child_array, restore_until);
END;
/

CREATE TABLE logs_scripts (
    canceled_operation VARCHAR(10),
    executed_script    VARCHAR(500)
);

CREATE OR REPLACE PROCEDURE restore_students (
    restore_until TIMESTAMP
) AS
    stmt VARCHAR(500);
BEGIN
    FOR logs_row IN (
        SELECT
            id,
            name,
            age,
            prev_id,
            prev_name,
            prev_age,
            operation_kind,
            datetime
        FROM
            logs_students
        WHERE
                datetime > restore_until
            AND is_reverted = 0
        ORDER BY
            datetime DESC
    ) LOOP
        CASE logs_row.operation_kind
            WHEN 'UPDATE' THEN
                stmt := 'UPDATE students SET name = '''
                        || logs_row.prev_name
                        || ''', age = '
                        || logs_row.prev_age
                        || ' WHERE ID = '
                        || logs_row.id;
            WHEN 'DELETE' THEN
                stmt := 'INSERT INTO students(id, name, age) VALUES ('
                        || logs_row.prev_id
                        || ', '''
                        || logs_row.prev_name
                        || ''', '
                        || logs_row.prev_age
                        || ')';
            WHEN 'INSERT' THEN
                stmt := 'DELETE FROM students WHERE ID=' || logs_row.id;
        END CASE;

        EXECUTE IMMEDIATE stmt;
        INSERT INTO logs_scripts (
            canceled_operation,
            executed_script
        ) VALUES (
            logs_row.operation_kind,
            stmt
        );

        restore_child('students', logs_row.datetime);
    END LOOP;

    UPDATE logs_students
    SET
        is_reverted = 1
    WHERE
        datetime > restore_until;

END;
/

CREATE OR REPLACE PROCEDURE restore_lessons (
    restore_until TIMESTAMP
) AS
    stmt VARCHAR(500);
BEGIN
    FOR logs_row IN (
        SELECT
            id,
            teacher,
            name,
            prev_id,
            prev_teacher,
            prev_name,
            operation_kind,
            datetime
        FROM
            logs_lessons
        WHERE
                datetime > restore_until
            AND is_reverted = 0
        ORDER BY
            datetime DESC
    ) LOOP
        CASE logs_row.operation_kind
            WHEN 'UPDATE' THEN
                stmt := 'UPDATE lessons SET teacher = '''
                        || logs_row.prev_teacher
                        || ''', name = '''
                        || logs_row.prev_name
                        || ''' WHERE ID = '
                        || logs_row.id;
            WHEN 'DELETE' THEN
                stmt := 'INSERT INTO lessons(id, tescher, name) VALUES ('
                        || logs_row.prev_id
                        || ', '''
                        || logs_row.prev_teacher
                        || ''', '''
                        || logs_row.prev_name
                        || ''')';
            WHEN 'INSERT' THEN
                stmt := 'DELETE FROM lessons WHERE ID=' || logs_row.id;
        END CASE;

        EXECUTE IMMEDIATE stmt;
        INSERT INTO logs_scripts (
            canceled_operation,
            executed_script
        ) VALUES (
            logs_row.operation_kind,
            stmt
        );

        restore_child('lessons', logs_row.datetime);
    END LOOP;

    UPDATE logs_lessons
    SET
        is_reverted = 1
    WHERE
        datetime > restore_until;

END;
/

CREATE OR REPLACE PROCEDURE restore_exams (
    restore_until TIMESTAMP
) AS
    stmt VARCHAR(500);
BEGIN
    FOR logs_row IN (
        SELECT
            id,
            exam_date,
            lesson_id,
            prev_id,
            prev_exam_date,
            prev_lesson_id,
            operation_kind,
            datetime
        FROM
            logs_exams
        WHERE
                datetime > restore_until
            AND is_reverted = 0
        ORDER BY
            datetime DESC
    ) LOOP
        CASE logs_row.operation_kind
            WHEN 'UPDATE' THEN
                stmt := 'UPDATE exams SET exam_date = (TO_DATE('''
                        || logs_row.prev_exam_date
                        || ''', ''DD.MM.YY''), lesson_id = '
                        || logs_row.prev_lesson_id
                        || ' WHERE ID = '
                        || logs_row.id;
            WHEN 'DELETE' THEN
                stmt := 'INSERT INTO exams(id, exam_date, lesson_id) VALUES ('
                        || logs_row.prev_id
                        || ', TO_DATE('''
                        || logs_row.prev_exam_date
                        || ''', ''DD.MM.YY''), '''
                        || logs_row.prev_lesson_id
                        || ''')';
            WHEN 'INSERT' THEN
                stmt := 'DELETE FROM exams WHERE ID=' || logs_row.id;
        END CASE;

        EXECUTE IMMEDIATE stmt;
        INSERT INTO logs_scripts (
            canceled_operation,
            executed_script
        ) VALUES (
            logs_row.operation_kind,
            stmt
        );

        restore_child('exams', logs_row.datetime);
    END LOOP;

    UPDATE logs_exams
    SET
        is_reverted = 1
    WHERE
        datetime > restore_until;

END;
/

CREATE OR REPLACE PACKAGE restore_pkg AS
    PROCEDURE db_rollback (
        rollback_timestamp IN TIMESTAMP,
        table_names        string_array
    );

    PROCEDURE db_rollback (
        rollback_millisecond IN NUMBER,
        table_names          string_array
    );

END;
/

CREATE OR REPLACE PACKAGE BODY restore_pkg AS

    PROCEDURE db_rollback (
        rollback_timestamp IN TIMESTAMP,
        table_names        string_array
    ) AS
    BEGIN
        restore_data(table_names, rollback_timestamp);
    END;

    PROCEDURE db_rollback (
        rollback_millisecond IN NUMBER,
        table_names          string_array
    ) AS
        rollback_timestamp TIMESTAMP;
    BEGIN
        SELECT
            current_timestamp - INTERVAL '0.001' SECOND * rollback_millisecond
        INTO rollback_timestamp
        FROM
            dual;

        restore_data(table_names, rollback_timestamp);
    END;

END;
/

CREATE OR REPLACE FUNCTION create_html_report (
    table_names IN string_array,
    ts          IN TIMESTAMP
) RETURN VARCHAR2 AS

    html_document    VARCHAR2(10000) := '<!DOCTYPE html>'
                                     || chr(10)
                                     || '<html>'
                                     || chr(10)
                                     || '    <head>'
                                     || chr(10)
                                     || '        <title>Report</title>'
                                     || chr(10)
                                     || '    </head>'
                                     || chr(10)
                                     || '    <body>'
                                     || chr(10);
    sys_ref_c        SYS_REFCURSOR;
    logs_student_row logs_students%rowtype;
    logs_lesson_row  logs_lessons%rowtype;
    logs_exam_row    logs_exams%rowtype;
BEGIN
    FOR i IN 1..table_names.count LOOP
        html_document := html_document
                         || '        <h2>'
                         || table_names(i)
                         || '</h2>'
                         || chr(10);

        CASE table_names(i)
            WHEN 'students' THEN
                OPEN sys_ref_c FOR 'SELECT * FROM logs_students WHERE is_reverted=0 AND datetime > TO_TIMESTAMP('''
                                   || to_char(ts, 'DD-MM-YYYY HH24:MI:SS')
                                   || ''', ''DD-MM-YYYYHH24:MI:SS'')';

                LOOP
                    FETCH sys_ref_c INTO logs_student_row;
                    EXIT WHEN sys_ref_c%notfound;
                    CASE logs_student_row.operation_kind
                        WHEN 'INSERT' THEN
                            html_document := html_document
                                             || '        <p>'
                                             || logs_student_row.operation_kind
                                             || ': ('
                                             || logs_student_row.id
                                             || ', '
                                             || logs_student_row.name
                                             || ', '
                                             || logs_student_row.age
                                             || ')</p>'
                                             || chr(10);
                        WHEN 'DELETE' THEN
                            html_document := html_document
                                             || '        <p>'
                                             || logs_student_row.operation_kind
                                             || ': ('
                                             || logs_student_row.prev_id
                                             || ', '
                                             || logs_student_row.prev_name
                                             || ', '
                                             || logs_student_row.prev_age
                                             || ')</p>'
                                             || chr(10);
                        ELSE
                            html_document := html_document
                                             || '        <p>'
                                             || logs_student_row.operation_kind
                                             || ': ('
                                             || logs_student_row.id
                                             || ', '
                                             || logs_student_row.name
                                             || ', '
                                             || logs_student_row.age
                                             || ') -> ('
                                             || logs_student_row.prev_id
                                             || ', '
                                             || logs_student_row.prev_name
                                             || ', '
                                             || logs_student_row.prev_age
                                             || ')</p>'
                                             || chr(10);
                    END CASE;

                END LOOP;

                CLOSE sys_ref_c;
            WHEN 'lessons' THEN
                OPEN sys_ref_c FOR 'SELECT * FROM logs_lessons WHERE is_reverted=0 AND datetime > TO_TIMESTAMP('''
                                   || to_char(ts, 'DD-MM-YYYY HH24:MI:SS')
                                   || ''', ''DD-MM-YYYYHH24:MI:SS'')';

                LOOP
                    FETCH sys_ref_c INTO logs_lesson_row;
                    EXIT WHEN sys_ref_c%notfound;
                    CASE logs_lesson_row.operation_kind
                        WHEN 'INSERT' THEN
                            html_document := html_document
                                             || '        <p>'
                                             || logs_lesson_row.operation_kind
                                             || ': ('
                                             || logs_lesson_row.id
                                             || ', '
                                             || logs_lesson_row.teacher
                                             || ', '
                                             || logs_lesson_row.name
                                             || ')</p>'
                                             || chr(10);
                        WHEN 'DELETE' THEN
                            html_document := html_document
                                             || '        <p>'
                                             || logs_lesson_row.operation_kind
                                             || ': ('
                                             || logs_lesson_row.prev_id
                                             || ', '
                                             || logs_lesson_row.prev_teacher
                                             || ', '
                                             || logs_lesson_row.prev_name
                                             || ')</p>'
                                             || chr(10);
                        ELSE
                            html_document := html_document
                                             || '        <p>'
                                             || logs_lesson_row.operation_kind
                                             || ': ('
                                             || logs_lesson_row.id
                                             || ', '
                                             || logs_lesson_row.teacher
                                             || ', '
                                             || logs_lesson_row.name
                                             || ') -> ('
                                             || logs_lesson_row.prev_id
                                             || ', '
                                             || logs_lesson_row.prev_teacher
                                             || ', '
                                             || logs_lesson_row.prev_name
                                             || ')</p>'
                                             || chr(10);
                    END CASE;

                END LOOP;

                CLOSE sys_ref_c;
            WHEN 'exams' THEN
                OPEN sys_ref_c FOR 'SELECT * FROM logs_exams WHERE is_reverted=0 AND datetime > TO_TIMESTAMP('''
                                   || to_char(ts, 'DD-MM-YYYY HH24:MI:SS')
                                   || ''', ''DD-MM-YYYYHH24:MI:SS'')';

                LOOP
                    FETCH sys_ref_c INTO logs_exam_row;
                    EXIT WHEN sys_ref_c%notfound;
                    CASE logs_exam_row.operation_kind
                        WHEN 'INSERT' THEN
                            html_document := html_document
                                             || '        <p>'
                                             || logs_exam_row.operation_kind
                                             || ': ('
                                             || logs_exam_row.id
                                             || ', '
                                             || logs_exam_row.exam_date
                                             || ', '
                                             || logs_exam_row.lesson_id
                                             || ')</p>'
                                             || chr(10);
                        WHEN 'DELETE' THEN
                            html_document := html_document
                                             || '        <p>'
                                             || logs_exam_row.operation_kind
                                             || ': ('
                                             || logs_exam_row.prev_id
                                             || ', '
                                             || logs_exam_row.prev_exam_date
                                             || ', '
                                             || logs_exam_row.prev_lesson_id
                                             || ')</p>'
                                             || chr(10);
                        ELSE
                            html_document := html_document
                                             || '        <p>'
                                             || logs_exam_row.operation_kind
                                             || ': ('
                                             || logs_exam_row.id
                                             || ', '
                                             || logs_exam_row.exam_date
                                             || ', '
                                             || logs_exam_row.lesson_id
                                             || ') -> ('
                                             || logs_exam_row.prev_id
                                             || ', '
                                             || logs_exam_row.prev_exam_date
                                             || ', '
                                             || logs_exam_row.prev_lesson_id
                                             || ')</p>'
                                             || chr(10);
                    END CASE;

                END LOOP;

                CLOSE sys_ref_c;
            ELSE
                dbms_output.put_line('undefined table');
        END CASE;

    END LOOP;

    html_document := html_document
                     || '    </body>'
                     || chr(10)
                     || '</html>';
    RETURN html_document;
END;
/

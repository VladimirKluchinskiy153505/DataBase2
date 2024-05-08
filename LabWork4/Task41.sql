-- 1.SELECT. на вход: JSON/XML, где тип-SELECT, имена выходных столбцов, таблиц, условия объединения таблиц и фильтрации.
-- Необходимо реализовать парс входных данных формирование запроса и выполнение его, на выход отдать курсор.
-- 2.Доработать 1., чтобы в качестве условия фильтрации можно было передать вложенный запрос (условия IN, NOT IN, EXISTS, NOT EXISTS).
-- Сформировать запрос, выполнить его, на выход передать курсор.

DROP TYPE LAB4.XMLRecord;
CREATE TYPE LAB4.XMLRecord IS TABLE OF VARCHAR2(1000);
/

CREATE OR REPLACE FUNCTION LAB4.get_value_from_xml(xml_string IN VARCHAR2, xpath IN VARCHAR2)
RETURN XMLRecord AS
    records_length NUMBER := 0; 
    current_record VARCHAR2(50) := ' '; 
    xml_property XMLRecord := XMLRecord(); 
    i NUMBER := 1;
BEGIN
    SELECT EXTRACTVALUE(XMLTYPE(xml_string), xpath ||'[' || i || ']') INTO current_record FROM dual;
    WHILE current_record IS NOT NULL 
    LOOP 
        i := i + 1;
        records_length := records_length + 1;
        xml_property.EXTEND;
        xml_property(records_length) := REPLACE(TRIM(current_record), ' ', '');
        SELECT EXTRACTVALUE(XMLTYPE(xml_string), xpath ||'[' || i || ']') INTO current_record FROM dual;
    END LOOP;
    RETURN xml_property;
END get_value_from_xml;
/
 
CREATE OR REPLACE PACKAGE LAB4.xml_package AS
    FUNCTION process_select_query(xml_string IN VARCHAR2) RETURN SYS_REFCURSOR;
    FUNCTION xml_select (xml_string IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION xml_where (xml_string IN VARCHAR2) RETURN VARCHAR2;
END xml_package;
/

CREATE OR REPLACE PACKAGE BODY LAB4.xml_package AS
    FUNCTION process_select_query(xml_string IN VARCHAR2) 
    RETURN SYS_REFCURSOR AS
        sys_refcur SYS_REFCURSOR;
        select_query_str VARCHAR2(2000);
    BEGIN
        select_query_str := xml_select(xml_string);
        dbms_output.put_line(select_query_str);
        OPEN sys_refcur FOR select_query_str; 
        RETURN sys_refcur;
    END process_select_query;

    FUNCTION xml_select(xml_string IN VARCHAR2) 
    RETURN VARCHAR2 AS
        tables_list XMLRecord := XMLRecord();
        columns_list XMLRecord := XMLRecord();
        filters XMLRecord := XMLRecord();
        join_type VARCHAR2(100);
        join_condition VARCHAR2(100);
        select_query VARCHAR2(1000) := CHR(10) || 'SELECT';
    BEGIN
        IF xml_string IS NULL THEN 
            RETURN NULL;
        END IF;
        
        tables_list := get_value_from_xml(xml_string, 'Operation/Tables/Table');
        columns_list := get_value_from_xml(xml_string, 'Operation/OutputColumns/Column');
         
        select_query := select_query || ' ' || columns_list(1);
        FOR col_index IN 2..columns_list.COUNT 
        LOOP
            select_query := select_query || ', ' || columns_list(col_index);
        END LOOP;
            
        select_query := select_query || CHR(10) ||'FROM ' || tables_list(1); 
        FOR indx IN 2..tables_list.COUNT 
        LOOP
            SELECT EXTRACTVALUE(XMLTYPE(xml_string),'Operation/Joins/Join' ||'[' || (indx - 1) || ']/Type') 
                INTO join_type FROM dual;
            SELECT EXTRACTVALUE(XMLTYPE(xml_string),'Operation/Joins/Join' ||'[' || (indx - 1) || ']/Condition') 
                INTO join_condition FROM dual;
            select_query := select_query || ' ' || join_type || ' ' || tables_list(indx) || CHR(10) || 'ON ' || join_condition;
        END LOOP;
        
        select_query := select_query || CHR(10) || xml_where(xml_string);
        dbms_output.put_line('Result querry..'||select_query);
        RETURN select_query; 
    END xml_select;

    FUNCTION xml_where (xml_string IN VARCHAR2)
    RETURN VARCHAR2 AS
        where_filters XMLRecord := XMLRecord();
        where_clouse VARCHAR2(1000) := 'WHERE';
        condition_body VARCHAR2(100);
        sub_query VARCHAR(1000);
        sub_query1 VARCHAR(1000);
        condition_operator VARCHAR(100);
        current_record VARCHAR2(1000);
        records_length NUMBER :=0;
        i NUMBER := 0; 
    BEGIN
        SELECT EXTRACT(XMLTYPE(xml_string), 'Operation/Where/Conditions/Condition').getStringVal() 
            INTO current_record FROM dual;
         
        WHILE current_record IS NOT NULL 
        LOOP 
            i := i + 1;
            records_length := records_length + 1; 
            where_filters.EXTEND;
            where_filters(records_length) := TRIM(current_record);
            SELECT EXTRACT(XMLTYPE(xml_string),  'Operation/Where/Conditions/Condition' ||'[' || i || ']').getStringVal()
                INTO current_record FROM dual;
        END LOOP;
        
        FOR i IN 2..where_filters.COUNT
        LOOP
            SELECT EXTRACTVALUE(XMLTYPE(where_filters(i)), 'Condition/Body') INTO condition_body FROM dual;
            SELECT EXTRACT(XMLTYPE(where_filters(i)), 'Condition/Operation').getStringVal() INTO sub_query FROM dual;
            SELECT EXTRACTVALUE(XMLTYPE(where_filters(i)), 'Condition/ConditionOperator') INTO condition_operator FROM dual;
            sub_query1 := xml_select(sub_query);
            IF sub_query1 IS NOT NULL THEN 
                sub_query1:= '('|| sub_query1 || ')';
            END IF;
            where_clouse := where_clouse || ' ' || TRIM(condition_body) || ' ' || sub_query1 || TRIM(condition_operator) || ' ';
        END LOOP;
        
        IF where_filters.COUNT = 0 THEN
            RETURN ' ';
        ELSE
            RETURN where_clouse;
        END IF;
    END xml_where;
END xml_package;
/



-- Проверка. Выполнение задания 1 
DROP TABLE LAB4.test_task1_res;
DELETE FROM LAB4.test_task1_res;
/
CREATE TABLE LAB4.test_task1_res(
    exam_id NUMBER,
    exam_date DATE,
    lesson_name VARCHAR2(100)
)
/
DECLARE
    sys_refcur SYS_REFCURSOR;
    test_task1_res_row LAB4.test_task1_res%ROWTYPE; 
BEGIN
    sys_refcur := LAB4.xml_package.process_select_query( 
        '<Operation>
            <QueryType> SELECT </QueryType>
            
            <OutputColumns>
                <Column>LAB4.exams.id</Column>
                <Column>LAB4.exams.exam_date</Column>
                <Column>LAB4.lessons.name</Column>
            </OutputColumns>
            
            <Tables>
                <Table>LAB4.exams</Table>
                <Table>LAB4.lessons</Table>
            </Tables>
            
            <Joins>
                <Join>
                    <Type>LEFT JOIN</Type>
                    <Condition>LAB4.exams.lesson_id = LAB4.lessons.id</Condition>
                </Join>
            </Joins>
            
            <Where>
                <Conditions>
                    <Condition>
                        <Body>LAB4.exams.id = 2</Body>
                    </Condition>
                </Conditions>
            </Where>
        </Operation>');
    LOOP
        FETCH sys_refcur INTO test_task1_res_row;
        EXIT WHEN sys_refcur%NOTFOUND;
        INSERT INTO LAB4.test_task1_res (exam_id, exam_date, lesson_name) 
            VALUES (test_task1_res_row.exam_id, test_task1_res_row.exam_date, test_task1_res_row.lesson_name);
    END LOOP;
    CLOSE sys_refcur;
END;
/    
 
 
-- Проверка работы пакета. Выполнение задания 2 
DROP TABLE LAB4.test_task2_res;
/
CREATE TABLE LAB4.test_task2_res(
    exam_id NUMBER,
    exam_date DATE,
    lesson_name VARCHAR2(100)
)
/
DECLARE
    sys_refcur SYS_REFCURSOR;
    test_task2_res_row LAB4.test_task2_res%ROWTYPE;
BEGIN
    sys_refcur := LAB4.xml_package.process_select_query( 
    '<Operation>
        <QueryType>SELECT</QueryType>
        
        <OutputColumns>
            <Column>exams.id</Column>
            <Column>exams.exam_date</Column>
            <Column>lessons.name</Column>
        </OutputColumns>
        
        <Tables>
            <Table>exams</Table>
            <Table>lessons</Table>
        </Tables>
        
        <Joins>
            <Join>
                <Type>LEFT JOIN</Type>
                <Condition>exams.lesson_id = lessons.id</Condition>
            </Join>
        </Joins>
         
        <Where>
            <Conditions>
                <Condition>
                    <Body>exams.id = 2</Body>
                    <ConditionOperator>OR</ConditionOperator>
                </Condition>
                <Condition>
                    <Body>lessons.name IN</Body>
                    
            
                    <Operation>
                        <QueryType>SELECT</QueryType>
                        <OutputColumns>
                            <Column>name</Column>
                        </OutputColumns>
                        <Tables>
                            <Table>lessons</Table>
                        </Tables>
                        <Where>
                            <Conditions>
                                <Condition>
                                    <Body>difficulty = ''hard''</Body>
                                </Condition>
                            </Conditions>
                        </Where>
                    </Operation>
                    
                    
                </Condition>
            </Conditions>
        </Where>
    </Operation>');
    LOOP
        FETCH sys_refcur INTO test_task2_res_row;
        EXIT WHEN sys_refcur%NOTFOUND;
        INSERT INTO LAB4.test_task2_res (exam_id, exam_date, lesson_name) 
            VALUES (test_task2_res_row.exam_id, test_task2_res_row.exam_date, test_task2_res_row.lesson_name);
    END LOOP;
    CLOSE sys_refcur;
END;
/



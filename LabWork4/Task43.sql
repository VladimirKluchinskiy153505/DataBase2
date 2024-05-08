-- 3.DML: реализовать возможность в качестве xml файла передавать условия для запросов INSERT, UPDATE, DELETE,
-- с реализацией возможности в качестве фильтра передавать как условия, так и подзапросы (Аналогично блоку 2)

CREATE OR REPLACE PACKAGE LAB4.xml_package AS
    FUNCTION process_select_query(xml_string IN VARCHAR2) RETURN SYS_REFCURSOR; 
    FUNCTION xml_select(xml_string IN VARCHAR2) RETURN VARCHAR2; 
    FUNCTION xml_where(xml_string IN VARCHAR2) RETURN VARCHAR2; 
    FUNCTION xml_insert(xml_string IN VARCHAR2) RETURN VARCHAR2; 
    FUNCTION xml_update(xml_string IN VARCHAR2) RETURN VARCHAR2; 
    FUNCTION xml_delete(xml_string IN VARCHAR2) RETURN VARCHAR2;
END xml_package;
/

CREATE OR REPLACE PACKAGE BODY LAB4.xml_package AS

    -- SELECT
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
            SELECT EXTRACTVALUE(XMLTYPE(xml_string),'Operation/Joins/Join' ||'[' || (indx -	1) || ']/Type') 
                INTO join_type FROM dual;
            SELECT EXTRACTVALUE(XMLTYPE(xml_string),'Operation/Joins/Join' ||'[' || (indx -	1) || ']/Condition') 
                INTO join_condition FROM dual;
            select_query := select_query || ' ' || join_type || ' ' || tables_list(indx) || CHR(10) || 'ON ' || join_condition;
        END LOOP;
        
        select_query := select_query || CHR(10) || xml_where(xml_string);
        RETURN select_query; 
    END xml_select;

    FUNCTION xml_where (xml_string IN VARCHAR2 ) 
    RETURN VARCHAR2 AS
        where_filters XMLRecord := XMLRecord();
        where_clouse VARCHAR2(1000) := 'WHERE';
        condition_body VARCHAR2(100);
        sub_query VARCHAR(1000); 
        sub_query1 VARCHAR(1000);
        condition_operator VARCHAR(100); 
        current_record VARCHAR2(1000);
        records_length NUMBER := 0;
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
            SELECT EXTRACT(XMLTYPE(xml_string), 'Operation/Where/Conditions/Condition' ||'[' || i || ']').getStringVal() 
                INTO current_record FROM dual; 
        END LOOP;
        
        FOR i IN 2..where_filters.COUNT
        LOOP
            SELECT EXTRACTVALUE(XMLTYPE(where_filters(i)), 'Condition/Body') INTO condition_body FROM dual;
            SELECT EXTRACT(XMLTYPE(where_filters(i)), 'Condition/Operation').getStringVal() INTO sub_query FROM dual;
            SELECT EXTRACTVALUE(XMLTYPE(where_filters(i)), 'Condition/ConditionOperator') INTO condition_operator FROM dual;
            sub_query1 := xml_select(sub_query);
            IF sub_query1 IS NOT NULL THEN 
                sub_query1 := '('|| sub_query1 || ')';
            END IF;
            where_clouse := where_clouse || ' ' || TRIM(condition_body) || ' ' || sub_query1 || TRIM(condition_operator) || ' ';
        END LOOP;
    
        IF where_filters.COUNT = 0 THEN
            RETURN ' '; 
        ELSE
            RETURN where_clouse;
        END IF;
    END xml_where;

    -- INSERT
    FUNCTION xml_insert(xml_string IN VARCHAR2) 
    RETURN VARCHAR2 AS
        values_to_insert VARCHAR2(1000);
        select_query_to_insert VARCHAR(1000);
        xml_values XMLRecord := XMLRecord();
        xml_columns_list XMLRecord := XMLRecord();
        insert_query VARCHAR2(1000);
        table_name VARCHAR(100); 
        xml_columns VARCHAR2(200);
    BEGIN
        SELECT EXTRACT(XMLTYPE(xml_string), 'Operation/Values').getStringVal() INTO values_to_insert FROM dual;
        SELECT EXTRACTVALUE(XMLTYPE(xml_string), 'Operation/Table') INTO table_name FROM dual;
        
        xml_columns_list := get_value_from_xml(xml_string,'Operation/Columns/Column'); 
        xml_columns:='(' || xml_columns_list(1);
        
        FOR i in 2 .. xml_columns_list.COUNT 
        LOOP
            xml_columns := xml_columns || ', ' || xml_columns_list(i);
        END LOOP;
    
        xml_columns := xml_columns || ')';
        insert_query := CHR(10) || 'INSERT INTO ' || table_name ||xml_columns;
    
    
        IF values_to_insert IS NOT NULL THEN
            xml_values := get_value_from_xml(values_to_insert, 'Values/Value');
            insert_query := insert_query || ' VALUES' || ' (' || xml_values(1) || ')' ;
            
            FOR i in 2 .. xml_values.COUNT 
            LOOP
                insert_query := insert_query || ', (' || xml_values(i) || ') '; 
            END LOOP;
        ELSE
            SELECT EXTRACT(XMLTYPE(xml_string), 'Operation/Operation').getStringVal() INTO select_query_to_insert FROM dual;
            insert_query := insert_query || ' ' || xml_select(select_query_to_insert); 
        END IF;
        RETURN insert_query; 
    end xml_insert;

    -- UPDATE
    FUNCTION xml_update(xml_string IN VARCHAR2)
    RETURN VARCHAR2 AS
        set_collection XMLRecord := XMLRecord(); 
        set_operations VARCHAR2(1000); 
        update_query VARCHAR2(1000) := CHR(10) || 'UPDATE '; 
        table_name VARCHAR(100);
    BEGIN
        SELECT extract(XMLTYPE(xml_string), 'Operation/SetOperations').getStringVal() INTO set_operations FROM dual;
        SELECT EXTRACTVALUE(XMLTYPE(xml_string), 'Operation/Table') INTO table_name FROM dual;
        set_collection := get_value_from_xml(set_operations,'SetOperations/Set');
        update_query := update_query || table_name || ' SET ' || set_collection(1);
        
        FOR i in 2..set_collection.COUNT 
        LOOP
            update_query := update_query || ',' || set_collection(i); 
        END LOOP;
        update_query := update_query || CHR(10) || xml_where(xml_string); 
        RETURN update_query;
    END xml_update;

    -- DELETE
    FUNCTION xml_delete(xml_string IN VARCHAR2)
    RETURN VARCHAR2 AS
        delete_query VARCHAR2(1000) := CHR(10) || 'DELETE FROM ';
        table_name VARCHAR(100); 
    BEGIN
        SELECT EXTRACTVALUE(XMLTYPE(xml_string), 'Operation/Table') INTO table_name FROM dual;
        delete_query := delete_query || table_name || ' ' || xml_where(xml_string);
        RETURN delete_query;
    END xml_delete;
END xml_package;
/


-- Проверка INSERT с подзапросом. Выполнение задания 3
DROP TABLE LAB4.all_exams_list;
/
CREATE TABLE LAB4.all_exams_list(
    id NUMBER,
    exam_date DATE,
    lesson_id NUMBER
)
/
INSERT INTO LAB4.all_exams_list(id, exam_date, lesson_id) VALUES (1, TO_DATE('2024/06/20', 'YYYY/MM/DD'), 1);
/

DECLARE
    script_str VARCHAR(2000); 
BEGIN
    script_str := LAB4.xml_package.xml_insert( '
    <Operation>
        <Type>INSERT</Type>
        <Table>LAB4.exams</Table>
        <Columns>
            <Column>lesson_id</Column>
            <Column>exam_date</Column>
        </Columns>
        
        <Operation>
            <QueryType>SELECT</QueryType>
            <Tables>
                <Table>LAB4.all_exams_list</Table>
            </Tables>
            <OutputColumns>
                <Column>lesson_id</Column>
                <Column>exam_date</Column>
            </OutputColumns>
            <Where>
                <Conditions>
                    <Condition>
                        <Body>id = 1</Body>
                    </Condition>
                </Conditions>
            </Where>
        </Operation>
    </Operation>');
    EXECUTE IMMEDIATE script_str;
    DBMS_OUTPUT.put_line(script_str);
END;
/


-- Проверка UPDATE с подзапросом. Выполнение задания 3
DECLARE
    script_str VARCHAR(2000); 
BEGIN
    script_str := LAB4.xml_package.xml_update( '
    <Operation>
        <Type>UPDATE</Type>
        <Table>LAB4.exams</Table>
        <SetOperations>
            <Set>exam_date = TO_DATE(''2024/01/01'', ''YYYY/MM/DD'')</Set>          
        </SetOperations>
        <Where>
            <Conditions>
                <Condition>
                    <Body>exams.id = 4</Body>
                    <ConditionOperator>OR</ConditionOperator>
                </Condition>
                <Condition>
                    <Body>exams.lesson_id IN</Body>
                    
                    
                    <Operation>
                        <QueryType>SELECT</QueryType>
                        <OutputColumns>
                            <Column>id</Column>
                        </OutputColumns>
                        <Tables>
                            <Table>lessons</Table>
                        </Tables>
                        <Where>
                            <Conditions>
                                <Condition>
                                    <Body>difficulty = ''medium''</Body>
                                </Condition>
                            </Conditions>
                        </Where>
                    </Operation>
                    
                    
                </Condition>
            </Conditions>
        </Where>
    </Operation>');

    EXECUTE IMMEDIATE script_str;
    DBMS_OUTPUT.put_line(script_str);
END;
/


-- Проверка DELETE с подзапросом. Выполнение задания 3
DECLARE
    script_str VARCHAR(2000); 
BEGIN
    script_str := LAB4.xml_package.xml_delete('
    <Operation>
        <Type>DELETE </Type>
        <Table>LAB4.exams</Table>
        <Where>
            <Conditions>
                <Condition>
                    <Body>exams.id = 4</Body>
                 </Condition>
            </Conditions>
        </Where>
    </Operation>');
    EXECUTE IMMEDIATE script_str;
    DBMS_OUTPUT.put_line(script_str);
END;
/
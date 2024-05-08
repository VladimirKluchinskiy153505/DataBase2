-- 4.DDL: возможность генерации и выполнения CREATE TABLE и DROP TABLE. Входные данные: структурированный файл
-- с определением DDL-команды, названием таблицы, в случае необходимости (перечнем полей и их типов).

-- DROP TABLE
CREATE OR REPLACE FUNCTION LAB4.xml_drop_table(xml_string IN VARCHAR2)
RETURN VARCHAR2 AS
    drop_query VARCHAR2(1000):='DROP TABLE ';
    table_name VARCHAR2(100); 
BEGIN
    SELECT EXTRACTVALUE(XMLTYPE(xml_string), 'Operation/Table') INTO table_name FROM dual;
    drop_query := drop_query || table_name; 
    RETURN drop_query;
END xml_drop_table;
/


-- CREATE TABLE
CREATE OR REPLACE FUNCTION LAB4.xml_create_table(xml_string IN VARCHAR2) 
RETURN NVARCHAR2 AS
    col_name VARCHAR2(100);
    col_type VARCHAR(100);
    parent_table VARCHAR2(100);
    constraint_value VARCHAR2(100);
    temporal_record XMLRecord := XMLRecord();
    temporal_string VARCHAR2(100);
    create_query VARCHAR2(1000):= 'CREATE TABLE';
    primary_constraint VARCHAR2(1000); 
    auto_increment_script VARCHAR(1000);
    current_record VARCHAR2(1000); 
    records_length NUMBER :=0;
    table_columns XMLRecord := XMLRecord();
    table_name VARCHAR2(100);
    col_constraints XMLRecord := XMLRecord();
    table_constraints XMLRecord := XMLRecord();
    i NUMBER := 0;
BEGIN
    SELECT EXTRACTVALUE(XMLTYPE(xml_string), 'Operation/Table') INTO table_name FROM dual;
    create_query := create_query || ' ' || table_name || '(';
    SELECT EXTRACT(XMLTYPE(xml_string), 'Operation/Columns/Column').getStringVal() INTO current_record FROM dual;
    
    WHILE current_record IS NOT NULL
    LOOP
        i := i + 1;
        records_length := records_length + 1;
        table_columns.EXTEND;
        table_columns(records_length) := TRIM(current_record);
        SELECT EXTRACT(XMLTYPE(xml_string), 'Operation/Columns/Column' ||'[' || i || ']').getStringVal() 
            INTO current_record FROM dual;
    END LOOP;
    
    FOR i IN 2..table_columns.COUNT 
    LOOP 
        constraint_value := '';
        SELECT EXTRACTVALUE(XMLTYPE(table_columns(i)), 'Column/Name') INTO col_name FROM dual;
        SELECT EXTRACTVALUE(XMLTYPE(table_columns(i)), 'Column/Type') INTO col_type FROM dual;
        col_constraints := get_value_from_xml(table_columns(i),'Column/Constraints/Constraint');
        
        FOR i IN 1..col_constraints.COUNT 
        LOOP
            constraint_value := constraint_value || ' ' || REPLACE(col_constraints(i), '@', ' ');
        END LOOP;
        
        create_query := create_query ||  CHR(10) || '    ' || col_name || ' ' || col_type || constraint_value;
        
        IF i != table_columns.COUNT THEN 
            create_query := create_query || ', ';
        END IF; 
    END LOOP;
    
    SELECT EXTRACT(XMLTYPE(xml_string), 'Operation/TableConstraints/PrimaryKey').getStringVal() 
        INTO primary_constraint FROM dual;
    IF primary_constraint IS NOT NULL THEN
        temporal_record := get_value_from_xml(primary_constraint,'PrimaryKey/Columns/Column');
        temporal_string := temporal_record(1);
        FOR i IN 2..temporal_record.COUNT 
        LOOP
        temporal_string := temporal_string || ', ' || temporal_record(i);
        END LOOP;
        create_query := create_query || ',' || CHR(10) || '    CONSTRAINT ' || REPLACE(table_name, '.', '_') || '_pk '
            || 'PRIMARY KEY (' || temporal_string || ')';
     ELSE
        create_query := create_query || ', ID NUMBER PRIMARY KEY';
    END IF;
    
    table_constraints := XMLRecord();
    records_length := 0;
    i := 0;
    SELECT EXTRACT(XMLTYPE(xml_string), 'Operation/TableConstraints/ForeignKey').getStringVal() INTO current_record FROM dual;
    
    WHILE current_record IS NOT NULL 
    LOOP 
        i := i + 1;
        records_length := records_length + 1;
        table_constraints.EXTEND;
        table_constraints(records_length) := TRIM(current_record);
        SELECT EXTRACT(XMLTYPE(xml_string),  'Operation/TableConstraints/ForeignKey' || '[' || i || ']').getStringVal()
            INTO current_record FROM dual;
    END LOOP;
    
    FOR i IN 2..table_constraints.COUNT 
    LOOP
        SELECT EXTRACTVALUE(XMLTYPE(table_constraints(i)), 'ForeignKey/Parent') INTO parent_table FROM dual;
        
        temporal_record := get_value_from_xml(table_constraints(i), 'ForeignKey/ChildColumns/Column');
        temporal_string := temporal_record(1);
        
        FOR i IN 2..temporal_record.COUNT 
        LOOP
            temporal_string := temporal_string || ', ' || temporal_record(i); 
        END LOOP;
        
        create_query:= create_query || ', '|| CHR(10) || '    CONSTRAINT ' || REPLACE(table_name, '.', '_') || '_' 
            || REPLACE(parent_table, '.', '_') || '_fk ' 
            || CHR(10) || '    FOREIGN KEY' || '(' || temporal_string || ') ';
        temporal_record := get_value_from_xml(table_constraints(i), 'ForeignKey/ChildColumns/Column');
        temporal_string := temporal_record(1);
        
        FOR i IN 2..temporal_record.COUNT 
        LOOP
            temporal_string := temporal_string || ', ' || temporal_record(i); 
        END LOOP;
        
        create_query:= create_query || CHR(10) || '    REFERENCES ' || parent_table || '(' || temporal_string || ')';
    END LOOP;
    
    create_query := create_query || CHR(10) || ')';-- || auto_increment_script;
    RETURN create_query;
END xml_create_table;
/



-- Проверка работы CREATE с простой таблицей. Выполнение задания 4 
DECLARE
    create_table_script_str VARCHAR(2000); 
BEGIN
    create_table_script_str := LAB4.xml_create_table('
    <Operation>
        <Type>CREATE</Type>
        <Table>LAB4.parent_test_table</Table>
        
        <Columns>
            <Column>
                <Name>parent_test_id</Name>
                <Type>NUMBER</Type>
                <Constraints>
                    <Constraint>NOT@NULL</Constraint>
                </Constraints>
            </Column>
            
            <Column>
                <Name>parent_test_name</Name>
                <Type>VARCHAR(100)</Type>
            </Column>
        </Columns>
        
        <TableConstraints>
            <PrimaryKey>
                <Columns>
                    <Column>parent_test_id</Column>
                </Columns>
            </PrimaryKey>
        </TableConstraints>
    </Operation>');
    dbms_output.put_line(create_table_script_str);
    EXECUTE IMMEDIATE create_table_script_str;
END;
/

-- Проверка работы CREATE с FK. Выполнение задания 4
DECLARE
    create_table_script_str VARCHAR(2000); 
BEGIN
    create_table_script_str := LAB4.xml_create_table('
    <Operation>
        <Type>CREATE</Type>
        <Table>LAB4.test_table</Table>
        
        <Columns>
            <Column>
                <Name>test_id</Name>
                <Type>NUMBER</Type>
                <Constraints>
                    <Constraint>NOT@NULL</Constraint>
                </Constraints>
            </Column>
            
            <Column>
                <Name>test_name</Name>
                <Type>VARCHAR(100)</Type>
            </Column>
            
            <Column>
                <Name>parent_test_id</Name>
                <Type>NUMBER</Type>
                <Constraints>
                    <Constraint>NOT@NULL</Constraint>
                </Constraints>
            </Column>
        </Columns>
        
        <TableConstraints>
            <PrimaryKey>
                <Columns>
                    <Column>test_id</Column>
                </Columns>
            </PrimaryKey>
            
            <ForeignKey>
                <ChildColumns>
                    <Column>parent_test_id</Column>
                </ChildColumns>
                <Parent>LAB4.parent_test_table</Parent>
                <ParentColumns>
                    <Column>parent_test_id</Column>
                </ParentColumns>
            </ForeignKey>
        </TableConstraints>
    </Operation>');
    dbms_output.put_line(create_table_script_str);
    EXECUTE IMMEDIATE create_table_script_str;
END;
/


-- Проверка работы DELETE с FK. Выполнение задания 4
DECLARE
    script_str VARCHAR(2000); 
BEGIN
    script_str := LAB4.xml_drop_table('
    <Operation>
        <Type>DROP</Type>
        <Table>LAB4.test_table</Table>
    </Operation>');
    dbms_output.put_line(script_str);
    EXECUTE IMMEDIATE script_str;
END;
/

-- Проверка работы DELETE с простой таблицей. Выполнение задания 4
DECLARE
    script_str VARCHAR(2000); 
BEGIN
    script_str := LAB4.xml_drop_table('
    <Operation>
        <Type>DROP</Type>
        <Table>LAB4.parent_test_table</Table>
    </Operation>');
    dbms_output.put_line(script_str);
    EXECUTE IMMEDIATE script_str;
END;
/
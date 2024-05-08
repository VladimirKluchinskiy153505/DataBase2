--Work with table T2
DROP TABLE LAB4.T2;
DECLARE
    script_str VARCHAR(2000); 
BEGIN
    script_str := LAB4.xml_drop_table('
    <Operation>
        <Type>DROP</Type>
        <Table>LAB4.T2</Table>
    </Operation>');
    dbms_output.put_line(script_str);
    EXECUTE IMMEDIATE script_str;
END;

DECLARE
    create_table_script_str VARCHAR(2000); 
BEGIN
    create_table_script_str := LAB4.xml_create_table('
    <Operation>
        <Type>CREATE</Type>
        <Table>T2</Table>
        <Columns>
            <Column>
                <Name>ID</Name>
                <Type>NUMBER</Type>
                <Constraints>
                    <Constraint>NOT@NULL</Constraint>
                </Constraints>
            </Column>
             <Column>
                <Name>NUM</Name>
                <Type>NUMBER</Type>
            </Column>
            <Column>
                <Name>VAL</Name>
                <Type>VARCHAR(100)</Type>
            </Column>
            <Column>
                <Name>T1_ID</Name>
                <Type>NUMBER</Type>
                <Constraints>
                    <Constraint>NOT@NULL</Constraint>
                </Constraints>
            </Column>
        </Columns>
        <TableConstraints>
            <PrimaryKey>
                <Columns>
                    <Column>ID</Column>
                </Columns>
            </PrimaryKey>
            <ForeignKey>
                <ChildColumns>
                    <Column>T1_ID</Column>
                </ChildColumns>
                <Parent>T1</Parent>
                <ParentColumns>
                    <Column>ID</Column>
                </ParentColumns>
            </ForeignKey>
        </TableConstraints>
    </Operation>');
    dbms_output.put_line('My script:' || create_table_script_str);
    EXECUTE IMMEDIATE create_table_script_str;
END;

INSERT INTO LAB4.T2(NUM, VAL, T1_ID) VALUES (1,'Berlin',1);
INSERT INTO LAB4.T2(NUM, VAL, T1_ID) VALUES (2,'Paris',2);
INSERT INTO LAB4.T2(NUM, VAL, T1_ID) VALUES (3,'Warsaw',3);
INSERT INTO LAB4.T2(NUM, VAL, T1_ID) VALUES (4,'Madrid',4);
INSERT INTO LAB4.T2(NUM, VAL, T1_ID) VALUES (5,'Prague',5);
INSERT INTO LAB4.T2(NUM, VAL, T1_ID) VALUES (6,'Dublin',6);
INSERT INTO LAB4.T2(NUM, VAL, T1_ID) VALUES (7,'Stockholm',7);

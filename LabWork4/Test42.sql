--Work with Table T1
DROP TABLE LAB4.T1;

DECLARE
    script_str VARCHAR(2000); 
BEGIN
    script_str := LAB4.xml_drop_table('
    <Operation>
        <Type>DROP</Type>
        <Table>LAB4.T1</Table>
    </Operation>');
    dbms_output.put_line(script_str);
    EXECUTE IMMEDIATE script_str;
END;

DECLARE
    script_str VARCHAR(2000);
BEGIN
    script_str := LAB4.xml_create_table('
    <Operation>
        <Type>CREATE</Type>
        <Table>T1</Table>
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
        </Columns>
        <TableConstraints>
            <PrimaryKey>
                <Columns>
                    <Column>ID</Column>
                </Columns>
            </PrimaryKey>
        </TableConstraints>
    </Operation>');
    --dbms_output.put_line(script_str);
END;

INSERT INTO LAB4.T1(NUM, VAL) VALUES (10,'London');
INSERT INTO LAB4.T1(NUM, VAL) VALUES (20,'Minsk');
INSERT INTO LAB4.T1(NUM, VAL) VALUES (30,'NewYork');
INSERT INTO LAB4.T1(NUM, VAL) VALUES (40,'Toronto');
INSERT INTO LAB4.T1(NUM, VAL) VALUES (50,'Grodno');
INSERT INTO LAB4.T1(NUM, VAL) VALUES (60,'Moskow');
INSERT INTO LAB4.T1(NUM, VAL) VALUES (70,'Brissago');
INSERT INTO LAB4.T1(NUM, VAL) VALUES (80,'Sevilia');
INSERT INTO LAB4.T1(NUM, VAL) VALUES (90,'Pekin');
INSERT INTO LAB4.T1(NUM, VAL) VALUES (100,'Dno');
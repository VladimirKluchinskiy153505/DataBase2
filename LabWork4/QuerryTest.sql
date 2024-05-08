DROP TABLE LAB4.test_querry_res;
/
CREATE TABLE LAB4.test_querry_res(
    t1_id NUMBER,
    t1_num NUMBER,
    t1_val VARCHAR2(100),
    t2_id NUMBER,
    t2_num NUMBER,
    t2_val VARCHAR2(100)
)
/
DECLARE
    sys_refcur SYS_REFCURSOR;
    test_querry_res_row LAB4.test_querry_res%ROWTYPE;
BEGIN
    sys_refcur := LAB4.xml_package.process_select_query( 
     '<Operation>
        <QueryType>SELECT</QueryType>
        <OutputColumns>
            <Column>T1.ID</Column>
            <Column>T1.NUM</Column>
            <Column>T1.VAL</Column>
            <Column>T2.ID</Column>
            <Column>T2.NUM</Column>
            <Column>T2.VAL</Column>
        </OutputColumns>
        <Tables>
            <Table>T1</Table>
            <Table>T2</Table>
        </Tables>
        <Joins>
            <Join>
                <Type>RIGHT JOIN</Type>
                <Condition>T2.T1_ID = T1.ID</Condition>
            </Join>
        </Joins>
        <Where>
            <Conditions>
                <Condition>
                   <Body>T1.ID IN</Body>
                   <Operation>
                        <QueryType>SELECT</QueryType>
                        <OutputColumns>
                            <Column>ID</Column>
                        </OutputColumns>
                        <Tables>
                            <Table>T2</Table>
                        </Tables>
                        <Where>
                            <Conditions>
                                <Condition>
                                    <Body>NUM between 2 and 4</Body>
                                    <ConditionOperator>AND</ConditionOperator>
                                </Condition>
                                <Condition>
                                    <Body>VAL like ''%a%''</Body>
                                </Condition>
                            </Conditions>
                        </Where>
                    </Operation>
                </Condition>
            </Conditions>
        </Where>
    </Operation>');
    LOOP
        FETCH sys_refcur INTO test_querry_res_row;
        EXIT WHEN sys_refcur%NOTFOUND;
        INSERT INTO LAB4.test_querry_res (t1_id, t1_num, t1_val,t2_id, t2_num, t2_val) 
            VALUES (test_querry_res_row.t1_id, test_querry_res_row.t1_num, test_querry_res_row.t1_val,test_querry_res_row.t2_id, test_querry_res_row.t2_num, test_querry_res_row.t2_val);
    END LOOP;
    CLOSE sys_refcur;
END;
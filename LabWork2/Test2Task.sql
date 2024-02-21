
INSERT INTO GROUPS(NAME)
VALUES ('FirstGroup');

INSERT INTO GROUPS(NAME)
VALUES ('Second_Group');

INSERT INTO GROUPS(NAME)
VALUES ('Third_Group');

SELECT *
FROM GROUPS;

DELETE FROM STUDENTS;
delete from groups;

INSERT INTO STUDENTS(NAME,GROUP_ID) VALUES ('wegwegwg', 100);
INSERT INTO STUDENTS(NAME,GROUP_ID) VALUES ('Abramovich Pavel Nikolaevich', 1);
INSERT INTO STUDENTS(NAME,GROUP_ID) VALUES ('Bybko Alina Andreevna', 1);
INSERT INTO STUDENTS(NAME,GROUP_ID) VALUES  ('Bychko Vasily Pavlovich', 1);
INSERT INTO STUDENTS(NAME,GROUP_ID) VALUES ('Glebtsova Elizaveta Nikolaevna', 2);
INSERT INTO STUDENTS(NAME,GROUP_ID) VALUES ('Grischuk Alexander Olegovich', 2);
INSERT INTO STUDENTS(NAME,GROUP_ID) VALUES ('Short Pavel Igorevich', 2);
INSERT INTO STUDENTS(NAME,GROUP_ID) VALUES ('Kosach Dmitry Anatolyevich', 2);
INSERT INTO STUDENTS(NAME,GROUP_ID) VALUES ('Kudlasevich Artur Ivanovich', 3);
INSERT INTO STUDENTS(NAME,GROUP_ID) VALUES ('Pihtovnikova Maria Timurovna', 3);
INSERT INTO STUDENTS(NAME,GROUP_ID) VALUES ('Stovba Vladislav Alexandrovich', 3);

INSERT ALL 
    INTO STUDENTS(NAME,GROUP_ID) VALUES  ('Bychko Vasily Pavlovich', 1)
    INTO STUDENTS(NAME,GROUP_ID) VALUES ('Glebtsova Elizaveta Nikolaevna', 2)
    INTO STUDENTS(NAME,GROUP_ID) VALUES ('Grischuk Alexander Olegovich', 2)
    INTO STUDENTS(NAME,GROUP_ID) VALUES ('Short Pavel Igorevich', 2)
    INTO STUDENTS(NAME,GROUP_ID) VALUES ('Kosach Dmitry Anatolyevich', 2)
    INTO STUDENTS(NAME,GROUP_ID) VALUES ('Kudlasevich Artur Ivanovich', 3)
    INTO STUDENTS(NAME,GROUP_ID) VALUES ('Pihtovnikova Maria Timurovna', 3)
    INTO STUDENTS(NAME,GROUP_ID) VALUES ('Stovba Vladislav Alexandrovich', 3)
SELECT 1 FROM DUAL;

UPDATE GROUPS
SET C_VAL = 0;
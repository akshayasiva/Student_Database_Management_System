DROP DATABASE IF EXISTS schoolManagementDB;
CREATE DATABASE IF NOT EXISTS schoolManagementDB;
USE SchoolManagementDB;

CREATE TABLE IF NOT EXISTS address_T(
	address_id INTEGER PRIMARY KEY,
	address_1 VARCHAR(30) NOT NULL,
    address_2 VARCHAR(30),
    county VARCHAR (30),
    city VARCHAR(30),
    state VARCHAR(20),
    country VARCHAR(30),
	pincode INTEGER
);

CREATE TABLE IF NOT EXISTS users_T(
	netid CHAR(8) PRIMARY KEY,
    password VARCHAR(20) NOT NULL,
    first_name VARCHAR(30) NOT NULL,
    last_name VARCHAR(30) NOT NULL,
    email_id VARCHAR(40) NOT NULL,
    address_id INTEGER ,
    contact_num VARCHAR(15),
    dob DATE NOT NULL,
    user_category CHAR(1) NOT NULL,
    -- user_category to be made into an enum
    FOREIGN KEY (address_id) REFERENCES address_T(address_id)
);
CREATE TABLE IF NOT EXISTS department_T(
	id INTEGER PRIMARY KEY,
    name VARCHAR(30) NOT NULL,
    school VARCHAR(30) NOT NULL,
    HOD INTEGER 
    -- REFERENCE THIS WITH FACULTY ID
);

CREATE TABLE IF NOT EXISTS concentration_T(
	id INTEGER PRIMARY KEY,
    name VARCHAR(30) NOT NULL,
    department_id INTEGER,
    school VARCHAR(30) NOT NULL,
	FOREIGN KEY (department_id) REFERENCES department_T(id)
);

CREATE TABLE IF NOT EXISTS student_T(
	id INTEGER PRIMARY KEY AUTO_INCREMENT,
    netid CHAR(7),
    current_gpa FLOAT(3,2),
    degree_pursue VARCHAR(5),
    major_pursue INTEGER,
    minor_pursue INTEGER,
    current_year INT,
    completion_year INT,
    credit_hrs INT,
    FOREIGN KEY (netid) REFERENCES users_T(netid),
    FOREIGN KEY (major_pursue) REFERENCES concentration_T(id),
    FOREIGN KEY (major_pursue) REFERENCES concentration_T(id)
);

CREATE TABLE IF NOT EXISTS level_T (
	level INTEGER PRIMARY KEY,
    designation VARCHAR (30),
    salary INTEGER DEFAULT 0
);


CREATE TABLE IF NOT EXISTS adminstaff_T(
	id INTEGER AUTO_INCREMENT PRIMARY KEY,
    netid CHAR(7),
    department_id INTEGER,
    level_num INTEGER,
    
    FOREIGN KEY (netid) REFERENCES users_T(netid),
    FOREIGN KEY (department_id) REFERENCES department_T(id),
    FOREIGN KEY (level_num) REFERENCES level_T(level)
);

CREATE TABLE IF NOT EXISTS rooms_T(
	room_id INTEGER PRIMARY KEY,
    building_name VARCHAR(10),
    capacity INTEGER
);

CREATE TABLE IF NOT EXISTS faculty_T(
	id INTEGER AUTO_INCREMENT PRIMARY KEY,
    netid CHAR(7),
    degree_pursued VARCHAR(5),
    department_id INTEGER,
    level_num INTEGER,
    office INTEGER,
    FOREIGN KEY (netid) REFERENCES users_T(netid),
    FOREIGN KEY (department_id) REFERENCES department_T(id),
    FOREIGN KEY (level_num) REFERENCES level_T(level)
);

CREATE TABLE IF NOT EXISTS courses_T(
	course_id FLOAT(7,2) PRIMARY KEY,
    name VARCHAR (40),
    faculty_id CHAR(7),
    term ENUM('FALL','SPRING','SUMMER'),
    modality ENUM('ONLINE','IN-PERSON','HYBRID'),
    credits INTEGER,
    room_id INTEGER,
    pre_req FLOAT(7,2),
	FOREIGN KEY (faculty_id) REFERENCES faculty_T(netid),
    FOREIGN KEY (room_id) REFERENCES rooms_T(room_id)
);

CREATE TABLE IF NOT EXISTS enrollment_T(
	student_id CHAR(7),
    course_id FLOAT(7,2),
    student_per FLOAT,
    FOREIGN KEY (student_id) REFERENCES student_T(netid),
    FOREIGN KEY (course_id) REFERENCES courses_T(course_id)
);

CREATE TABLE IF NOT EXISTS advisors_T(
	student_id CHAR(7),
    faculty_id CHAR(7),
    FOREIGN KEY (student_id) REFERENCES student_T(netid),
    FOREIGN KEY (faculty_id) REFERENCES faculty_T(netid)
);

CREATE TABLE IF NOT EXISTS parking_T(
	vehicle_num VARCHAR(7) PRIMARY KEY,
    owner_id CHAR(7),
    FOREIGN KEY (owner_id) REFERENCES users_T(netid)
);

CREATE TABLE IF NOT EXISTS book_T(
	book_id INTEGER PRIMARY KEY,
    title VARCHAR(30),
    author VARCHAR(30),
    section VARCHAR(30),
    cost INTEGER
);

CREATE TABLE IF NOT EXISTS bookissue_T(
	borrower_id CHAR(7),
    book_id INTEGER,
    borrow_date DATE DEFAULT NULL,
    deposite_date DATE DEFAULT NULL,
    FOREIGN KEY (borrower_id) REFERENCES users_T(netid),
    FOREIGN KEY (book_id) REFERENCES book_T(book_id)
);

CREATE TABLE IF NOT EXISTS attendence_T(
	student_id CHAR(7),
    course_id FLOAT(7,2),
    date DATE,
    status  ENUM('A','P'),
    FOREIGN KEY (student_id) REFERENCES student_T(netid),
    FOREIGN KEY (course_id) REFERENCES courses_T(course_id)
);

CREATE TABLE IF NOT EXISTS credit_fee_T(
	credits INTEGER,
    fee INTEGER
);

CREATE TABLE IF NOT EXISTS publications_T(
	orchid_id INTEGER,
    author_id CHAR(7),
    dicipline VARCHAR(20),
    journal VARCHAR(20),
    FOREIGN KEY (author_id) REFERENCES users_T(netid)
);

CREATE TABLE IF NOT EXISTS assets_T(
	asset_id INTEGER,
    assset_grp INTEGER, -- Multiple quantity of same object will have same asset_grp but different asset_id.
    asset VARCHAR(30),
    cost INTEGER,
    manufacturer VARCHAR(30),
    vendor VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS assests_use_T(
	asset_id INTEGER,
    owner_id CHAR(7),
	out_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    in_time TIMESTAMP DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS bus_T(
	route INTEGER,
    start_time TIME
);	

CREATE TABLE IF NOT EXISTS busstop_T(
	stop_name VARCHAR(30),
    time_from_source TIME,
    route INTEGER
);

-- 3 function
DELIMITER //
CREATE FUNCTION get_user_type(
	user_id CHAR(7)
)
RETURNS CHAR(1)
DETERMINISTIC
BEGIN
	DECLARE user_type CHAR(1);
	SELECT user_category INTO user_type
    FROM users_T WHERE users_T.netid = user_id;
    RETURN user_type;
END //
DELIMITER ;

DELIMITER //
CREATE FUNCTION get_user_name(
	fname VARCHAR(30),
	lname VARCHAR(30)
)
RETURNS VARCHAR(61)
DETERMINISTIC
BEGIN
	DECLARE name_1 VARCHAR(61);
	SELECT concat(fname,' ',lname) INTO name_1;
    RETURN name_1;
END //
DELIMITER ;

DELIMITER //
CREATE FUNCTION calc_per_atten(
	pre INT,
	abs INT
)
RETURNS FLOAT(4,2)
DETERMINISTIC
BEGIN
	DECLARE result FLOAT(4,2);
	SELECT (pre*100)/(pre+abs) INTO result;
    RETURN result;
END //
DELIMITER ;


    
-- 3 triggers
DELIMITER //
CREATE TRIGGER ins_book_issue BEFORE INSERT ON bookissue_T
FOR EACH ROW
BEGIN
	SET new.borrow_date = curdate();
	IF get_user_type(NEW.borrower_id) = 'S' THEN
		SET NEW.deposite_date = DATE_ADD(curdate(), INTERVAL 7 DAY);
	ELSEIF get_user_type(NEW.borrower_id) = 'A' THEN
		SET NEW.deposite_date = DATE_ADD(curdate(), INTERVAL 10 DAY);
	ELSE
    	SET NEW.deposite_date = DATE_ADD(curdate(), INTERVAL 5 DAY);
	END IF;
END;
//
DELIMITER ;



DELIMITER //
CREATE TRIGGER attendance_check BEFORE INSERT ON attendence_T
FOR EACH ROW
BEGIN
	DECLARE stud_count INT DEFAULT 0;
	select count(*) into stud_count
	from enrollment_T where NEW.student_id = enrollment_T.student_id AND
	NEW.course_id = enrollment_T.course_id;
	IF stud_count <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Student not enrolled for class';
    END IF;
END;
//
DELIMITER ;


DELIMITER //
CREATE TRIGGER password_check BEFORE INSERT ON users_T
FOR EACH ROW
BEGIN
	DECLARE pass_length INT DEFAULT 0;
	DECLARE domain_check INT DEFAULT 0;
	select INSTR(NEW.email_id, "@email.com") into domain_check;
	select length(NEW.password) into pass_length;
	IF domain_check = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Email domain is invalid';
    ELSEIF pass_length <6 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Password should alteast be 6 character long';
	END IF;
END;
//
DELIMITER ;


-- 3 stored procedures
DELIMITER //
CREATE PROCEDURE busChart(
IN ROUTE_NO INT
 )
BEGIN
select t1.stop_name,group_concat(t1.arrival) as arrival_time from(
    select stop_name,cast(addtime(bus_t.start_time,busstop_t.time_from_source) as char) as arrival
	from bus_t inner join busstop_t on bus_t.route = busstop_T.route
	order by arrival asc) t1
    group by t1.stop_name;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE update_gpa(
IN net_id CHAR(7),
IN gpa FLOAT(3,2)
)
BEGIN
UPDATE student_T
SET current_gpa = gpa WHERE
netid = net_id;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE enroll_student(
IN student_id_param CHAR(7),
IN course_id_param FLOAT(7,2)
)
BEGIN
insert into enrollment_T values(student_id_param,course_id_param,0);
END //
DELIMITER ;

INSERT INTO address_T (address_id, address_1, address_2, county, city, state, country, pincode)
VALUES
    (1, '123 Main St', 'Apt 4B', 'Los Angeles', 'Los Angeles', 'CA', 'USA', 90001),
    (2, '456 Elm Rd', 'Apt 1722', 'Collin', 'Texas', 'TX', 'USA', 75252),
    (3, '789 Oak Ln', 'Apt 101', 'Sabine', 'New York', 'NY', 'USA', 07712),
    (4, '101 Maple Ave', 'Apt 78', 'Rains', 'New Jersey', 'NJ', 'USA', 10001),
    (5, '210 Pine St', 'Apt 2C', 'Orange', 'Oregon', 'OR', 'USA', 97005),
    (6, '567 Elm St', 'Apt 3D', 'Novi', 'Michigan', 'MI', 'USA', 39010),
    (7, '678 Oak Ave', 'Suite 202', 'Los Angeles', 'Los Angeles', 'LA', 'USA', 90001),
    (8, '987 Birch Rd', 'Apt 5A', 'King County', 'Washington', 'WA', 'USA', 98101),
    (9, '333 Cedar Ln', 'Apt 67', 'Mason', 'Florida', 'FL', 'USA', 34787),
    (10, '777 Elm St', 'Apt 2B', 'Lynn', 'San Jose', 'AT', 'USA', 30033),
    (11, '454 Oak Ave', 'Suite 303', 'Lee', 'Los Angeles', 'SC', 'USA', 29406),
    (12, '575 Pine Rd', 'Apt 98', 'Keer', 'Bellevue', 'NC', 'USA', 27606),
    (13, '111 Maple St', 'Apt 1A', 'Jones', 'Palo Alto', 'AR', 'USA',71606 ),
    (14, '999 Cedar Rd', 'Suite 102', 'Irion', 'San Jose', 'LA', 'USA', 95050),
    (15, '666 Birch Ave', 'Apt 2112', 'Hood', 'Mississippi', 'MS', 'USA', 39762),
    (16, '232 Oak Ln', 'Apt 4C', 'Hamilton', 'Wisconsin', 'WI', 'USA', 53233),
    (17, '444 Pine Rd', 'Suite 404', 'Hale', 'Colorado', 'CO', 'USA', 80206),
    (18, '888 Cedar St', 'Apt 1166', 'Falls', 'Neveda', 'NV', 'USA', 89015),
    (19, '222 Elm Ave', 'Apt 6D', 'Floyd', 'Montana', 'MT', 'USA', 59758),
    (20, '555 Maple Rd', 'Apt 789', 'Delta ', 'Seattle', 'NM', 'USA', 87106);


INSERT INTO department_T (id, name, school, HOD) VALUES 
    (1, 'MIS', 'JSOM', 1),
    (2, 'Music', 'Performing Arts', 2),
    (3, 'Computer Science', 'Engineering', 3),
    (4, 'Biology', 'Science', 4),
    (5, 'History', 'Arts', 5),
    (6, 'Mathematics', 'Science', 6),
    (7, 'English', 'Arts', 7),
    (8, 'Chemistry', 'Science', 8),
    (9, 'Physics', 'Science', 9),
    (10, 'Psychology', 'Social Sciences', 10),
    (11, 'Economics', 'Social Sciences', 11),
    (12, 'Dance', 'Performing Arts', 12),
    (13, 'Marketing', 'JSOM', 13),
    (14, 'Sociology', 'Social Sciences', 14),
    (15, 'Political Science', 'Social Sciences', 15),
    (16, 'Philosophy', 'Arts', 16),
    (17, 'Mechanical Engineering', 'Engineering', 17),
    (18, 'Electrical Engineering', 'Engineering', 18),
    (19, 'Civil Engineering', 'Engineering', 19),
    (20, 'Finance', 'JSOM', 20);


INSERT INTO users_T VALUES ('netid1', 'pass123', 'Alice', 'Smith', 'alice.smith@email.com', 1, '123-456-7890', '1990-05-15', 'S'),
('netid2', 'pass456', 'Bob', 'Johnson', 'bob.johnson@email.com', 2, '987-654-3210', '1985-08-22', 'A'),
('netid3', 'pass789','Charlie', 'Brown', 'charlie.brown@email.com', 3, '555-123-4567', '1998-02-10', 'S'),
('netid4', 'passabc', 'David', 'Wilson', 'david.wilson@email.com', 4, '111-222-3333', '1982-11-30', 'A'),
('netid5', 'passxyz', 'Emma', 'Davis', 'emma.davis@email.com', 5, '444-555-6666', '1995-07-18', 'S'),
('netid6', 'pass123', 'Frank', 'White', 'frank.white@email.com', 6, '777-888-9999', '1989-04-05', 'A'),
('netid7', 'pass456', 'Grace', 'Adams', 'grace.adams@email.com', 7, '222-333-4444', '1993-09-12', 'S'),
('netid8', 'pass789', 'Henry', 'Johnson', 'henry.johnson@email.com', 8, '666-777-8888', '1980-12-28', 'A'),
('netid9', 'passabc', 'Ivy', 'Lee', 'ivy.lee@email.com', 9, '999-000-1111', '1997-03-25', 'S'),
('netid10', 'passxyz', 'Jack', 'Brown', 'jack.brown@email.com', 10, '333-444-5555', '1987-06-08', 'A'),
('netid11', 'pass123', 'Kate', 'Williams', 'kate.williams@email.com', 11, '000-111-2222', '1991-01-17', 'S'),
('netid12', 'pass456', 'Liam', 'Davis', 'liam.davis@email.com', 12, '888-999-0000', '1984-10-04', 'A'),
('netid13', 'pass789', 'Mia', 'Wilson', 'mia.wilson@email.com', 13, '111-222-3333', '1996-08-20', 'S'),
('netid14', 'passabc', 'Noah', 'Smith', 'noah.smith@email.com', 14, '444-555-6666', '1981-05-13', 'A'),
('netid15', 'passxyz', 'Olivia', 'Johnson', 'olivia.johnson@email.com', 15, '777-888-9999', '1994-02-28', 'S'),
('netid16', 'pass123', 'Paul', 'Adams', 'paul.adams@email.com', 16, '222-333-4444', '1988-09-15', 'A'),
('netid17', 'pass456', 'Quinn', 'White', 'quinn.white@email.com', 17, '555-666-7777', '1992-04-24', 'S'),
('netid18', 'pass789', 'Rachel', 'Lee', 'Rachel.lee@email.com', 18, '888-999-0000', '1983-11-11', 'A'),
('netid19', 'passabc', 'Sam', 'Brown', 'sam.brown@email.com', 19, '333-444-5555', '1999-06-03', 'S'),
('netid20', 'passxyz', 'Tom', 'Johnson', 'tom.johnson@email.com', 20, '000-111-2222', '1986-03-22', 'A'),
('netid21', '123pass', 'Dan', 'Hines', 'dan.hines@email.com', 1, '123-456-7890', '1979-05-15', 'F'),
('netid22', '456pass', 'Mark', 'Bailey', 'mark.bailey@email.com', 2, '987-654-3210', '1980-08-22', 'F'),
('netid23', '789pass','John', 'Snow', 'john.snow@email.com', 3, '555-123-4567', '1981-02-10', 'F'),
('netid24', 'abcpass', 'Jay', 'Bhat', 'jay.bhat@email.com', 4, '111-222-3333', '1972-11-30', 'F'),
('netid25', 'xyzpass', 'Amlan', 'Davis', 'amlan.davis@email.com', 5, '444-555-6666', '1975-07-18', 'F'),
('netid26', '123pass', 'James', 'Hall', 'james.white@email.com', 6, '777-888-9999', '1979-04-05', 'F'),
('netid27', 'qwepass', 'Peter', 'Hines', 'peter.hines@email.com', 1, '213-546-7809', '1967-05-15', 'F'),
('netid28', 'rtypass', 'Garden', 'Arya', 'garden.arya@email.com', 2, '978-645-3120', '1968-08-22', 'F'),
('netid29', 'ikjpass','Shannon', 'Tyrion', 'shannon.tyrion@email.com', 3, '535-923-4967', '1965-02-10', 'F'),
('netid30', 'bnmpass', 'Acre', 'Stark', 'acre.stark@email.com', 4, '198-262-3003', '1965-11-30', 'F');

INSERT INTO concentration_T (id, name, department_id, school) VALUES 
    (1, 'Information Technology', 1, 'JSOM'),
    (2, 'Music Composition', 2, 'Performing Arts'),
    (3, 'Computer Engineering', 3, 'Engineering'),
    (4, 'Biochemistry', 4, 'Science'),
    (5, 'Ancient History', 5, 'Arts'),
    (6, 'Applied Mathematics', 6, 'Science'),
    (7, 'English Literature', 7, 'Arts'),
    (8, 'Organic Chemistry', 8, 'Science'),
    (9, 'Theoretical Physics', 9, 'Science'),
    (10, 'Clinical Psychology', 10, 'Social Sciences'),
    (11, 'Microeconomics', 11, 'Social Sciences'),
    (12, 'Dance Performance', 12, 'Performing Arts'),
    (13, 'Digital Marketing', 13, 'JSOM'),
    (14, 'Criminology', 14, 'Social Sciences'),
    (15, 'International Relations', 15, 'Social Sciences'),
    (16, 'Ethics', 16, 'Arts'),
    (17, 'Mechanical Systems', 17, 'Engineering'),
    (18, 'Electrical Systems', 18, 'Engineering'),
    (19, 'Structural Engineering', 19, 'Engineering'),
    (20, 'Corporate Finance', 20, 'JSOM');


INSERT INTO level_T VALUES 
(1,'President',200000),
(2,'Dean',170000),
(3,'Head of Department',150000),
(4,'Professor',120000),
(5,'Associate Professor',100000),
(6,'Assistant Professor',90000),
(7,'Lecturer',80000),
(8,'Jn Clerk',60000),
(9,'Sn Clerk',50000),
(10, 'Researcher', 85000),
(11, 'Technical Staff', 75000),
(12, 'Analyst', 70000),
(13, 'Coordinator', 65000),
(14, 'Assistant', 60000);
    


INSERT INTO student_T (id,netid, current_gpa, degree_pursue, major_pursue, minor_pursue, current_year, completion_year, credit_hrs)
VALUES (1,'netid1', 3.45, 'MS', 1, 3, 3, 2025, 3),
(2,'netid2', 3.89, 'MS', 2, 3, 2, 2025, 3),
(3,'netid3', 3.88, 'MS', 2, 3, 1, 2025, 3),
(4,'netid4', 3.91, 'MS', 2, 3, 2, 2025, 6),
(5,'netid5', 3.76, 'MS', 2, 3, 1, 2025, 3),
(6,'netid6', 3.67, 'MS', 2, 3, 2, 2025, 2),
(7,'netid7', 3.56, 'MS', 2, 3, 1, 2025, 5),
(8,'netid8', 3.75, 'MS', 2, 3, 2, 2025,6),
(9,'netid9', 3.87, 'MS', 2, 3, 1, 2025, 9),
(10,'netid10', 3.77, 'MS', 2, 3, 2, 2025,10),
(11,'netid11', 3.33, 'MS', 2, 3, 1, 2025, 7),
(12,'netid12', 3.43, 'MS', 2, 3, 2, 2025, 2),
(13,'netid13', 3.54, 'MS', 2, 3, 1, 2025, 6),
(14,'netid14', 3.45, 'MS', 2, 3, 2, 2025, 8),
(15,'netid15', 3.5, 'MS', 2, 3, 1, 2025, 9),
(16,'netid16', 3.6, 'MS', 2, 3, 2, 2025, 2),
(17,'netid17', 3.7, 'MS', 2, 3, 1, 2025, 3),
(18,'netid18', 3.8, 'MS', 2, 3, 2, 2025, 1),
(19,'netid19', 3.6, 'MS', 2, 3, 1, 2025, 5),
(20,'netid20', 3.9, 'MS', 2, 3, 2, 2025, 6);



INSERT INTO faculty_T (netid, degree_pursued, department_id, level_num, office) VALUES 
    ('netid21', 'PhD', 1, 5, 301),
    ('netid22', 'PhD', 2, 6, 202),
    ('netid23', 'PhD', 3, 7, 101),
    ('netid24', 'PhD', 4, 8, 401),
    ('netid25', 'PhD', 1, 9, 202),
    ('netid26', 'PhD', 2, 10, 103),
    ('netid27', 'PhD', 3, 11, 302),
    ('netid28', 'PhD', 4, 12, 402),
    ('netid29', 'PhD', 1, 13, 203),
    ('netid30', 'PhD', 2, 14, 104),
    ('netid21', 'PhD', 3, 14, 303),
    ('netid22', 'PhD', 4, 14, 403),
    ('netid23', 'PhD', 1, 14, 204),
    ('netid24', 'PhD', 2, 14, 105),
    ('netid25', 'PhD', 3, 14, 304),
    ('netid26', 'PhD', 4, 3, 404),
    ('netid27', 'PhD', 1, 1, 205),
    ('netid28', 'PhD', 2, 2, 106),
    ('netid29', 'PhD', 3, 3, 305),
    ('netid30', 'PhD', 4, 4, 405);



INSERT INTO adminstaff_T (id,netid, department_id, level_num) VALUES 
    (1,'netid1', 1, 4),
    (2,'netid2', 2, 5),
    (3,'netid3', 3, 6),
    (4,'netid4', 4, 7),
    (5,'netid5', 1, 8),
    (6,'netid6', 2, 9),
    (7,'netid7', 3, 10),
    (8,'netid8', 4, 11),
    (9,'netid9', 1, 12),
    (10,'netid10', 2, 13),
    (11,'netid11', 3, 11),
    (12,'netid12', 4, 12),
    (13,'netid13', 1, 12),
    (14,'netid14', 2, 12),
    (15,'netid15', 3, 11),
    (16,'netid16', 4, 11),
    (17,'netid17', 1, 12),
    (18,'netid8', 2, 13),
    (19,'netid19', 3, 12),
    (20,'netid20', 4, 12);



INSERT INTO book_T (book_id, title, author, section, cost) VALUES 
    (1, 'The Catcher in the Rye', 'J.D. Salinger', 'Fiction', 15),
    (2, 'To Kill a Mockingbird', 'Harper Lee', 'Fiction', 18),
    (3, '1984', 'George Orwell', 'Science Fiction', 12),
    (4, 'Pride and Prejudice', 'Jane Austen', 'Classic Literature', 20),
    (5, 'The Great Gatsby', 'F. Scott Fitzgerald', 'Fiction', 16),
    (6, 'The Hobbit', 'J.R.R. Tolkien', 'Fantasy', 22),
    (7, 'Harry Potter and the Sorcerer', 'J.K. Rowling', 'Fantasy', 25),
    (8, 'The Lord of the Rings', 'J.R.R. Tolkien', 'Fantasy', 30),
    (9, 'Crime and Punishment', 'Fyodor Dostoevsky', 'Classic Literature', 19),
    (10, 'Moby-Dick', 'Herman Melville', 'Classic Literature', 21),
    (11, 'The Da Vinci Code', 'Dan Brown', 'Mystery', 17),
    (12, 'Brave New World', 'Aldous Huxley', 'Science Fiction', 14),
    (13, 'The Picture of Dorian Gray', 'Oscar Wilde', 'Classic Literature', 18),
    (14, 'The Hitchhiker''s Guide', 'Douglas Adams', 'Science Fiction', 16),
    (15, 'Frankenstein', 'Mary Shelley', 'Classic Literature', 20),
    (16, 'The Odyssey', 'Homer', 'Classic Literature', 23),
    (17, 'The Adventures of Tom Sawyer', 'Mark Twain', 'Fiction', 13),
    (18, 'The Road', 'Cormac McCarthy', 'Fiction', 19),
    (19, 'A Tale of Two Cities', 'Charles Dickens', 'Classic Literature', 22),
    (20, 'Lord of the Flies', 'William Golding', 'Fiction', 17);


INSERT INTO bookissue_T (borrower_id, book_id) VALUES 
    ('netid1', 1),
    ('netid2', 2),
    ('netid3', 3),
    ('netid4', 4),
    ('netid5', 5),
    ('netid6', 6),
    ('netid7', 7),
    ('netid8', 8),
    ('netid9', 9),
    ('netid10', 10),
    ('netid11', 11),
    ('netid12', 12),
    ('netid13', 13),
    ('netid14', 14),
    ('netid15', 15),
    ('netid16', 16),
    ('netid17', 17),
    ('netid18', 18),
    ('netid19', 19),
    ('netid20', 20);


INSERT INTO bus_t VALUES(1,'09:00:00'),(2,'09:10:00'),(3,'09:20:00'),(1,'09:30:00'),(2,'09:40:00'),(3,'09:50:00'),
(4,'10:00:00'),(2,'10:10:00'),(3,'10:20:00'),(1,'10:30:00'),(2,'10:40:00'),(4,'10:50:00'),(1,'11:00:00'),(2,'11:15:00'),
(3,'11:30:00'),(4,'11:45:00'),(2,'12:00:00'),(1,'12:15:00'),(3,'12:30:00'),(4,'12:45:00');

INSERT INTO busstop_t VALUES('Stop A','00:05:00',1),('Stop B','00:10:00',2),('Stop C','00:15:00',3),
('Stop D','00:20:00',4),('Stop E','00:25:00',1),('Stop F','00:30:00',2),('Stop G','00:35:00',3),('Stop H','00:40:00',4),
('Stop A','00:45:00',1),('Stop B','00:50:00',2),('Stop C','00:55:00',3),('Stop D','01:00:00',4),('Stop E','01:05:00',1),
('Stop F','01:10:00',2),('Stop G','01:15:00',3),('Stop A','01:20:00',4),('Stop B','01:25:00',1),('Stop C','01:30:00',2),
('Stop D','01:35:00',3),('Stop E','01:40:00',4);

INSERT INTO credit_fee_T (credits,fee) VALUES(1,1200),
(2,2100),
(3,3000),
(4,3950),
(5,4965),
(6,5900),
(7,6895),
(8,7850),
(9,8825),
(10,9700),
(11,10090),
(12,11000),
(13,11100),
(14,11200),
(15,11300);


INSERT INTO advisors_T (student_id, faculty_id) VALUES 
    ('netid1', 'netid21'),
    ('netid2', 'netid23'),
    ('netid3', 'netid24'),
    ('netid4', 'netid25'),
    ('netid5', 'netid26'),
    ('netid6', 'netid27'),
    ('netid7', 'netid28'),
    ('netid8', 'netid29'),
    ('netid9', 'netid22'),
    ('netid10', 'netid21'),
    ('netid1', 'netid22'),
    ('netid12', 'netid23'),
    ('netid3', 'netid24'),
    ('netid14', 'netid25'),
    ('netid5', 'netid26'),
    ('netid16', 'netid27'),
    ('netid17', 'netid28'),
    ('netid18', 'netid29'),
    ('netid19', 'netid25'),
    ('netid20', 'netid24');


INSERT INTO rooms_T VALUES
(1,'JSOM1',60),(2,'JSOM2',60),(3,'ECS1',10),(4,'ECS1',40),(5,'JSOM1',50),
(6,'JSOM2',50),(7,'ECS1',100),(8,'ECS2',20),(9,'JSOM2',30),(10,'JSOM1',60),
(11,'JSOM2',60),(12,'ECS1',10),(13,'ECS1',40),(14,'JSOM1',50),(15,'JSOM2',50),
(16,'ECS1',100),(17,'ECS2',20),(18,'JSOM2',30),(19,'ECS2',20),(20,'JSOM2',30);


INSERT INTO parking_T (vehicle_num, owner_id) VALUES 
    ('ABC1234', 'netid1'),('DEF5678', 'netid2'),('GHI9012', 'netid3'),('JKL3456', 'netid4'),('MNO7890', 'netid5'),
    ('PQR2345', 'netid6'),('STU6789', 'netid7'),('VWX1234', 'netid8'),('YZA5678', 'netid9'),('BCD9012', 'netid10'),
    ('EFG3456', 'netid11'),('HIJ7890', 'netid12'),('KLM2345', 'netid13'),('NOP6789', 'netid14'),('QRS1234', 'netid15'),
    ('TUV5678', 'netid16'),('WXY9012', 'netid17'),('ZAB3456', 'netid18'),('CDE7890', 'netid19'),('FGH2345', 'netid20');



INSERT INTO publications_T (orchid_id, author_id, dicipline, journal) VALUES 
    (12345, 'netid1', 'Computer Science', 'Journal of Computing'),
    (23456, 'netid2', 'Physics', ' Review Letters'),
    (34567, 'netid3', 'Biology', 'Nature'),
    (45678, 'netid4', 'Chemistry', 'Chemical Physics'),
    (56789, 'netid5', 'Psychology', 'Psychological Review'),
    (67890, 'netid6', 'Mathematics', 'Maths Analysis'),
    (78901, 'netid7', 'Literature', 'Modern Studies'),
    (89012, 'netid8', 'History', ' Historical Review'),
    (90123, 'netid9', 'Sociology', 'American Review'),
    (12340, 'netid10', 'Economics', 'The Economic Journal'),
    (23451, 'netid11', 'Political Science', 'World Politics'),
    (34562, 'netid12', 'Anthropology', 'Anthro'),
    (45673, 'netid13', 'Environmental', 'Technology'),
    (56784, 'netid14', 'Engineering', 'Robotics'),
    (67895, 'netid15', 'Medicine', 'Journal of Medicine'),
    (78906, 'netid16', 'Education', 'Harvard Review'),
    (89017, 'netid17', 'Art History', 'Art Bulletin'),
    (90128, 'netid18', 'Philosophy', 'Philosophical '),
    (12349, 'netid19', 'Geology', 'Geology'),
    (23450, 'netid20', 'Business', 'Harvard Review');
	
INSERT INTO assets_T (asset_id, assset_grp, asset, cost, manufacturer, vendor) VALUES 
    (1, 1, 'Laptop', 1000, 'Dell', 'Vendor A'),
    (2, 1, 'Laptop', 1000, 'HP', 'Vendor B'),
    (3, 2, 'Printer', 500, 'Epson', 'Vendor C'),
    (4, 2, 'Printer', 550, 'HP', 'Vendor D'),
    (5, 3, 'Monitor', 300, 'Samsung', 'Vendor E'),
    (6, 3, 'Monitor', 320, 'LG', 'Vendor F'),
    (7, 4, 'Desktop Computer', 1200, 'Lenovo', 'Vendor G'),
    (8, 4, 'Desktop Computer', 1300, 'Apple', 'Vendor H'),
    (9, 5, 'Projector', 800, 'Sony', 'Vendor I'),
    (10, 5, 'Projector', 850, 'BenQ', 'Vendor J'),
    (11, 6, 'Scanner', 400, 'Canon', 'Vendor K'),
    (12, 6, 'Scanner', 420, 'Brother', 'Vendor L'),
    (13, 7, 'Tablet', 700, 'Microsoft', 'Vendor M'),
    (14, 7, 'Tablet', 750, 'Samsung', 'Vendor N'),
    (15, 8, 'Server', 2000, 'Dell', 'Vendor O'),
    (16, 8, 'Server', 2200, 'HP', 'Vendor P'),
    (17, 9, 'Switch', 600, 'Cisco', 'Vendor Q'),
    (18, 9, 'Switch', 650, 'Juniper', 'Vendor R'),
    (19, 10, 'Router', 500, 'TP-Link', 'Vendor S'),
    (20, 10, 'Router', 520, 'Netgear', 'Vendor T');

INSERT INTO assests_use_T (asset_id, owner_id, out_time, in_time) VALUES 
    (1, 'netid1', '2023-11-16 08:00:00', '2023-11-16 17:00:00'),
    (2, 'netid2', '2023-11-16 09:30:00', '2023-11-16 16:45:00'),
    (3, 'netid3', '2023-11-16 10:15:00', '2023-11-16 18:30:00'),
    (4, 'netid4', '2023-11-16 11:00:00', '2023-11-16 19:15:00'),
    (5, 'netid5', '2023-11-16 13:45:00', '2023-11-16 18:45:00'),
    (6, 'netid6', '2023-11-16 14:30:00', '2023-11-16 19:00:00'),
    (7, 'netid7', '2023-11-16 15:20:00', '2023-11-16 20:00:00'),
    (8, 'netid8', '2023-11-16 16:00:00', '2023-11-16 20:45:00'),
    (9, 'netid9', '2023-11-16 08:45:00', '2023-11-16 16:30:00'),
    (10, 'netid10', '2023-11-16 09:15:00', '2023-11-16 17:45:00'),
    (11, 'netid11', '2023-11-16 10:30:00', '2023-11-16 18:15:00'),
    (12, 'netid12', '2023-11-16 11:45:00', '2023-11-16 19:30:00'),
    (13, 'netid13', '2023-11-16 12:20:00', '2023-11-16 20:00:00'),
    (14, 'netid14', '2023-11-16 13:00:00', '2023-11-16 19:45:00'),
    (15, 'netid15', '2023-11-16 14:00:00', '2023-11-16 23:45:00'),
    (16, 'netid16', '2023-11-16 15:00:00', '2023-11-16 21:45:00'),
    (17, 'netid17', '2023-11-16 16:30:00', '2023-11-16 23:45:00'),
    (18, 'netid18', '2023-11-16 17:45:00', '2023-11-17 01:30:00'),
    (19, 'netid19', '2023-11-16 18:15:00', '2023-11-17 02:15:00'),
    (20, 'netid20', '2023-11-16 19:30:00', '2023-11-17 03:00:00');

INSERT INTO courses_T VALUES
(6301.1,'Database Systems','netid21','FALL','IN-PERSON',3,2,NULL),
(6303.3,'Advanced Database Systems','netid23','FALL','IN-PERSON',3,1,6301.1),
(101.01, 'Introduction to Biology', 'netid21', 'FALL', 'IN-PERSON', 3, 1, 100.00),
(102.02, 'English Composition', 'netid22', 'SPRING', 'ONLINE', 4, 2, 101.01),
(103.03, 'Algebra 1', 'netid23', 'FALL', 'IN-PERSON', 3, 3, 102.02),
(104.04, 'History of World Civilization', 'netid24', 'SUMMER', 'HYBRID', 4, 4, 103.03),
(105.05, 'Introduction to Psychology', 'netid25', 'FALL', 'ONLINE', 3, 5, 104.04),
(106.06, 'Fundamentals of Computer Science', 'netid26', 'SPRING', 'IN-PERSON', 4, 6, 105.05),
(107.07, 'Chemistry 101', 'netid27', 'FALL', 'IN-PERSON', 3, 7, NULL),
(108.08, 'Introduction to Economics', 'netid28', 'SUMMER', 'ONLINE', 4, 8, 107.07),
(109.09, 'Sociology: The Study of Society', 'netid29', 'FALL', 'IN-PERSON', 3, 9, 108.08),
(110.10, 'Statistics', 'netid30', 'SPRING', 'ONLINE', 4, 10, 108.09),
(111.11, 'Art History', 'netid21', 'FALL', 'IN-PERSON', 3, 11, 101.1),
(112.12, 'Political Science', 'netid22', 'SUMMER', 'HYBRID', 4, 12, 111.11),
(113.13, 'Environmental Science', 'netid23', 'FALL', 'ONLINE', 3, 13, 112.12),
(114.14, 'Engineering Principles', 'netid24', 'SPRING', 'IN-PERSON', 4, 14, NULL),
(115.15, 'Introduction to Medicine', 'netid25', 'FALL', 'IN-PERSON', 3, 15, 100.01),
(116.16, 'Education Foundations', 'netid26', 'SUMMER', 'ONLINE', 4, 16, 100.01),
(117.17, 'Business Administration', 'netid27', 'FALL', 'IN-PERSON', 3, 17, 100.01),
(118.18, 'Philosophy 101', 'netid28', 'SPRING', 'HYBRID', 4, 18, 100.01),
(119.19, 'Geology Basics', 'netid29', 'FALL', 'ONLINE', 3, 19, 100.01),
(120.20, 'Introduction to Marketing', 'netid30', 'SUMMER', 'IN-PERSON', 4, 20, 100.01);

INSERT INTO enrollment_T (student_id, course_id, student_per) VALUES 
    ('netid1', 101.01, 90.00),
    ('netid2', 101.01, 85.50),
    ('netid3', 101.01, 78.20),
	('netid4', 101.01, 65.10),
    ('netid5', 101.01, 52.40),
    ('netid6', 101.01, 78.40),
    ('netid7', 101.01, 72.20),
    ('netid8', 101.01, 89.60),
    ('netid9', 101.01, 82.20),
	('netid4', 104.04, 92.85),
    ('netid5', 105.05, 87.80),
    ('netid6', 106.06, 81.30),
    ('netid7', 107.07, 94.60),
    ('netid8', 101.01, 88.20),
    ('netid9', 109.09, 79.90),
    ('netid10', 110.10, 91.80),
    ('netid1', 111.11, 86.90),
    ('netid2', 112.12, 93.40),
    ('netid3', 113.13, 82.70),
    ('netid4', 114.14, 95.60),
    ('netid5', 115.15, 89.10),
    ('netid6', 116.16, 84.20),
    ('netid7', 117.17, 97.00),
    ('netid8', 118.18, 90.50),
    ('netid9', 119.19, 83.80),
    ('netid10', 120.20, 96.30);

INSERT INTO attendence_T (student_id, course_id, date, status) VALUES 
    ('netid1', 101.01, '2023-09-05', 'P'),
    ('netid2', 101.01, '2023-09-05', 'P'),
    ('netid3', 101.01, '2023-09-05', 'A'),
    ('netid4', 101.01, '2023-09-05', 'P'),
    ('netid5', 101.01, '2023-09-05', 'P'),
    ('netid6', 101.01, '2023-09-05', 'A'),
    ('netid7', 101.01, '2023-09-05', 'P'),
    ('netid8', 101.01, '2023-09-05', 'P'),
	('netid1', 101.01, '2023-09-07', 'P'),
    ('netid2', 101.01, '2023-09-07', 'A'),
    ('netid3', 101.01, '2023-09-07', 'A'),
    ('netid4', 101.01, '2023-09-07', 'A'),
    ('netid5', 101.01, '2023-09-07', 'P'),
    ('netid6', 101.01, '2023-09-07', 'P'),
    ('netid7', 101.01, '2023-09-07', 'P'),
    ('netid8', 101.01, '2023-09-07', 'P');


 -- Call to procedures               
call buschart(1);
call update_gpa('netid1',3.45);
call enroll_student('netid3',103.03);

-- 10 Queries

-- self join
select c1.name as course , c2.name as pre_requisite
from courses_T c1 join courses_T c2
on c1.pre_req = c2.course_id;


select student_id,get_user_name(users_T.first_name,users_T.last_name) as 'Name', student_per, dense_rank() over (order by student_per desc) as 'rank'
from enrollment_T inner join users_T on users_T.netid = enrollment_T.student_id
where enrollment_T.course_id = 101.01;

select manufacturer,sum(cost) as Total_purchases, rank() over (order by sum(cost) DESC) as 'rn' from assets_T
group by manufacturer 
order by Total_purchases DESC;


select faculty_T.netid, get_user_name(users_T.first_name,users_T.last_name) as Name,faculty_T.level_num
from faculty_T inner join users_T on faculty_T.netid = users_T.netid
where department_id in (select department_id from department_T where name in ('MIS','Computer Science','Biology'))
order by level_num;

with cte as (
	select enrollment_T.course_id,avg(student_per) as avg_score_sub 
	from enrollment_T group by enrollment_T.course_id
)
select enrollment_T.student_id , get_user_name(users_T.first_name,users_T.last_name) as Name,
courses_T.course_id,enrollment_T.student_per, avg_score_sub from enrollment_T inner join cte on 
enrollment_T.course_id = cte.course_id inner join courses_T on courses_T.course_id = enrollment_T.course_id
inner join users_T on users_T.netid = enrollment_T.student_id;

select get_user_name(u1.first_name,u1.last_name) as Student_Name , get_user_name(u2.first_name,u2.last_name) as Faculty_Name
from advisors_t inner join users_T u1 on advisors_T.student_id = u1.netid inner join
users_T u2 on advisors_T.faculty_id = u2.netid;



with cte as(
select date, status,count(status)  as cnt from attendence_T where course_id = 101.01 group by date,status 
)select date,
max(case when status = 'P' then cnt end) as Count_of_Presence,
max(case when status = 'A' then cnt end) as Count_of_Absence,
max(case when status = 'A' then cnt end) + max(case when status = 'P' then cnt end) as "Total Count",
calc_per_atten(max(case when status = 'P' then cnt end),max(case when status = 'A' then cnt end)) as "Percent Of Presence"
from cte
group by date;

select state, count(1) as cnt from address_T
group by state
order by cnt desc
limit 3
offset 1;

select building_name, sum(capacity) from rooms_T
group by building_name
order by building_name;

select level,count(1) from faculty_T inner join level_T on faculty_T.level_num = level_T.level
group by level;




-- Uncomment and Run below query to test trigger 2, it will throw error stating student not enrolled. 
-- INSERT INTO attendence_T (student_id, course_id, date, status) VALUES 
-- ('netid1', 104.04, '2023-09-05', 'P');

-- Uncomment and Run below queries to test trigger 3, it will throw 2 different errors for not meeting credential requirements. 

-- INSERT INTO users_T VALUES ('netid61', 'pass', 'Alice', 'Smith', 'alice.smith@email.com', 1, '123-456-7890', '1990-05-15', 'S');
-- INSERT INTO users_T VALUES ('netid41', 'pass1234', 'Alice', 'Smith', 'alice.smith@gmail.com', 1, '123-456-7890', '1990-05-15', 'S');

-- 6 joins
select student_T.* , credit_fee_T.fee from 
student_T inner join credit_fee_T on 
student_T.credit_hrs = credit_fee_T.credits;

select adminstaff_T.netid , get_user_name(users_T.first_name,users_T.last_name) as 'Name',level_T.designation,
department_T.name from users_T inner join adminstaff_T on users_T.netid = adminstaff_T.netid 
inner join department_T on department_T.id = adminstaff_T.department_id
inner join level_T on adminstaff_T.level_num = level_T.level;

select assets_T.asset_id,asset,owner_id,out_time,in_time
from assets_T inner join assests_use_T on assests_use_T.asset_id = assets_T.asset_id;

select get_user_name(users_T.first_name,users_T.last_name) as Name,
enrollment_T.course_id , courses_T.name from
student_T inner join enrollment_T on student_T.netid = enrollment_T.student_id
inner join courses_T on enrollment_T.course_id = courses_T.course_id
inner join users_T on student_T.netid = users_T.netid;

select book_T.book_id,bookissue_T.borrower_id,get_user_name(users_T.first_name,users_T.last_name) as Name,
users_T.email_id,book_T.title,bookissue_T.borrow_date,bookissue_T.deposite_date
from book_T inner join bookissue_T on bookissue_T.book_id = book_T.book_id inner join users_T on
bookissue_T.borrower_id = users_T.netid;

select student_T.netid, get_user_name(users_T.first_name,users_T.last_name) as 'Name',credit_hrs,credit_fee_T.fee
from student_T inner join users_T on student_T.netid = users_T.netid inner join
credit_fee_T on credit_fee_T.credits = student_T.credit_hrs;


-- Drop FUNCTIONS/TRIGGERS/PROCEDURES
DROP FUNCTION IF EXISTS get_user_type;
DROP FUNCTION IF EXISTS get_user_name;
DROP FUNCTION IF EXISTS calc_per_atten;
DROP TRIGGER IF EXISTS ins_book_issue;
DROP TRIGGER IF EXISTS attendance_check;
DROP TRIGGER IF EXISTS password_check;
DROP PROCEDURE IF EXISTS buschart;
DROP PROCEDURE IF EXISTS update_gpa;
DROP PROCEDURE IF EXISTS enroll_student;
-- Drop Table
DROP TABLE IF EXISTS advisorS_T;
DROP TABLE IF EXISTS parking_T;
DROP TABLE IF EXISTS bookissue_T;
DROP TABLE IF EXISTS book_T;
DROP TABLE IF EXISTS attendence_T;
DROP TABLE IF EXISTS credit_fee_T;
DROP TABLE IF EXISTS publications_T;
DROP TABLE IF EXISTS assets_T;
DROP TABLE IF EXISTS assests_use_T;
DROP TABLE IF EXISTS busstop_T;
DROP TABLE IF EXISTS bus_T;
DROP TABLE IF EXISTS enrollment_T;
DROP TABLE IF EXISTS student_T;
DROP TABLE IF EXISTS concentration_T;
DROP TABLE IF EXISTS courses_T;
DROP TABLE IF EXISTS adminstaff_T;
DROP TABLE IF EXISTS faculty_T;
DROP TABLE IF EXISTS department_T;
DROP TABLE IF EXISTS rooms_T;
DROP TABLE IF EXISTS users_T;
DROP TABLE IF EXISTS address_T;

-- Drop Database
DROP DATABASE schoolManagementDB;
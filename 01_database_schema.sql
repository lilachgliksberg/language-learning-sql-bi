
--Table Creation

CREATE TABLE LANGUAGES(		
	LanguageName		Varchar(20)		PRIMARY KEY NOT NULL,
	Status				Bit				NULL
)

CREATE TABLE USERS(
	Email				Varchar(40)		PRIMARY KEY NOT NULL,
	NameFirst			Varchar(20)		NULL, 
	NameLast			Varchar(20)		NULL, 
	UserPassword		Varchar(20)		NOT NULL,
	CountryOfOrigin		Varchar(20)		NULL
)

CREATE TABLE CREDIT_CARDS(   
	CardNumber			Varchar(16)		PRIMARY KEY NOT NULL,
	ExpirationDate		Date			NOT NULL,
	CVV					Varchar(3)		NOT NULL
)

CREATE TABLE STUDENTS(
    Student				Varchar(40)		PRIMARY KEY NOT NULL, 

    CONSTRAINT FK_Students_Users
    FOREIGN KEY (Student)			
    REFERENCES USERS(Email)
)
	
CREATE TABLE TUTORS(
	Tutor				Varchar(40)		PRIMARY KEY NOT NULL, 
	Rate				Money			NOT NULL,			
	PromotionalVideo	Varchar(100)	NULL,


	CONSTRAINT FK_Tutors_Users
    FOREIGN KEY (Tutor)			
    REFERENCES USERS(Email)
)



CREATE TABLE REVIEWS(
	Student				Varchar(40)		NOT NULL,
	Review				Int				NOT NULL,
	ReviewText			Varchar(100)	NULL,  
	Grade				TinyInt			NULL,
	Tutor				Varchar(40)		NOT NULL,

	CONSTRAINT PK_Reviews
	PRIMARY KEY (Student, Review),
	
	CONSTRAINT FK_Reviews_Students
    FOREIGN KEY (Student)
    REFERENCES STUDENTS(Student),

    CONSTRAINT FK_Reviews_Tutors
    FOREIGN KEY (Tutor)
    REFERENCES TUTORS(Tutor)
)



CREATE TABLE BOOKINGS(
	Booking				Int				PRIMARY KEY NOT NULL,
	NumberOfLessons		TinyInt			NOT NULL,
	TotalPrice			Money			NOT NULL,
	Student				Varchar(40)		NOT NULL,
	CreditCard			Varchar(16)		NOT NULL,

	CONSTRAINT FK_Bookings_Students
	FOREIGN KEY (Student)
	REFERENCES STUDENTS(Student),

	CONSTRAINT FK_Bookings_CreditCards
	FOREIGN KEY (CreditCard)
	REFERENCES CREDIT_CARDS(CardNumber)
)


CREATE TABLE LESSONS(
	Tutor				Varchar(40)		NOT NULL,
	StartDT				DateTime		NOT NULL,
	Duration			TinyInt			NOT NULL,
	Status				Varchar(20)		NOT NULL,
	Link				Varchar(100)	NULL,
	Booking				Int				NOT NULL,

	CONSTRAINT PK_Lessons
	PRIMARY KEY (Tutor, StartDT),

	CONSTRAINT FK_Lessons_Tutors
	FOREIGN KEY (Tutor)
	REFERENCES TUTORS(Tutor),

	CONSTRAINT FK_Lessons_Bookings
	FOREIGN KEY (Booking)
	REFERENCES BOOKINGS(Booking)
)


CREATE TABLE TEACHING(
	Tutor				Varchar(40)		NOT NULL,
	LanguageName		Varchar(20)		NOT NULL,
	Level				Varchar(2)		NOT NULL,	

	CONSTRAINT PK_Teaching
	PRIMARY KEY (Tutor, LanguageName),

	CONSTRAINT FK_Teaching_Tutors
	FOREIGN KEY (Tutor)
	REFERENCES TUTORS(Tutor),

	CONSTRAINT FK_Teaching_LanguageName
	FOREIGN KEY (LanguageName)
	REFERENCES LANGUAGES(LanguageName)
)


CREATE TABLE STUDYING(
	Student				Varchar(40)		NOT NULL,
	LanguageName		Varchar(20)		NOT NULL,
	CurrentLevel		Varchar(2)		NULL, 
	TargetLevel			Varchar(2)		NULL, 


	CONSTRAINT PK_Studying
	PRIMARY KEY (Student, LanguageName),

	CONSTRAINT FK_Studying_Students
	FOREIGN KEY (Student)
	REFERENCES STUDENTS(Student),

	CONSTRAINT FK_Studying_LanguageName
	FOREIGN KEY (LanguageName)
	REFERENCES LANGUAGES(LanguageName)
)


-- CHECK CONSTRAINTS


ALTER TABLE USERS
ADD CONSTRAINT CK_Users_UserPassword
CHECK (
    LEN(UserPassword) >= 8
    AND UserPassword LIKE '%[A-Z]%'
    AND UserPassword LIKE '%[a-z]%'
    AND UserPassword LIKE '%[0-9]%')

ALTER TABLE USERS
ADD CONSTRAINT CK_Users_Email
CHECK (Email LIKE '%@%.%')


ALTER TABLE CREDIT_CARDS
ADD CONSTRAINT CK_CreditCards_CardNumber
CHECK (CardNumber NOT LIKE '%[^0-9]%' AND LEN(CardNumber) = 16)

ALTER TABLE CREDIT_CARDS
ADD CONSTRAINT CK_CreditCards_CVV
CHECK (CVV NOT LIKE '%[^0-9]%' AND LEN(CVV) = 3)

ALTER TABLE CREDIT_CARDS
ADD CONSTRAINT CK_CreditCards_ExpirationDate
CHECK (DAY(ExpirationDate) = 1)


ALTER TABLE TUTORS
ADD CONSTRAINT CK_Tutors_Rate
CHECK (Rate > 0)


ALTER TABLE REVIEWS
ADD CONSTRAINT CK_Reviews_Grade
CHECK (Grade BETWEEN 1 AND 5)


ALTER TABLE BOOKINGS
ADD CONSTRAINT CK_Bookings_NumberOfLessons
CHECK (NumberOfLessons BETWEEN 1 AND 10)

ALTER TABLE BOOKINGS
ADD CONSTRAINT CK_Bookings_TotalPrice
CHECK (TotalPrice >= 0)



ALTER TABLE LESSONS
ADD CONSTRAINT CK_Lessons_Duration
CHECK (Duration BETWEEN 15 AND 180)


--LOOKUP Tables

CREATE TABLE LEVELS(
    LevelCode		Varchar(2)		PRIMARY KEY NOT NULL
)

INSERT INTO LEVELS
VALUES
('A1'),
('A2'),
('B1'),
('B2'),
('C1'),
('C2')

ALTER TABLE TEACHING
ADD CONSTRAINT FK_Teaching_Levels
FOREIGN KEY (Level)
REFERENCES LEVELS(LevelCode)

ALTER TABLE STUDYING
ADD CONSTRAINT FK_Studying_CurrentLevels
FOREIGN KEY (CurrentLevel)
REFERENCES LEVELS(LevelCode)

ALTER TABLE STUDYING
ADD CONSTRAINT FK_Studying_TargetLevels
FOREIGN KEY (TargetLevel)
REFERENCES LEVELS(LevelCode)


CREATE TABLE LESSON_STATUSES(
    LessonStatus	VARCHAR(20)		PRIMARY KEY NOT NULL
)

INSERT INTO LESSON_STATUSES
VALUES
('Scheduled'),
('Completed'),
('Cancelled'),
('Pending')

ALTER TABLE LESSONS
ADD CONSTRAINT FK_Lessons_Statuses
FOREIGN KEY (Status)
REFERENCES LESSON_STATUSES(LessonStatus)


--Data Insertion


INSERT INTO LANGUAGES
VALUES
('English', 1),
('Spanish', 1),
('French', 1),
('German', 0),
('Hebrew', 1)



INSERT INTO USERS
VALUES
('lilachgl@gmail.com', 'Lilach', 'Gliksberg', 'Lilach123A', 'Israel'),
('mayasinger@gmail.com', 'Maya', 'Singer', 'Maya456B', 'Israel'),
('leenoy@gmail.com', 'Lee', 'Noy', 'Leeeeee789C', 'Israel'),
('tom1234@gmail.com', 'Tom', 'Holland', 'Study123D', 'USA'),
('omeradam@gmail.com', 'Omer', 'Adam', 'OmerOmer123', 'UAE'),
('adireven@gmail.com', 'Adir', 'Even', 'ADIReven012', 'India'),
('boazg@gmail.com', 'Boaz', 'Gordon', 'BOaz123345', 'Japan'),
('yonatanvak@gmail.com', 'Yonatan', 'Vaknin', 'YoVa1998', 'Netherlands'),
('tomerdav@walla.com', 'Tomer', 'Davidson', 'TOMdav6789', 'USA'),
('adilevi@gmail.com', 'Adi', 'Levi', 'AdiLE4321', 'Thailand')


INSERT INTO CREDIT_CARDS
VALUES
('1234567812345678', '2027-08-01', '123'),
('1111222233334444', '2028-05-01', '456'),
('5555666677778888', '2029-01-01', '789'),
('9999000011112222', '2027-11-01', '321'),
('4444333322221111', '2030-03-01', '654')


INSERT INTO STUDENTS
VALUES
('lilachgl@gmail.com'),
('mayasinger@gmail.com'),
('leenoy@gmail.com'),
('tomerdav@walla.com'),
('adilevi@gmail.com')


INSERT INTO TUTORS
VALUES
('tom1234@gmail.com', 120, 'https://video1.com'),
('omeradam@gmail.com', 150, 'https://video2.com'),
('adireven@gmail.com', 140, NULL),
('boazg@gmail.com', 140, NULL),
('yonatanvak@gmail.com', 135, 'https://video5.com')



INSERT INTO BOOKINGS
VALUES
(1, 5, 600, 'lilachgl@gmail.com', '1234567812345678'),
(2, 3, 450, 'mayasinger@gmail.com', '1111222233334444'),
(3, 2, 300, 'leenoy@gmail.com', '5555666677778888'),
(4, 4, 520, 'tomerdav@walla.com', '9999000011112222'),
(5, 1, 170, 'adilevi@gmail.com', '4444333322221111'),
(6, 2, 240, 'lilachgl@gmail.com', '1234567812345678')


INSERT INTO REVIEWS
VALUES
('lilachgl@gmail.com', 1, 'Great lesson', 5, 'tom1234@gmail.com'),
('mayasinger@gmail.com', 1, 'Very helpful', 4, 'omeradam@gmail.com'),
('leenoy@gmail.com', 1, 'Good tutor', 5, 'tom1234@gmail.com'),
('tomerdav@walla.com', 1, 'Clear explanation', 4, 'boazg@gmail.com'),
('adilevi@gmail.com', 1, 'Excellent teacher', 5, 'yonatanvak@gmail.com'),
('lilachgl@gmail.com', 2, 'Very professional tutor', 5, 'yonatanvak@gmail.com')



INSERT INTO LESSONS
VALUES
('tom1234@gmail.com', '2026-06-01 10:00:00', 60, 'Scheduled', 'https://lesson1.com', 1),
('omeradam@gmail.com', '2026-06-02 12:00:00', 90, 'Completed', 'https://lesson2.com', 2),
('tom1234@gmail.com', '2026-06-03 14:00:00', 45, 'Pending', NULL, 3),
('boazg@gmail.com', '2026-06-04 16:00:00', 60, 'Scheduled', 'https://lesson4.com', 4),
('yonatanvak@gmail.com', '2026-06-05 18:00:00', 30, 'Cancelled', NULL, 5),
('adireven@gmail.com', '2026-06-06 09:00:00', 60, 'Completed', 'https://lesson6.com', 1),
('boazg@gmail.com', '2026-06-07 11:00:00', 75, 'Scheduled', 'https://lesson7.com', 2),
('yonatanvak@gmail.com', '2026-06-08 13:00:00', 120, 'Pending', NULL, 3)



INSERT INTO TEACHING
VALUES
('tom1234@gmail.com', 'English', 'C2'),
('tom1234@gmail.com', 'French', 'B2'),
('omeradam@gmail.com', 'Spanish', 'C1'),
('boazg@gmail.com', 'German', 'B2'),
('adireven@gmail.com', 'English', 'C1'),
('yonatanvak@gmail.com', 'Hebrew', 'C2')


INSERT INTO STUDYING
VALUES
('lilachgl@gmail.com', 'English', 'A2', 'B2'),
('mayasinger@gmail.com', 'Spanish', 'B1', 'C1'),
('leenoy@gmail.com', 'French', 'A1', 'B1'),
('tomerdav@walla.com', 'German', 'A2', 'B1'),
('adilevi@gmail.com', 'Hebrew', 'B1', 'C1'),
('lilachgl@gmail.com', 'Spanish', 'A1', 'B1'),
('adilevi@gmail.com', 'English', 'B2', 'C1')


--Table Dropping

ALTER TABLE STUDYING
DROP CONSTRAINT PK_Studying,
                 FK_Studying_Students,
                 FK_Studying_LanguageName,
                 FK_Studying_CurrentLevels,
                 FK_Studying_TargetLevels

ALTER TABLE TEACHING
DROP CONSTRAINT PK_Teaching,
                 FK_Teaching_Tutors,
                 FK_Teaching_LanguageName,
                 FK_Teaching_Levels

ALTER TABLE LESSONS
DROP CONSTRAINT PK_Lessons,
                 FK_Lessons_Tutors,
                 FK_Lessons_Bookings,
                 FK_Lessons_Statuses,
                 CK_Lessons_Duration

ALTER TABLE REVIEWS
DROP CONSTRAINT PK_Reviews,
                 FK_Reviews_Students,
                 FK_Reviews_Tutors,
                 CK_Reviews_Grade

ALTER TABLE BOOKINGS
DROP CONSTRAINT FK_Bookings_Students,
                 FK_Bookings_CreditCards,
                 CK_Bookings_NumberOfLessons,
                 CK_Bookings_TotalPrice

ALTER TABLE TUTORS
DROP CONSTRAINT FK_Tutors_Users,
                 CK_Tutors_Rate

ALTER TABLE STUDENTS
DROP CONSTRAINT FK_Students_Users

ALTER TABLE CREDIT_CARDS
DROP CONSTRAINT CK_CreditCards_CardNumber,
                 CK_CreditCards_CVV,
                 CK_CreditCards_ExpirationDate

ALTER TABLE USERS
DROP CONSTRAINT CK_Users_UserPassword,
                 CK_Users_Email


DROP TABLE STUDYING

DROP TABLE TEACHING

DROP TABLE LESSONS

DROP TABLE REVIEWS

DROP TABLE BOOKINGS

DROP TABLE TUTORS

DROP TABLE STUDENTS

DROP TABLE CREDIT_CARDS

DROP TABLE USERS

DROP TABLE LESSON_STATUSES

DROP TABLE LEVELS

DROP TABLE LANGUAGES
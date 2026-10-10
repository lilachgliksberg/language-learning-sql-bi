--===================================================================================================
--מטלה 1
--===================================================================================================

--שאילתה רגילה 1

SELECT T.Tutor AS TutorEmail,
       CONCAT(U.NameFirst, ' ', U.NameLast) AS TutorFullName,
       COUNT(L.StartDT) AS CompletedLessonsCount,
       SUM(T.Rate) AS TotalEstimatedEarnings
FROM LESSONS AS L
     JOIN TUTORS AS T ON L.Tutor = T.Tutor
     JOIN USERS AS U ON T.Tutor = U.Email
WHERE L.Status = 'Completed' AND L.LanguageName = 'German' AND YEAR(L.StartDT) = 2026
GROUP BY T.Tutor, U.NameFirst, U.NameLast
HAVING COUNT(L.StartDT) >= 5
ORDER BY TotalEstimatedEarnings DESC


--===================================================================================================

--שאילתה רגילה 2

SELECT CONCAT(U.NameFirst, ' ', U.NameLast) AS TutorName,
       R.Student AS StudentEmail,
       R.Grade AS ReviewGrade,
       R.ReviewText AS ReviewContent,
       DATEDIFF(day, R.ReviewDT, GETDATE()) AS DaysAgo
FROM REVIEWS AS R
     JOIN TUTORS AS T ON R.Tutor = T.Tutor
     JOIN USERS AS U ON T.Tutor = U.Email
WHERE U.CountryOfOrigin = 'Spain' AND R.Grade = 5
ORDER BY R.ReviewDT DESC

--===================================================================================================

--שאילתה מקוננת 1

SELECT T.Tutor AS TutorEmail,
       U.NameFirst + ' ' + U.NameLast AS TutorFullName,
       T.Rate
FROM TUTORS AS T
     JOIN USERS AS U ON T.Tutor = U.Email
WHERE T.Rate > (SELECT AVG(Rate) FROM TUTORS)
ORDER BY T.Rate DESC

--===================================================================================================

--שאילתה מקוננת 2

SELECT
    StudentRevenue.CountryOfOrigin,
    COUNT(*) AS PayingStudentsCount,
    SUM(StudentRevenue.TotalPaid) AS TotalRevenue,
    AVG(StudentRevenue.TotalPaid) AS AvgRevenuePerStudent
FROM (
      SELECT U.CountryOfOrigin, B.Student, SUM(T.Rate * L.Duration / 60.0) AS TotalPaid
      FROM BOOKINGS AS B
      JOIN USERS AS U ON B.Student = U.Email
      JOIN LESSONS AS L ON B.Booking = L.Booking
      JOIN TUTORS AS T ON L.Tutor = T.Tutor
      WHERE L.Status = 'Completed'
      GROUP BY U.CountryOfOrigin, B.Student
      ) AS StudentRevenue
GROUP BY StudentRevenue.CountryOfOrigin


--===================================================================================================

--פונקציית חלון 1

SELECT T.LanguageName, 
       T.Tutor AS TutorEmail,
       U.NameFirst + ' ' + U.NameLast AS TutorFullName,
       TR.Rate,
       ROW_NUMBER() OVER (PARTITION BY T.LanguageName ORDER BY TR.Rate DESC) AS TutorSeqNum,
       DENSE_RANK() OVER (PARTITION BY T.LanguageName ORDER BY TR.Rate DESC) AS PriceTierRank
FROM TEACHING AS T
     JOIN TUTORS AS TR ON T.Tutor = TR.Tutor
     JOIN USERS AS U ON TR.Tutor = U.Email

--===================================================================================================

--פונקציית חלון 2

SELECT B.Student AS StudentEmail,
       L.StartDT AS CurrentLessonDT,
       L.LanguageName,
       L.Status,
       LAG(L.StartDT, 1) OVER (PARTITION BY B.Student ORDER BY L.StartDT) AS PreviousLessonDT,
       LEAD(L.StartDT, 1) OVER (PARTITION BY B.Student ORDER BY L.StartDT) AS NextLessonDT
FROM LESSONS AS L
     JOIN BOOKINGS AS B ON L.Booking = B.Booking
WHERE L.Status IN ('Scheduled', 'Completed', 'Pending')

--===================================================================================================

--פונקציית חלון 3

SELECT L.LanguageName, L.Tutor AS TutorEmail,
       COUNT(*) AS CompletedLessonsCount,
       RANK() OVER (PARTITION BY L.LanguageName ORDER BY COUNT(*) DESC) AS TutorRankInLanguage
FROM LESSONS AS L
WHERE L.Status = 'Completed'
GROUP BY L.LanguageName, L.Tutor
ORDER BY L.LanguageName, TutorRankInLanguage


--===================================================================================================

--פונקציית חלון 4

SELECT B.Student AS StudentEmail,
       SUM(TR.Rate) AS TotalSpent,
       NTILE(3) OVER (ORDER BY SUM(TR.Rate) DESC) AS StudentEngagementTier
FROM BOOKINGS AS B
     JOIN LESSONS AS L ON B.Booking = L.Booking
     JOIN TUTORS AS TR ON L.Tutor = TR.Tutor
WHERE L.Status = 'Completed'
GROUP BY B.Student

--===================================================================================================


WITH 
--תת שאילתה 1: חישוב כמות חיפושים לכל שפה
LanguageDemand AS (
                   SELECT LanguageName, COUNT(*) AS TotalSearches
                   FROM SEARCHES
                   GROUP BY LanguageName
                   ),


--תת שאילתה 2: חישוב כמות שיעורים שהושלמו לכל שפה
LanguageSupply AS (
                   SELECT LanguageName, COUNT(*) AS CompletedLessons
                   FROM LESSONS
                   WHERE Status = 'Completed'
                   GROUP BY LanguageName
                   ),


--תת שאילתה 3: שילוב הנתונים
MarketMetrics AS (
                  SELECT 
                  D.LanguageName, 
                  D.TotalSearches, 
                  ISNULL(S.CompletedLessons, 0) AS CompletedLessons
                  FROM LanguageDemand AS D
                  LEFT JOIN LanguageSupply AS S ON D.LanguageName = S.LanguageName
                  )

--השאילתה הראשית 
SELECT MM.LanguageName,
       MM.TotalSearches,
       MM.CompletedLessons,
       CAST((MM.CompletedLessons * 100.0 / MM.TotalSearches) AS Decimal(10,2)) AS ConversionRatePercent,
       ISNULL(AVG(T.Rate), 0) AS AvgTutorRate,
       COUNT(DISTINCT TEA.Tutor) AS ActiveTutorsCount --מראה כמה מורים מלמדים את השפה בפועל
FROM MarketMetrics AS MM
     LEFT JOIN TEACHING AS TEA ON MM.LanguageName = TEA.LanguageName
     LEFT JOIN TUTORS AS T ON TEA.Tutor = T.Tutor
GROUP BY MM.LanguageName, 
         MM.TotalSearches, 
         MM.CompletedLessons
ORDER BY MM.TotalSearches DESC


--===================================================================================================
--מטלה 2
--===================================================================================================

--VIEW

DROP VIEW IF EXISTS vw_TutorSearchBase
GO


CREATE VIEW vw_TutorSearchBase AS
SELECT T.Tutor AS TutorEmail,
       U.NameFirst + ' ' + U.NameLast AS TutorName,
       U.CountryOfOrigin,
       TE.LanguageName,
       TE.Level AS TeachingLevel,
       T.Rate
FROM TUTORS AS T
JOIN USERS AS U ON U.Email = T.Tutor
JOIN TEACHING AS TE ON TE.Tutor = T.Tutor

--דוגמה לשימוש

SELECT *
FROM vw_TutorSearchBase
WHERE LanguageName = 'English'
ORDER BY Rate ASC


--===================================================================================================

--פונקציה סקלרית

DROP FUNCTION IF EXISTS fn_LevelMatch
GO

CREATE FUNCTION fn_LevelMatch (@StudentLevel VARCHAR(2), @TutorLevel VARCHAR(2))
RETURNS VARCHAR(25)
AS
BEGIN
    DECLARE @Result VARCHAR(25);

    IF @StudentLevel IS NULL
        SET @Result = 'Level Not Provided';

    ELSE IF @TutorLevel >= @StudentLevel
        SET @Result = 'Suitable';

    ELSE
        SET @Result = 'Not Suitable';

    RETURN @Result;
END



--דוגמה לשימוש

SELECT S.Student, S.LanguageName, S.CurrentLevel, T.Tutor, T.Level AS TutorLevel,
       dbo.fn_LevelMatch(S.CurrentLevel, T.[Level]) AS MatchStatus
FROM STUDYING AS S
JOIN TEACHING AS T ON S.LanguageName = T.LanguageName

--===================================================================================================

--פונקציה טבלאית


DROP FUNCTION IF EXISTS fn_SearchTutorsByNeed
GO


CREATE FUNCTION fn_SearchTutorsByNeed (@LanguageName VARCHAR(20), @MaxRate MONEY)
RETURNS TABLE
AS
RETURN
(
    SELECT
        TutorEmail,
        TutorName,
        CountryOfOrigin,
        LanguageName,
        TeachingLevel,
        Rate
    FROM vw_TutorSearchBase
    WHERE LanguageName = @LanguageName
      AND Rate <= @MaxRate
)

--דוגמה לשימוש

SELECT *
FROM dbo.fn_SearchTutorsByNeed('Spanish', 60)
ORDER BY Rate

--===================================================================================================

--טריגר

--הכנה לטריגר- יצירת עמודה חדשה בטבלת ההזמנות

ALTER TABLE BOOKINGS
ADD TotalCost MONEY NULL


--יצירת הטריגר

DROP TRIGGER IF EXISTS trg_UpdateBookingTotalCost
GO


CREATE TRIGGER trg_UpdateBookingTotalCost
ON LESSONS
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    UPDATE BOOKINGS
    SET TotalCost = ISNULL((
                            SELECT SUM(T.Rate * (CAST(L.Duration AS FLOAT) / 60.0))
                            FROM LESSONS AS L
                            JOIN TUTORS AS T
                            ON L.Tutor = T.Tutor
                            WHERE L.Booking = BOOKINGS.Booking
                            AND L.Status <> 'Cancelled'
                            ), 0)
                            WHERE BOOKINGS.Booking IN (
                                                       SELECT Booking
                                                       FROM inserted
                                                       WHERE Booking IS NOT NULL

                                                       UNION

                                                       SELECT Booking
                                                       FROM deleted
                                                       WHERE Booking IS NOT NULL
                                                       );
END


--דוגמה לשימוש

SELECT Booking, TotalCost
FROM BOOKINGS
WHERE Booking = 101;

UPDATE LESSONS
SET Duration = 90
WHERE Booking = 101
  AND Status = 'Scheduled';

SELECT Booking, TotalCost
FROM BOOKINGS
WHERE Booking = 101

--===================================================================================================

--פרוצדורה שמורה 

DROP PROCEDURE IF EXISTS sp_CancelBooking
GO


CREATE PROCEDURE sp_CancelBooking
    @BookingID INT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM LESSONS
        WHERE Booking = @BookingID
          AND Status = 'Completed'
    )
    BEGIN
        PRINT 'Error: Cannot cancel a booking that contains completed lessons.';
        RETURN;
    END

    UPDATE LESSONS
    SET Status = 'Cancelled'
    WHERE Booking = @BookingID;

    PRINT 'Booking successfully cancelled. All related lessons are now cancelled.';
END

-- דוגמה לשימוש שבה הזמנה מתבטלת

SELECT Booking, StartDT, Duration, Status
FROM LESSONS
WHERE Booking = 68;

EXEC sp_CancelBooking @BookingID = 68;

SELECT Booking, StartDT, Duration, Status
FROM LESSONS
WHERE Booking = 68


--דוגמה לשימוש שבו הפרוצדורה לא ביטלה את ההזמנה
SELECT Booking, StartDT, Duration, Status
FROM LESSONS
WHERE Booking = 1;

EXEC sp_CancelBooking @BookingID = 1;

SELECT Booking, StartDT, Duration, Status
FROM LESSONS
WHERE Booking = 1


--=================================================================================================================
--מטלה 3
--=================================================================================================================

--VIEWS FOR POWER BI

--דוח עסקי
--VIEW 1:
--מחבר בין טבלת החיפושים לטבלת השפות עם עמודות חדשות שמראות לכל שפה מה מספר החיפושים שהיו לה, מספר המורים שיש לה ומספר חיפושים פר מורה בממוצע


DROP VIEW IF EXISTS vw_LanguageSupplyDemand
GO

CREATE VIEW vw_LanguageSupplyDemand AS
SELECT L.LanguageName,
    CASE
        WHEN L.Status = 1 THEN 'Active'
        ELSE 'Inactive'
        END AS Status,
    ISNULL(S.TotalSearches, 0) AS TotalSearches,
    ISNULL(T.TotalTutors, 0) AS TotalTutors,
    CASE
        WHEN ISNULL(T.TotalTutors, 0) = 0 THEN NULL
        ELSE CAST(ISNULL(S.TotalSearches, 0) AS FLOAT) / T.TotalTutors
    END AS SearchesPerTutor
FROM LANGUAGES AS L
LEFT JOIN (
    SELECT LanguageName, COUNT(*) AS TotalSearches
    FROM SEARCHES
    GROUP BY LanguageName
    ) AS S
ON L.LanguageName = S.LanguageName
LEFT JOIN (
    SELECT LanguageName, COUNT(DISTINCT Tutor) AS TotalTutors
    FROM TEACHING
    GROUP BY LanguageName
    ) AS T
    ON L.LanguageName = T.LanguageName

--שאילתה לבדיקה:

    SELECT * FROM vw_LanguageSupplyDemand
--=================================================================================================================

--VIEW 2:
--מראה מה הציון הממוצע שכל שפה קיבלה באתר (יכול לעזור להבין האם שווה להתעמק באיכות המורים בשפות מסוימות


DROP VIEW IF EXISTS vw_LanguagePerformance
GO

CREATE VIEW vw_LanguagePerformance AS
SELECT T.LanguageName,
       AVG(CAST(R.Grade AS FLOAT)) AS AvgRating,
       COUNT(*) AS NumReviews
FROM TEACHING AS T
JOIN REVIEWS AS R ON T.Tutor = R.Tutor
GROUP BY T.LanguageName

--שאילתה לבדיקה:

SELECT * FROM vw_LanguagePerformance

--=================================================================================================================

--לוח מחוונים
--VIEW 1:
--מחבר בין השיעורים למורים ובודק מה היה המחיר לכל שיעור שתאריכו עבר. על שיעורים שבוטלו ההכנסה תהיה 0
--מכאן אפשר לחשב הכנסות של האתר

DROP VIEW IF EXISTS vw_LessonRevenue
GO


CREATE VIEW vw_LessonRevenue AS
SELECT L.Tutor, L.StartDT, L.Duration, L.Status, L.LanguageName, L.Booking, T.Rate,
       CASE
           WHEN L.Status = 'Completed' THEN T.Rate * L.Duration / 60.0
           ELSE 0
       END AS LessonRevenue
FROM LESSONS AS L
JOIN TUTORS AS T ON L.Tutor = T.Tutor

--שאילתה לבדיקה:

SELECT * FROM vw_LessonRevenue

--=================================================================================================================

--VIEW 2:
--בודק מה התאריך האחרון שלקוח ביצע הזמנה ומסווג אותו כפעיל או לא פעיל
--לקוח פעיל הוא כזה שביצע הזמנה ב90 ימים האחרונים


DROP VIEW IF EXISTS vw_StudentActivity
GO


CREATE VIEW vw_StudentActivity AS
WITH MaxDate AS (
    SELECT MAX(BookingDT) AS LastDate
    FROM BOOKINGS
    )

SELECT B.Student, 
       MAX(B.BookingDT) AS LastBookingDate, DATEDIFF(DAY, MAX(B.BookingDT), M.LastDate)
       AS DaysSinceLastBooking,
       CASE
           WHEN DATEDIFF(
                DAY,
                MAX(B.BookingDT),
                M.LastDate
             ) <= 90
           THEN 'Active'
           ELSE 'Inactive'
       END AS ActivityStatus
FROM BOOKINGS B
CROSS JOIN MaxDate M
GROUP BY B.Student, M.LastDate

--שאילתה לדוגמה:

SELECT * FROM vw_StudentActivity

--=================================================================================================================
--מטלה 4
--=================================================================================================================

--אופטימיזציה 1


CREATE INDEX IX_SEARCHES_LanguageName
ON SEARCHES (LanguageName);

CREATE INDEX IX_LESSONS_Status_LanguageName
ON LESSONS (Status, LanguageName);

CREATE INDEX IX_TEACHING_LanguageName_Tutor
ON TEACHING (LanguageName, Tutor);



WITH LanguageDemand AS (
    SELECT LanguageName, COUNT(*) AS TotalSearches
    FROM SEARCHES
    GROUP BY LanguageName
),
LanguageSupply AS (
    SELECT LanguageName, COUNT(*) AS CompletedLessons
    FROM LESSONS
    WHERE Status = 'Completed'
    GROUP BY LanguageName
),
TutorMetrics AS (
    SELECT 
        TT.LanguageName,
        AVG(CAST(T.Rate AS DECIMAL(10,2))) AS AvgTutorRate,
        COUNT(*) AS ActiveTutorsCount
    FROM (
        SELECT DISTINCT LanguageName, Tutor
        FROM TEACHING
    ) AS TT
    JOIN TUTORS AS T ON TT.Tutor = T.Tutor
    GROUP BY TT.LanguageName
)
SELECT 
    D.LanguageName,
    D.TotalSearches,
    ISNULL(S.CompletedLessons, 0) AS CompletedLessons,
    CAST(
        ISNULL(S.CompletedLessons, 0) * 100.0 / NULLIF(D.TotalSearches, 0)
        AS DECIMAL(10,2)
    ) AS ConversionRatePercent,
    ISNULL(TM.AvgTutorRate, 0) AS AvgTutorRate,
    ISNULL(TM.ActiveTutorsCount, 0) AS ActiveTutorsCount
FROM LanguageDemand AS D
LEFT JOIN LanguageSupply AS S
    ON D.LanguageName = S.LanguageName
LEFT JOIN TutorMetrics AS TM
    ON D.LanguageName = TM.LanguageName
ORDER BY D.TotalSearches DESC;
    

--=================================================================================================================
--אופטימיזציה 2


WITH CompletedLessonsRevenue AS (
    SELECT 
        L.Booking,
        L.Tutor,
        L.Duration
    FROM LESSONS AS L
    WHERE L.Status = 'Completed'
),
StudentRevenue AS (
    SELECT 
        U.CountryOfOrigin,
        B.Student,
        SUM(T.Rate * CLR.Duration / 60.0) AS TotalPaid
    FROM CompletedLessonsRevenue AS CLR
    JOIN BOOKINGS AS B
        ON CLR.Booking = B.Booking
    JOIN USERS AS U
        ON B.Student = U.Email
    JOIN TUTORS AS T
        ON CLR.Tutor = T.Tutor
    GROUP BY 
        U.CountryOfOrigin,
        B.Student
)
SELECT
    SR.CountryOfOrigin,
    COUNT(*) AS PayingStudentsCount,
    SUM(SR.TotalPaid) AS TotalRevenue,
    AVG(SR.TotalPaid) AS AvgRevenuePerStudent
FROM StudentRevenue AS SR
GROUP BY SR.CountryOfOrigin
--DATEADD

/*
-- How do we populate the body column in tblREVIEW in our synthetic transaction
I am suggesting CASE
--> base the CASE statement on a RAND() * 100 --> this creates a random 2-digit number
--> multiple sentences in the case statement


*/
DECLARE @Body varchar(1000)
DECLARE @Number INT
SET @Number = (SELECT RAND() * 100)
PRINT @Number
SET @Body = (CASE
		WHEN @Number < 18
		THEN 'I liked the movie but I found the acting incredibly fantastic...my rating is a 3'
		WHEN @Number BETWEEN 18 AND 53
		THEN 'This movie sucked air and wasted $11 of my money...my rating is a 1'
		WHEN @Number BETWEEN 54 AND 80
		THEN 'MEH... I guess it was okay, so I give the rating a 2'
		ELSE 'No rating'
		END)
PRINT @Body

USE Spotify
go

--1. Write the code to populate REVIEW table using three (3) stored procedures.
--a. GetAccessID when provided SubscriptionName, AccessTypeName, RecordingName and AccessDateTime 
--b. GetRatingID when provided RatingName
--c. The ‘calling’ base stored procedure that does the INSERT into REVIEW leveraging the two other nested procedures in an explicit transaction
--d. Please include two instances of error-handling by checking for NULL values.

CREATE PROCEDURE uspGetAccessID
@SubscriptionName varchar(100),
@AccTypeName varchar(100),
@RecordName varchar(100),
@AccDateTime datetime,
@AccID INT OUTPUT,
@SubID INT OUTPUT,
@AccTypeID INT OUTPUT,
@RecID INT OUTPUT
AS SET @SubID = (SELECT SubID FROM tblSubscription WHERE SubscriptionName = @SubscriptionName)
SET @AccTypeID = (SELECT AccessTypeID FROM tblACCESS_TYPE WHERE AccessTypeName = @AccTypeName)
SET @RecID = (SELECT RecordingID FROM tblRecording WHERE RecordingName = @RecordName)
SET @AccID = (SELECT AccessID FROM tblACCESS WHERE SubscriptionID = @SubID
										AND RecordingID = @RecID
										AND AccessTypeID = @AccID
										AND AccessDateTime = @AccDateTime)
GO

CREATE PROCEDURE uspGetRatingID
@RateName varchar(100),
@RateID INT OUTPUT
AS SET @RateID = (SELECT RatingID FROM tblRATING WHERE RatingName = @RateName)
GO

CREATE PROCEDURE insREVIEW
@Sub_Name varchar(100),
@AccType_Name varchar(100),
@Record_Name varchar(100),
@Rate_Name varchar(100),
@RevDate date,
@RevBody varchar(100),
@Acc_DateTime datetime
AS DECLARE @Sub_ID INT, @AccType_ID INT, @Rec_ID INT, @A_ID INT, @R_ID INT

EXEC uspGetAccessID
@SubscriptionName = @Sub_Name,
@AccTypeName = @AccType_Name,
@RecordName = @Record_Name,
@AccDateTime = @Acc_DateTime,
@SubID = @Sub_ID OUTPUT,
@AccTypeID = @AccType_ID OUTPUT,
@RecID = @Rec_ID OUTPUT,
@AccID = @A_ID OUTPUT
IF @Sub_ID IS NULL
	BEGIN
		PRINT 'Hi, there is a problem with @Sub_ID being NULL'
		RAISERROR('@Sub_ID cannot be NULL', 11,1)
		RETURN
	END
IF @AccType_ID IS NULL
	BEGIN
		PRINT 'Hi, there is a problem with @AccType_ID being NULL'
		RAISERROR('@AccType_ID cannot be NULL', 11,1)
		RETURN
	END
IF @Rec_ID IS NULL
	BEGIN
		PRINT 'Hi, there is a problem with @Rec_ID being NULL'
		RAISERROR('@Rec_ID cannot be NULL', 11,1)
		RETURN
	END
IF @A_ID IS NULL
	BEGIN
		PRINT 'Hi, there is a problem with @A_ID being NULL'
		RAISERROR('@A_ID cannot be NULL', 11,1)
		RETURN
	END

EXEC uspGetRatingID
@RateName = @Rate_Name
@RateID = @R_ID OUTPUT
IF @R_ID IS NULL
	BEGIN
		PRINT 'Hi, there is a problem with @R_ID being NULL'
		RAISERROR('@A_ID cannot be NULL', 11,1)
		RETURN
	END


BEGIN TRAN G1
	INSERT INTO tblREVIEW (AccessID, RatingID, ReviewDate, ReviewBody)
	VALUES (@A_ID, @R_ID, @RevBody, @RevBody)
IF @@ERROR <> 0
    BEGIN
        PRINT 'Hey...there is an error up ahead and I am pulling over'
        ROLLBACK TRAN G1
    END
ELSE
    COMMIT TRAN G1
GO


--3. Create a computed column with a User-Defined Functions (UDF) to determine the 
--AVERAGE customer rating for each recording.
CREATE FUNCTION fn_AvgCustRating(@PK INT)
RETURNS INT
AS 
BEGIN 
DECLARE @RET Numeric(11,2) = (
SELECT AVG(R.RatingNumberic)
FROM tblRecording RC 
   JOIN tblACCESS A ON A.RecordingID = RC.RecordingID
   JOIN tblSubscription S ON S.SubscriptionID = A.SubscritpionID
   JOIN tblCUSTOMER C ON C.CustomerID = S.CustomerID
   JOIN tblREVIEW RV ON RV.AccessID = A.AccessID
   JOIN tblRATING RT ON RT.RatingID = RV.RatingID
WHERE RC.RecordingID = @PK
)
RETURN @RET 
END 
GO 

ALTER TABLE tblRECORDING 
ADD AvgRating AS (dbo.fn_AvgCustRating(RecordingID))
go

--4. Write the SQL for a function that is used to enforce the following business rule:
--“No customer between the ages of 12 and 19 may stream more than 6 recordings with the 
--artist 'Greg Hay' on instrument of keyboard in the first 90 days of their subscription 
--begin date”
CREATE FUNCTION fn_NoStreaming(@PK INT)
RETURNS INT
AS
BEGIN
DECLARE @RET INT = 0
IF EXISTS(SELECT C.CustomerID, RC.RecordingName, DATEDIFF(year, C.BirthDate, GETDATE()) AS Age
		FROM tblCUSTOMER C
			JOIN tblSubscription SB ON SB.CustomerID = C.CustomerID
			JOIN tblACCESS AC ON AC.SubscriptionID = SB.SubscriptionID
			JOIN tblRecording RC ON RC.RecordingID = AC.RecordingID
			JOIN tblSong S ON S.SongID = RC.SongID
			JOIN tblWRITER W ON W.SongID = S.SongID
			JOIN tblArtist A ON A.ArtistID = W.AristID
			JOIN tblPERFORMANCE PC ON PC.ArtistID = A.ArtistID
			JOIN tblINSTRUMENT I ON I.InstrumentID = PC.InstrumentID
		WHERE I.InstrumentName = 'keyboard' 
			AND A.ArtistFname = 'Greg'
			AND A.ArtistLname = 'Hay'
		HAVING COUNT(AC.AccessDateTime) >= 6
			AND (DATEDIFF(year, C.BirthDate, GETDATE()) BETWEEN 12 AND 19)
			AND (DATEDIFF(day, S.BeginDate, GETDATE()) < 90)
)
SET @Ret = 1
RETURN @Ret
END
GO 

ALTER TABLE tblCUSTOMER WITH NoCheck
ADD CONSTRAINT StreamingRestriction
CHECK (dbo.fn_NoStreaming() = 0)
GO

--5. Write the SQL code using nested subqueries to determine which customers meet all 
-- three of the following conditions:
--a. Streamed 12 recordings after May 12, 2016  of genre ‘BeBop Jazz’
--b. Have added no more than 9 recordings of genre 'Hip Hop' to any playlist in 
-- the past 180 days
--c. Have an maximum rating on downloaded recordings of 4.2 / 5 before December 11, 2016.
SELECT C.CustomerID, C.CustFname, C.CustLname
FROM tblCUSTOMER C
	JOIN tblSubscription S ON S.CustomerID = C.CustomerID
	JOIN tblACCESS AC ON AC.SubscriptionID = S.SubscriptionID
	JOIN (SELECT *
		FROM tblPLAYLIST_DETAIL PD
			JOIN tblPLAYLIST P ON P.PlaylistID = PD.PlaylistID
			JOIN(SELECT *
				FROM tblCUSTOMER C
					JOIN tblSubscription S ON S.CustomerID = C.CustomerID
					JOIN tblACCESS AC ON AC.SubscriptionID = S.SubscriptionID
					JOIN tblREVIEW RV ON RV.AccessID = AC.AccessID
					JOIN tblRATING RT ON RT.RatingID = RV.RatingID
				WHERE R.RatingNumeric <= 4.2
				AND A.AccessDateTime < '2016-12-11'
				) AS subq1 ON subq1.AccessID = PD.AccessID
			JOIN tblRecording RC ON RC.RecordingID = subq1.AccessID
			JOIN tblGenre G ON G.GenreID = RC.GenreID
		WHERE G.GenreName = 'Hip Hop'
		HAVING COUNT(RC.RecordingID) < 9
			AND DATEDIFF(day, PD.AddDate, GETDATE()) < 180
		) AS subq2 ON subq2.RecordingID = AC.RecordingID
	JOIN tblGenre G ON G.GenreID = subq2.GenreID
WHERE G.GenreName = 'BeBop Jazz'
HAVING COUNT(AC.AccessDate) >= 12
	AND AC.AccessDate > '2016-05-12'
GO

--6. Using multiple Common Table Expressions (CTE) and ranking functions, write the SQL 
-- to determine the ENSEMBLE that meets the following conditions:
--a. Has at least 75 recordings that have been in Studio 'X Factor 5' with an Average 
-- Rating of at least 4.5/5 
--b. Have had more than 3 artists from South America since May 5, 1986
--c. Rank  between 15 and 25 of all ensembles for total number of downloads 
-- (AccessTypeName) in the past 12 years.
WITH CTE_EnsembleRank (EnsembleID, EnsembleName, RankDownloads)
AS (
SELECT E.EnsembleID, E.EnsembleName,
RANK() OVER (PARTITION BY ACT.AccessTypeName ORDER BY COUNT(AC.AccessID)) AS RankDownloads
FROM tblENSEMBLE E
	JOIN tblENSEMBLE_ARTIST EA ON EA.EnsembleID = E.EnsembleID
	JOIN tblArtist A ON A.ArtistID = EA.ArtistID
	JOIN tblWRITER W ON W.ArtistID = A.ArtistID
	JOIN tblSong SG ON SG.SongID = W.SongID
	JOIN tblRecording RC ON RC.SongID = SG.SongID
	JOIN tblACCESS AC ON AC.RecordingID = RC.RecordingID
	JOIN tblACCESS_TYPE ACT ON ACT.AccessTypeID = AC.AccessTypeID
HAVING DATEDIFF(year, AC.AccessDate, GETDATE()) <= 12
	AND RANK() OVER (PARTITION BY ACT.AccessTypeName ORDER BY COUNT(AC.AccessID)) BETWEEN 15 AND 25),

SAartists (EnsembleID, ArtistID, NumArtists)
AS (
SELECT E.EnsembleID, A.ArtistID, COUNT(A.ArtistID) AS NumArtists
FROM tblENSEMBLE E
	JOIN tblENSEMBLE_ARTIST EA ON EA.EnsembleID = E.EnsembleID
	JOIN tblArtist A ON A.ArtistID = EA.ArtistID
	JOIN tblCountry CT ON CT.CountryID = A.CountryID
	JOIN tblRegion RG ON RG.RegionID = CT.RegionID
WHERE RG.RegionName = 'South America'
	AND EA.BeginDate > '1986-05-05'
HAVING COUNT(A.ArtistID) > 3),
StudioRecordRatings (ArtistID, NumRecords, AvgRating)
AS (
SELECT AR.ArtistID, (RC.RecordingID) AS NumRecords, AVG(RT.RatingNumeric) AS AvgRating
FROM tblRecording RC
	JOIN tblSTUDIO SD ON SD.StudioID = RC.StudioID
	JOIN tblACCESS AC ON AC.RecordingID = RC.RecordingID
	JOIN tblREVIEW RV ON RV.AccessID = AC.AccessID
	JOIN tblRATING RT ON RT.RatingID = RV.RatingID
	JOIN tblSONG SG ON SG.SongID = RC.SongID
	JOIN tblWRITER W ON W.ArtistID = SG.ArtistID
	JOIN tblArtist AR ON AR.ArtistID = W.ArtistID
HAVING COUNT(RC.RecordingID) >= 75
	AND AVG(RT.RatingNumeric) >= 4.5)

SELECT EnsembleName, RankDownloads, NumArtists, AvgRating
FROM CTE_EnsembleRank ER
	JOIN SAartists SA ON ER.EnsembleID = SA.EnsembleID
	JOIN StudioRecordRatings SRR ON SRR.ArtistID = SA.ArtistID


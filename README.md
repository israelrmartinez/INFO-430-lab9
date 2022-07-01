# INFO-430-lab9
 
## Canvas Assignment Instructions

1. Write the code to populate REVIEW table using three (3) stored procedures.
a. GetAccessID when provided SubscriptionName, AccessTypeName, RecordingName and AccessDateTime 
b. GetRatingID when provided RatingName
c. The ‘calling’ base stored procedure that does the INSERT into REVIEW leveraging the two other nested procedures in an explicit transaction
d. Please include two instances of error-handling by checking for NULL values.

 

2. Create a ‘wrapper’ to establish a synthetic transaction on the base stored procedure that was created immediately above. There should be only one single parameter for this wrapper.

 

3. Create a computed column with a User-Defined Functions (UDF) to determine the AVERAGE customer rating for each recording.


4. Write the SQL for a function that is used to enforce the following business rule:
“No customer between the ages of 12 and 19 may stream more  than 6 recordings with the artist 'Greg Hay' on instrument of keyboard in the first 90 days of their subscription begin date”



5. Write the SQL code using nested subqueries to determine which customers meet all three of the following conditions:
a. Streamed 12 recordings after May 12, 2016  of genre ‘BeBop Jazz’
b. Have added no more than 9 recordings of genre 'Hip Hop' to any playlist in the past 180 days
c. Have an maximum rating on downloaded recordings of 4.2 / 5 before December 11, 2016.

6. Using multiple Common Table Expressions (CTE) and ranking functions, write the SQL to determine the ENSEMBLE that meets the following conditions:
a. Has at least 75 recordings that have been in Studio 'X Factor 5' with an Average Rating of at least 4.5/5 
b. Have had more than 3 artists from South America since May 5, 1986
c. Rank  between 15 and 25 of all ensembles for total number of downloads (AccessTypeName) in the past 12 years.

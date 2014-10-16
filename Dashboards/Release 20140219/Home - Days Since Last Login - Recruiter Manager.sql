-- Home - Days Since Last Login - Recruiter Manager.sql
-- Requirements
-- ============
-- Show the number of days since the last login for every recruiter
-- Data context = Recruiter Managers only

SET NOCOUNT ON;  

SELECT R.nvcFirstname + ' ' + R.nvcLastname AS Recruiter, DATEDIFF(d, U.dteLastLogin, GETDATE()) AS 'Days since last login' 
FROM dtlUser U
JOIN dtlRecruiter R ON U.uidId = R.uidUserId 
WHERE R.bitHidden = 0
ORDER BY R.nvcFirstname, R.nvcLastname
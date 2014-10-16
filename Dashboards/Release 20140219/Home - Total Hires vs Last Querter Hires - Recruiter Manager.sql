-- Home - Gender and Race Hired.sql
-- Requirements
-- ============
-- Count (just once) any application that has been in RWF step = Hired
-- Data context = user specific based on Job access level (AllRequisitions | AsssignedRequisitions)


SET NOCOUNT ON;  

CREATE TABLE #tmpRecruiterApplications 
(
  uidApplicationId uniqueidentifier,  
  nvcRecruiter nvarchar(50),
  dteLandingDate datetime,
  bitLastQuater bit
)  

INSERT INTO #tmpRecruiterApplications
SELECT DISTINCT A.uidId, REC.nvcFirstname + ' ' + REC.nvcLastname, 
(SELECT MAX(dteLandingDate) FROM relApplicationWorkflowHistory WHERE uidApplicationId = A.uidId), 0
FROM relApplication A
JOIN dtlRequisition R ON A.uidRequisitionId = R.uidId 
JOIN relRecruiterRequisition RR ON R.uidId = RR.uidRequisitionId AND RR.enmRecruiterRequisitionType = 1
JOIN dtlRecruiter REC ON RR.uidRecruiterId = REC.uidId 
WHERE A.uidApplicationWorkflowStepId = 'D48D37A6-FF45-4A2A-B6C4-C87FE3123809' -- Hired


UPDATE #tmpRecruiterApplications
SET bitLastQuater = 1
WHERE dteLandingDate >= DATEADD(m, -3, GETDATE())

SELECT nvcRecruiter AS Recruiter, COUNT(uidApplicationId) AS 'Total Hires (All Time)', COUNT(bitLastQuater) AS 'Total Hires (Last Quarter)'
FROM #tmpRecruiterApplications
GROUP BY nvcRecruiter

DROP TABLE #tmpRecruiterApplications
-- Home - Active vs Archived Jobs - Recruiter Manager.sql
-- Requirements
-- ============
-- Advertised = date jobs first moved into RWF step where published = true)
-- Archived = (date jobs first moved into RWF step = archived)
-- The data is genereated for the last 3 months
-- Data context = Recruiter Managers only

SET NOCOUNT ON;  

SELECT uidRequisitionId, dteLandingDate 
INTO #tmpRequisitionSourcingDates
FROM relRequisitionWorkflowAction
WHERE uidRequisitionWorkflowStepId IN
(
	SELECT uidId FROM refRequisitionWorkflowStep WHERE nvcName = 'Sourcing'
)

SELECT uidRequisitionId, dteLandingDate 
INTO #tmpRequisitionArchivedDates
FROM relRequisitionWorkflowAction
WHERE uidRequisitionWorkflowStepId IN
(
	SELECT uidId FROM refRequisitionWorkflowStep WHERE nvcName = 'Archived'
)


SELECT R.uidId, REC.nvcFirstname + ' ' + REC.nvcLastname AS 'Recruiter',
(SELECT MAX(dteLandingDate) FROM #tmpRequisitionSourcingDates WHERE uidRequisitionId = R.uidId) AS dteSourcingDate,
(SELECT MAX(dteLandingDate) FROM #tmpRequisitionArchivedDates WHERE uidRequisitionId = R.uidId) AS dteArchiveDate
INTO #tmpRequisitions
FROM dtlRequisition R
JOIN relRecruiterRequisition RR ON R.uidId = RR.uidRequisitionId AND RR.enmRecruiterRequisitionType = 1
JOIN dtlRecruiter REC ON RR.uidRecruiterId = REC.uidId 
ORDER BY R.uidId

SELECT Recruiter, COUNT(dteSourcingDate) AS Sourcing, COUNT(dteArchiveDate) AS Archived
FROM #tmpRequisitions
WHERE dteSourcingDate >= DATEADD(m, -3, GETDATE())
OR dteArchiveDate >= DATEADD(m, -3, GETDATE())
GROUP BY Recruiter

DROP TABLE #tmpRequisitionSourcingDates
DROP TABLE #tmpRequisitionArchivedDates
DROP TABLE #tmpRequisitions
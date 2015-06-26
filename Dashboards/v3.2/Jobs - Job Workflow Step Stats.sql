-- Jobs - Job Workflow Step Stats.sql
-- 20150507
-- Count the total jobs in each RWF step, filter by recruiter user
SET NOCOUNT ON;

DECLARE @uidUserId uniqueidentifier = '0EDC2E28-002E-4F3F-BCC7-21B44A54692B'
DECLARE @uidLanguageId uniqueidentifier = '4850874D-715B-4950-B188-738E2FFC1520'
	
SELECT * INTO #tmpUserRequisitionWorkflowSteps
FROM refRequisitionWorkflowStep
WHERE uidId IN 
(
	SELECT uidRequisitionWorkflowStepId 
	FROM relRequisitionWorkflowStepPermission 
	WHERE uidRoleId IN (SELECT uidRoleId FROM relRoleMembership WHERE uidUserId = @uidUserId) 
)
AND uidId <> '67A567F0-196B-4868-BE56-CCD2800C3051'
AND uidId <> '5CFBBA0A-EAB9-45E5-A9AF-8AF292B0AAD4'


SELECT 
R.uidId AS 'uidRequisitionId', 
RWS.nvcName, 
(
	select top 1 dteStartDate 
	from relRequisitionWebsite 
	where uidRequisitionId = R.uidId 
	order by dteStartDate
) AS dteStartDate,
(
	select top 1 dteEndDate 
	from relRequisitionWebsite 
	where uidRequisitionId = R.uidId 
	order by dteEndDate DESC
) AS dteEndDate,
'XXXXXXXXXXXXXXXXXXXX' AS 'nvcPublishedState'
INTO #tmpUserRequisitions
FROM dtlRequisition R
JOIN refRequisitionWorkflowStep RWS ON R.uidRequisitionWorkflowStepId = RWS.uidId 
JOIN relRequisitionWebsite RW ON R.uidId = RW.uidRequisitionId 
WHERE R.uidId IN (SELECT uidRequisitionId FROM relRecruiterRequisition WHERE uidRecruiterId IN (SELECT uidId FROM dtlRecruiter WHERE uidUserId = @uidUserId))
OR R.uidRequisitionWorkflowStepId IN (SELECT uidId FROM #tmpUserRequisitionWorkflowSteps)

UPDATE #tmpUserRequisitions
SET nvcPublishedState = 

	CASE 
		WHEN (dteStartDate > GETDATE()) THEN 'NOT YET PUBLISHED'
		WHEN (dteStartDate <= GETDATE() AND dteEndDate > GETDATE() ) THEN 'CURRENTLY PUBLISHED'
		WHEN (dteStartDate <= GETDATE() AND dteEndDate = NULL ) THEN 'CURRENTLY PUBLISHED'
		WHEN (dteEndDate < GETDATE()) THEN 'PREVIOUSLY PUBLISHED'
		ELSE 'X'
	END
	
DELETE FROM #tmpUserRequisitions WHERE nvcPublishedState = 'X'

SELECT nvcName + ' - ' + nvcPublishedState AS 'nvcStatus', COUNT(*) AS 'intCount'
INTO #tmpUserRequisitionsFinal
FROM #tmpUserRequisitions	
GROUP BY nvcName, nvcPublishedState	

SELECT '1' AS 'series', nvcStatus AS 'x', intCount AS 'y' FROM #tmpUserRequisitionsFinal
	
DROP TABLE #tmpUserRequisitionWorkflowSteps	
DROP TABLE #tmpUserRequisitions
DROP TABLE #tmpUserRequisitionsFinal
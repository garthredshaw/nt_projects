-- Jobs - Application status stats.sql
-- 20150507
-- Count applications in each AWF step, filter by recruiter user
SET NOCOUNT ON;

DECLARE @uidUserId uniqueidentifier = '0EDC2E28-002E-4F3F-BCC7-21B44A54692B'
DECLARE @uidLanguageId uniqueidentifier = '4850874D-715B-4950-B188-738E2FFC1520'
DECLARE @intPeriod int = 12
		
SELECT * INTO #tmpUserApplicationWorkflowSteps
FROM refApplicationWorkflowStep
WHERE uidId IN 
(
	SELECT uidApplicationWorkflowStepId 
	FROM relApplicationWorkflowStepPermission 
	WHERE uidRoleId IN (SELECT uidRoleId FROM relRoleMembership WHERE uidUserId = @uidUserId) 
)
			
SELECT * INTO #tmpUserRequisitionWorkflowSteps
FROM refRequisitionWorkflowStep
WHERE uidId IN 
(
	SELECT uidRequisitionWorkflowStepId 
	FROM relRequisitionWorkflowStepPermission 
	WHERE uidRoleId IN (SELECT uidRoleId FROM relRoleMembership WHERE uidUserId = @uidUserId) 
)

SELECT * INTO #tmpUserRequisitions
FROM dtlRequisition
WHERE
	uidId IN (SELECT uidRequisitionId FROM relRecruiterRequisition WHERE uidRecruiterId IN (SELECT uidId FROM dtlRecruiter WHERE uidUserId = @uidUserId))
	OR
	uidRequisitionWorkflowStepId IN (SELECT uidId FROM #tmpUserRequisitionWorkflowSteps)

SELECT * INTO #tmpUserApplications
FROM relApplication
WHERE
	uidRequisitionId IN (SELECT uidRequisitionId FROM #tmpUserRequisitions)
	AND
	uidApplicationWorkflowStepId IN (SELECT uidId FROM #tmpUserApplicationWorkflowSteps)
	
;WITH sequencedApplicationHistory AS
(
	SELECT
		ROW_NUMBER() OVER (ORDER BY uidApplicationId, dteLandingDate) as intOrder,
		*
	FROM relApplicationWorkflowHistory
	WHERE
		dteLandingDate > '1 ' + DATENAME(month, (DATEADD(month, 0-@intPeriod, GETDATE()))) + ' ' + CAST(YEAR(DATEADD(month, 0-@intPeriod, GETDATE())) as nvarchar)
		AND
		uidApplicationId IN (SELECT uidApplicationId FROM #tmpUserApplications)		
)
SELECT
	'1' as series,
	S1T.nvcTranslation as x,
	(
		SELECT COUNT(*)
		FROM #tmpUserApplications A
		WHERE
			A.uidApplicationWorkflowStepId = S1.uidId
	) as y
FROM
	sequencedApplicationHistory H1
RIGHT JOIN
	refApplicationWorkflowStep S1 ON H1.uidApplicationWorkflowStepId = S1.uidId AND	S1.uidId IN (SELECT uidId FROM #tmpUserApplicationWorkflowSteps)
LEFT JOIN
	relUserDataTranslation S1T ON S1.uidUserDataItemId_InternalNameId= S1T.uidUserDataItemId AND S1t.uidLanguageId = @uidLanguageId
LEFT JOIN
	sequencedApplicationHistory H2 ON H1.uidApplicationId = H2.uidApplicationId AND H1.intOrder = H2.intOrder-1
GROUP BY
	S1.uidId, S1T.nvcTranslation, S1.nvcName, S1.intSortOrder
ORDER BY
	S1.intSortOrder
	
DROP TABLE #tmpUserApplicationWorkflowSteps
DROP TABLE #tmpUserRequisitionWorkflowSteps
DROP TABLE #tmpUserRequisitions
DROP TABLE #tmpUserApplications
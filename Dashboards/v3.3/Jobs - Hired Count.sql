SET NOCOUNT ON;

DECLARE @uidUserId uniqueidentifier = '0EDC2E28-002E-4F3F-BCC7-21B44A54692B'
DECLARE @uidLanguageId uniqueidentifier = '4850874D-715B-4950-B188-738E2FFC1520'
DECLARE @intPeriod int = 12
		
--#tmpUserApplicationWorkflowSteps		
SELECT * INTO #tmpUserApplicationWorkflowSteps
FROM refApplicationWorkflowStep
WHERE uidId IN 
(
	SELECT uidApplicationWorkflowStepId 
	FROM relApplicationWorkflowStepPermission 
	WHERE uidRoleId IN (SELECT uidRoleId FROM relRoleMembership WHERE uidUserId = @uidUserId) 
)
AND uidId = 'D48D37A6-FF45-4A2A-B6C4-C87FE3123809'

--#tmpUserRequisitionWorkflowSteps			
SELECT * INTO #tmpUserRequisitionWorkflowSteps
FROM refRequisitionWorkflowStep
WHERE uidId IN 
(
	SELECT uidRequisitionWorkflowStepId 
	FROM relRequisitionWorkflowStepPermission 
	WHERE uidRoleId IN (SELECT uidRoleId FROM relRoleMembership WHERE uidUserId = @uidUserId) 
)

--#tmpUserRequisitions
SELECT * INTO #tmpUserRequisitions
FROM dtlRequisition
WHERE
	uidId IN (SELECT uidRequisitionId FROM relRecruiterRequisition WHERE uidRecruiterId IN (SELECT uidId FROM dtlRecruiter WHERE uidUserId = @uidUserId))
	OR
	uidRequisitionWorkflowStepId IN (SELECT uidId FROM #tmpUserRequisitionWorkflowSteps)

--#tmpUserApplications
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
		uidApplicationId IN (SELECT uidApplicationId FROM #tmpUserApplications)		
)

select '#HIRESCOUNT#' as tag,
( SELECT COUNT(*) FROM #tmpUserApplications A WHERE A.uidApplicationWorkflowStepId = 'D48D37A6-FF45-4A2A-B6C4-C87FE3123809') as value

	
DROP TABLE #tmpUserApplicationWorkflowSteps
DROP TABLE #tmpUserRequisitionWorkflowSteps
DROP TABLE #tmpUserRequisitions
DROP TABLE #tmpUserApplications
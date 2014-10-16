-- Jobs - Age of Active Job (simplified).sql
-- Requirements
-- ============
-- Active = (Jobs where RWF step = Review and jobs where published = true)
-- Age = (Days spent in steps where published = true + days spent in RWF step = review)
-- Data context = user specific based on Job access level (AllRequisitions | AsssignedRequisitions)

SET NOCOUNT ON;

-- REMOVE NEXT LINE BEFORE DEPLOYING TO SYSTEM
DECLARE @uidUserId uniqueidentifier = '3427F1F9-B3C3-4A14-9579-C82F5BAD73AF' --Ian
DECLARE @uidRequisitionId uniqueidentifier = 'CBA0C484-9DD6-4B3C-A9C1-007E7B4F3494'
			
SELECT uidId INTO #tmpUserRequisitionWorkflowSteps
FROM refRequisitionWorkflowStep
WHERE uidId IN 
(
	SELECT uidRequisitionWorkflowStepId 
	FROM relRequisitionWorkflowStepPermission 
	WHERE uidRoleId IN (SELECT uidRoleId FROM relRoleMembership WHERE uidUserId = @uidUserId) 
)
AND bitPublished = 1
OR uidId = '82288BB5-1977-4932-B035-70570820B4EF'

SELECT uidId INTO #tmpUserRequisitions
FROM dtlRequisition
WHERE uidId = @uidRequisitionId 

	
SELECT RWA.uidRequisitionId, DATEDIFF(dd, MIN(RWA.dteLandingDate), GETDATE()) AS intDaysActive
INTO #tmpRequisitionAgeSinceActive
FROM refRequisitionWorkflowStep RWS
JOIN relRequisitionWorkflowAction RWA
ON RWS.uidId = RWA.uidRequisitionWorkflowStepId
WHERE RWS.bitPublished = 1
AND RWA.uidRequisitionId IN 
(
	SELECT uidId
	FROM #tmpUserRequisitions
)
GROUP BY RWA.uidRequisitionId
	

SELECT intDaysActive AS 'Age (days)'
FROM #tmpRequisitionAgeSinceActive

DROP TABLE #tmpUserRequisitionWorkflowSteps
DROP TABLE #tmpUserRequisitions
DROP TABLE #tmpRequisitionAgeSinceActive
SET NOCOUNT ON;  

DECLARE @uidUserId uniqueIdentifier = '0EDC2E28-002E-4F3F-BCC7-21B44A54692B'

SELECT uidId INTO #tmpUserApplicationWorkflowSteps 
FROM refApplicationWorkflowStep WHERE uidId IN  
(  
	SELECT uidApplicationWorkflowStepId   
	FROM relApplicationWorkflowStepPermission   
	WHERE uidRoleId IN 
		(SELECT uidRoleId FROM relRoleMembership WHERE uidUserId = @uidUserId)  
)     

SELECT uidId INTO #tmpUserRequisitionWorkflowSteps 
FROM refRequisitionWorkflowStep 
WHERE nvcName <> 'Library' AND uidId IN  
(  
	SELECT uidRequisitionWorkflowStepId   
	FROM relRequisitionWorkflowStepPermission   
	WHERE uidRoleId IN 
		(SELECT uidRoleId FROM relRoleMembership WHERE uidUserId = @uidUserId)  
)  
	
SELECT uidId INTO #tmpUserRequisitions 
FROM dtlRequisition 
WHERE  uidId IN 
(
	SELECT uidRequisitionId 
	FROM relRecruiterRequisition 
	WHERE uidRecruiterId IN 
	(SELECT uidId FROM dtlRecruiter WHERE uidUserId = @uidUserId)
)  
OR  uidRequisitionWorkflowStepId IN 
	(SELECT uidId FROM #tmpUserRequisitionWorkflowSteps)  
	
SELECT uidId INTO #tmpUserApplications 
FROM relApplication 
WHERE  uidRequisitionId IN 
	(SELECT uidId FROM #tmpUserRequisitions)  
	AND  uidApplicationWorkflowStepId IN 
		(SELECT uidId FROM #tmpUserApplicationWorkflowSteps)   
		

SELECT '#CANDIDATECOUNT#' as tag, COUNT(*) as value FROM dtlCandidate  
WHERE  
(   
	uidWebsiteId IN 
	(
		SELECT uidWebsiteId FROM relWebsitePermission WHERE enmPermission = 1 AND uidRoleId IN 
		(
			SELECT uidRoleId FROM relRoleMembership WHERE uidUserId = @uidUserId
		)
	) 
) 
UNION 
SELECT '#REQUISITIONCOUNT#' as tag, COUNT(*) as value FROM #tmpUserRequisitions 
UNION 
SELECT '#APPLICATIONCOUNT#' as tag, COUNT(*) as value FROM #tmpUserApplications  

DROP TABLE #tmpUserApplicationWorkflowSteps 
DROP TABLE #tmpUserRequisitionWorkflowSteps 
DROP TABLE #tmpUserRequisitions 
DROP TABLE #tmpUserApplications
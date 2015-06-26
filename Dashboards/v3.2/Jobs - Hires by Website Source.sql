-- Jobs - Hires by Website Source.sql
-- 20150507
-- Count the candidates hired by Website souce. Filer by recruiter user
SET NOCOUNT ON;  

SELECT uidId INTO #tmpUserApplicationWorkflowSteps 
FROM refApplicationWorkflowStep 
WHERE uidId IN  
(  
	SELECT uidApplicationWorkflowStepId   
	FROM relApplicationWorkflowStepPermission   
	WHERE uidRoleId IN   
	(   
		SELECT uidRoleId FROM relRoleMembership WHERE uidUserId = @uidUserId 
	) 
) 
AND uidId = 'D48D37A6-FF45-4A2A-B6C4-C87FE3123809'     

SELECT uidId, uidCandidateId INTO #tmpUserApplications 
FROM relApplication 
WHERE uidApplicationWorkflowStepId IN  
	(SELECT uidId FROM #tmpUserApplicationWorkflowSteps)
	
SELECT W.nvcName as Website, 
COUNT(*) as Total 
FROM refWebsite W 
JOIN dtlCandidate C  ON C.uidWebsiteId = W.uidId WHERE 
(
	W.uidId IN   
	(   
		SELECT uidWebsiteId FROM relWebsitePermission WHERE enmPermission = 1 AND uidRoleId IN    
		(    
			SELECT uidRoleId FROM relRoleMembership WHERE uidUserId = @uidUserId   
		)  
	) 
) AND 
(  
	C.uidId IN   
	(SELECT uidCandidateId FROM #tmpUserApplications) 
) 
GROUP BY W.nvcName 
ORDER BY W.nvcName  

DROP TABLE #tmpUserApplicationWorkflowSteps 
DROP TABLE #tmpUserApplications
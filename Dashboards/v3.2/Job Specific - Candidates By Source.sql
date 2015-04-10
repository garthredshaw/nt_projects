SET NOCOUNT ON;

SELECT * INTO #tmpUserApplicationWorkflowSteps
FROM refApplicationWorkflowStep
WHERE uidId IN 
(
	SELECT uidApplicationWorkflowStepId 
	FROM relApplicationWorkflowStepPermission 
	WHERE uidRoleId IN (SELECT uidRoleId FROM relRoleMembership WHERE uidUserId = @uidUserId) 
)
			
SELECT * INTO #tmpUserApplications
FROM relApplication
WHERE
	uidRequisitionId = @uidRequisitionId
	AND
	uidApplicationWorkflowStepId IN (SELECT uidId FROM #tmpUserApplicationWorkflowSteps)

SELECT
	'1' as series,
	W.nvcName as x,
	COUNT(*) as y,
	COUNT(*) as s
FROM 
	refWebsite W
JOIN
	dtlCandidate C ON C.uidWebsiteId = W.uidId
WHERE
	(
		W.uidId IN (SELECT uidWebsiteId FROM relWebsitePermission WHERE enmPermission = 1 AND uidRoleId IN (SELECT uidRoleId FROM relRoleMembership WHERE uidUserId = @uidUserId))
	)
        AND
        (C.uidId IN (SELECT uidCandidateId FROM #tmpUserApplications))
GROUP BY
	W.nvcName
ORDER BY
	W.nvcName

DROP TABLE #tmpUserApplicationWorkflowSteps
DROP TABLE #tmpUserApplications
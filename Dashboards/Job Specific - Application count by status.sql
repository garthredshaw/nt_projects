-- Neptune dashboards - Jobs (individual) - Candidates per workflow step.sql

SET NOCOUNT ON;
		
SELECT * INTO #tmpUserApplicationWorkflowSteps
FROM refApplicationWorkflowStep
WHERE uidId IN 
(
	SELECT uidApplicationWorkflowStepId 
	FROM relApplicationWorkflowStepPermission 
	WHERE uidRoleId IN 
	(
		SELECT uidRoleId 
		FROM relRoleMembership 
		WHERE uidUserId = @uidUserId
	) 
)
			
SELECT * INTO #tmpUserApplications
FROM relApplication
WHERE uidRequisitionId = @uidRequisitionId
AND	uidApplicationWorkflowStepId IN 
(
	SELECT uidId 
	FROM #tmpUserApplicationWorkflowSteps
)
	
;WITH sequencedApplicationHistory AS
(
	SELECT ROW_NUMBER() OVER (ORDER BY uidApplicationId, dteLandingDate) AS intOrder,
	*
	FROM relApplicationWorkflowHistory
	WHERE dteLandingDate > '1 ' + DATENAME(month, (DATEADD(month, 0-@intPeriod, GETDATE()))) + ' ' + CAST(YEAR(DATEADD(month, 0-@intPeriod, GETDATE())) as nvarchar)
	AND uidApplicationId IN 
	(
		SELECT uidApplicationId 
		FROM #tmpUserApplications
	)		
)

SELECT '1' as series,
S1T.nvcTranslation as x,
(
	SELECT COUNT(*)
	FROM #tmpUserApplications A
	WHERE A.uidApplicationWorkflowStepId = S1.uidId
) as y
FROM sequencedApplicationHistory H1
RIGHT JOIN refApplicationWorkflowStep S1 
ON H1.uidApplicationWorkflowStepId = S1.uidId AND S1.uidId IN 
(
	SELECT uidId 
	FROM #tmpUserApplicationWorkflowSteps
)
LEFT JOIN relUserDataTranslation S1T 
ON S1.uidUserDataItemId_InternalNameId= S1T.uidUserDataItemId AND S1t.uidLanguageId = @uidLanguageId
LEFT JOIN sequencedApplicationHistory H2 
ON H1.uidApplicationId = H2.uidApplicationId AND H1.intOrder = H2.intOrder-1
GROUP BY S1.uidId, S1T.nvcTranslation, S1.nvcName, S1.intSortOrder
ORDER BY S1.intSortOrder
	
DROP TABLE #tmpUserApplicationWorkflowSteps
DROP TABLE #tmpUserApplications
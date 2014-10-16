SET NOCOUNT ON;
	
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
	
;WITH sequencedRequisitionHistory AS 
(
	SELECT
		ROW_NUMBER() OVER (ORDER BY uidRequisitionId, dteLandingDate) as intOrder,
		*
	FROM relRequisitionWorkflowAction
	WHERE
		dteLandingDate > '1 ' + DATENAME(month, (DATEADD(month, 0-@intPeriod, GETDATE()))) + ' ' + CAST(YEAR(DATEADD(month, 0-@intPeriod, GETDATE())) as nvarchar)
		AND
		uidRequisitionId IN (SELECT uidRequisitionId FROM #tmpUserRequisitions)		
)
SELECT
	'1' as series,
	S1T.nvcTranslation as x,
	(
		SELECT COUNT(*)
		FROM #tmpUserRequisitions A
		WHERE
			A.uidRequisitionWorkflowStepId = S1.uidId
	) as y
FROM
	sequencedRequisitionHistory H1
RIGHT JOIN
	refRequisitionWorkflowStep S1 ON H1.uidRequisitionWorkflowStepId = S1.uidId AND S1.uidId IN (SELECT uidId FROM #tmpUserRequisitionWorkflowSteps)
LEFT JOIN
	relUserDataTranslation S1T ON S1.uidUserDataItemId_InternalNameId= S1T.uidUserDataItemId AND S1t.uidLanguageId = @uidLanguageId
LEFT JOIN
	sequencedRequisitionHistory H2 ON H1.uidRequisitionId = H2.uidRequisitionId AND H1.intOrder = H2.intOrder-1
GROUP BY
	S1.uidId, S1T.nvcTranslation, S1.nvcName, S1.intSortOrder
ORDER BY
	S1.intSortOrder

DROP TABLE #tmpUserRequisitionWorkflowSteps
DROP TABLE #tmpUserRequisitions
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
	RIT.nvcTranslation as x,
	COUNT(*) as y,
	COUNT(*) as s
FROM
	refReferenceDataItem RI
JOIN
	relReferenceDataTranslation RIT ON RI.uidId = RIT.uidReferenceDataItemId AND RIT.uidLanguageId = @uidLanguageId
JOIN
	neptune_dynamic_objects.relCandidateFieldValue_CBAE5C2B870E48D0A8C280B713CEB2B4 CFV ON CFV.uidIdValue = RI.uidId
JOIN
	relCandidateSectionValue CSV ON CFV.uidCandidateSectionValueId = CSV.uidId
JOIN
	dtlCandidate C ON CSV.uidCandidateId = C.uidId
WHERE
	CFV.uidCandidateFieldId = '4139CFC2-E110-4D3F-B7BC-769BE572BFDB'
	AND
	(
		C.uidWebsiteId IN (SELECT uidWebsiteId FROM relWebsitePermission WHERE enmPermission = 1 AND uidRoleId IN (SELECT uidRoleId FROM relRoleMembership WHERE uidUserId = @uidUserId))
	)
        AND
        (C.uidId IN (SELECT uidCandidateId FROM #tmpUserApplications))
GROUP BY
	RI.uidId, RIT.nvcTranslation
ORDER BY
	RIT.nvcTranslation

DROP TABLE #tmpUserApplicationWorkflowSteps
DROP TABLE #tmpUserApplications
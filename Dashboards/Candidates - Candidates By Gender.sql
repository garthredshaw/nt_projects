SET NOCOUNT ON;

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
	CFV.uidCandidateFieldId = '9119C19F-1736-4D23-8723-F856D741F326'
	AND
	(
		C.uidWebsiteId IN (SELECT uidWebsiteId FROM relWebsitePermission WHERE enmPermission = 1 AND uidRoleId IN (SELECT uidRoleId FROM relRoleMembership WHERE uidUserId = @uidUserId))
	)
GROUP BY
	RI.uidId, RIT.nvcTranslation
ORDER BY
	RIT.nvcTranslation
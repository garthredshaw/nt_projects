SET NOCOUNT ON;

SELECT
	'1' as series,
	A.nvcName as x,
	COUNT(*) as y,
	COUNT(*) as s
FROM 
	dtlAgency A
JOIN
	relAgencyCandidate AC ON AC.uidAgencyId = A.uidId
JOIN
	dtlCandidate C ON AC.uidCandidateId = C.uidId
JOIN
	refWebsite W ON C.uidWebsiteId = W.uidId
WHERE
	(
		W.uidId IN (SELECT uidWebsiteId FROM relWebsitePermission WHERE enmPermission = 1 AND uidRoleId IN (SELECT uidRoleId FROM relRoleMembership WHERE uidUserId = @uidUserId))
	)
GROUP BY
	A.nvcName
ORDER BY
	A.nvcName
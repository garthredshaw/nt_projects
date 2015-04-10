SET NOCOUNT ON;

SELECT
	'1' as series,
	W.nvcName as x,
	COUNT(*) as y,
	COUNT(*) as s
FROM 
	refWebsite W
JOIN
	dtlCandidate C ON C.uidWebsiteId = W.uidId
JOIN
	relApplication A ON A.uidCandidateId = C.uidId
WHERE
	(
		W.uidId IN (SELECT uidWebsiteId FROM relWebsitePermission WHERE enmPermission = 1 AND uidRoleId IN (SELECT uidRoleId FROM relRoleMembership WHERE uidUserId = @uidUserId))
	)
GROUP BY
	W.nvcName
ORDER BY
	W.nvcName
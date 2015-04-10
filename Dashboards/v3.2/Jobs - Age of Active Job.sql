SET NOCOUNT ON;

			
SELECT * INTO #tmpUserRequisitionWorkflowSteps
FROM refRequisitionWorkflowStep
WHERE uidId IN 
(
	SELECT uidRequisitionWorkflowStepId 
	FROM relRequisitionWorkflowStepPermission 
	WHERE uidRoleId IN (SELECT uidRoleId FROM relRoleMembership WHERE uidUserId = @uidUserId) 
)
AND bitPublished = 1
OR uidId = '82288BB5-1977-4932-B035-70570820B4EF'

SELECT * INTO #tmpUserRequisitions
FROM dtlRequisition
WHERE uidId IN 
(
	SELECT uidRequisitionId 
	FROM relRecruiterRequisition 
	WHERE uidRecruiterId IN 
	(
		SELECT uidId 
		FROM dtlRecruiter 
		WHERE uidUserId = @uidUserId
	)
)
OR uidRequisitionWorkflowStepId IN 
(
	SELECT uidId 
	FROM #tmpUserRequisitionWorkflowSteps
)
	
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
	

SELECT R.nvcReferenceCode AS 'Ref #'
, RFV.nvcStringValue AS 'Job Title'
,(
	SELECT TOP 1 R2.nvcFirstname + ' ' + R2.nvcLastname AS 'Owner'
	FROM dtlRecruiter R2
	JOIN relRecruiterRequisition RR2
	ON R2.uidId = RR2.uidRecruiterId 
	WHERE RR2.enmRecruiterRequisitionType = 2
	AND RR2.uidRequisitionId = R.uidId
) AS 'Job Owner'
, RWS.nvcName AS 'Job Status'
, RASA.intDaysActive AS 'Age (days)'
FROM refRequisitionWorkflowStep RWS
JOIN dtlRequisition R ON RWS.uidId = R.uidRequisitionWorkflowStepId
JOIN relRequisitionSectionValue RSV ON  R.uidId = RSV.uidRequisitionId
JOIN relRequisitionFieldValue RFV ON RSV.uidId = RFV.uidRequisitionSectionValueId AND RFV.uidRequisitionFieldId = '01B513BA-C40A-4D50-8B44-FAF0DDC7BB40'
JOIN #tmpRequisitionAgeSinceActive RASA ON R.uidId = RASA.uidRequisitionId
ORDER BY RASA.intDaysActive DESC, R.nvcReferenceCode

DROP TABLE #tmpUserRequisitionWorkflowSteps
DROP TABLE #tmpUserRequisitions
DROP TABLE #tmpRequisitionAgeSinceActive
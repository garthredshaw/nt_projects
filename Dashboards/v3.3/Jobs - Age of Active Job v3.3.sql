-- Jobs - Age of Active Job.sql
-- Requirements
-- ============
-- Active = (Jobs where RWF step = Review and jobs where published = true)
-- Age = (Days spent in steps where published = true + days spent in RWF step = review)
-- Data context = user specific based on Job access level (AllRequisitions | AsssignedRequisitions)

SET NOCOUNT ON;

-- REMOVE NEXT LINE BEFORE DEPLOYING TO SYSTEM
DECLARE @uidUserId uniqueidentifier = '0EDC2E28-002E-4F3F-BCC7-21B44A54692B'

			
SELECT uidId INTO #tmpUserRequisitionWorkflowSteps
FROM refRequisitionWorkflowStep
WHERE uidId IN 
(
	SELECT uidRequisitionWorkflowStepId 
	FROM relRequisitionWorkflowStepPermission 
	WHERE uidRoleId IN (SELECT uidRoleId FROM relRoleMembership WHERE uidUserId = @uidUserId) 
)
AND uidId = 'DD84363C-D03D-46F1-9DD9-633806951E06' 

SELECT uidId INTO #tmpUserRequisitions
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
AND uidId IN
(
	-- FILTER ONLY JOBS THAT ARE CURRENTLY PUBLISHED OR HAVE BEEN PREVIOUSLY PUBLISHED
	SELECT uidRequisitionId FROM relRequisitionWebsite WHERE dteStartDate <= GETDATE()
)
	
SELECT RWH.uidRequisitionId, DATEDIFF(dd, MIN(RWH.dteLandingDate), GETDATE()) AS intDaysActive
INTO #tmpRequisitionAgeSinceActive
FROM refRequisitionWorkflowStep RWS
JOIN relRequisitionWorkflowHistory RWH
ON RWS.uidId = RWH.uidRequisitionWorkflowStepId
WHERE RWH.uidRequisitionId IN 
(
	SELECT uidId
	FROM #tmpUserRequisitions
)
GROUP BY RWH.uidRequisitionId
	

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
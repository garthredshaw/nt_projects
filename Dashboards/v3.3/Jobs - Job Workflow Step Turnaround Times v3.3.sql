SET NOCOUNT ON;

DECLARE @uidUserId uniqueidentifier = '0EDC2E28-002E-4F3F-BCC7-21B44A54692B'
DECLARE @uidLanguageId uniqueidentifier = '4850874D-715B-4950-B188-738E2FFC1520'
DECLARE @intPeriod int = 12

	
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
	AND
	uidRequisitionWorkflowStepId <> '5CFBBA0A-EAB9-45E5-A9AF-8AF292B0AAD4' -- LIBRARY
	
;WITH sequencedRequisitionHistory AS 
(
	SELECT
		ROW_NUMBER() OVER (ORDER BY uidRequisitionId, dteLandingDate) as intOrder,
		*
	FROM relRequisitionWorkflowHistory
	WHERE
		dteLandingDate > '1 ' + DATENAME(month, (DATEADD(month, 0-@intPeriod, GETDATE()))) + ' ' + CAST(YEAR(DATEADD(month, 0-@intPeriod, GETDATE())) as nvarchar)
		AND
		uidRequisitionId IN (SELECT uidRequisitionId FROM #tmpUserRequisitions)		
)
SELECT
	'1' as series,
	S1T.nvcTranslation as x,
	AVG(ISNULL((CAST(DATEDIFF(second, H1.dteLandingDate, H2.dteLandingDate) as float) / 86400.00),-0)) as y
FROM
	sequencedRequisitionHistory H1
RIGHT JOIN
	refRequisitionWorkflowStep S1 ON H1.uidRequisitionWorkflowStepId = S1.uidId AND S1.uidId IN (SELECT uidId FROM #tmpUserRequisitionWorkflowSteps)
LEFT JOIN
	relUserDataTranslation S1T ON S1.uidUserDataItemId_InternalNameId= S1T.uidUserDataItemId AND S1t.uidLanguageId = @uidLanguageId
LEFT JOIN
	sequencedRequisitionHistory H2 ON H1.uidRequisitionId = H2.uidRequisitionId AND H1.intOrder = H2.intOrder-1
WHERE S1.nvcName <>'Library'
GROUP BY
	S1.uidId, S1T.nvcTranslation, S1.nvcName, S1.intSortOrder
ORDER BY
	S1.intSortOrder

DROP TABLE #tmpUserRequisitionWorkflowSteps
DROP TABLE #tmpUserRequisitions
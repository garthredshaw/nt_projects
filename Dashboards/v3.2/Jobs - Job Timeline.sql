SET NOCOUNT ON;

CREATE TABLE #tmpTimeLine
(
	intMonth int,
	intYear int
)

DECLARE @dtePeriodDate datetime
DECLARE @intCount int
SELECT @intCount = 0

WHILE @intCount < @intPeriod
BEGIN
	SELECT @dtePeriodDate = DATEADD(month, 0 - @intCount, GETDATE())
	INSERT INTO #tmpTimeLine (intMonth, intYear) VALUES (MONTH(@dtePeriodDate), YEAR(@dtePeriodDate))

	SELECT @intCount = @intCount + 1
END
			
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
	
--Requisition Timeline
SELECT
	'1' as series,
	LEFT(DATENAME(month, DATEADD(month, TL.intMonth - 1, 0)), 3) + ' ' + RIGHT(CAST(TL.intYear as nvarchar), 2) as x,
	ISNULL(CTL.intRequisitions, 0) as y
FROM 
	#tmpTimeLine TL
	LEFT JOIN 		
	(
		SELECT
			MONTH(dteCreationDate) as intMonth,
			YEAR(dteCreationDate) intYear,
			COUNT(*) as intRequisitions
		FROM
			#tmpUserRequisitions
		WHERE
			dteCreationDate > '1 ' + DATENAME(month, (DATEADD(month, 0-@intPeriod, GETDATE()))) + ' ' + CAST(YEAR(DATEADD(month, 0-@intPeriod, GETDATE())) as nvarchar)
		GROUP BY
			MONTH(dteCreationDate), YEAR(dteCreationDate)
	) as CTL ON TL.intMonth = CTL.intMonth AND TL.intYear = CTL.intYear
ORDER BY
	TL.intYear, TL.intMonth		

DROP TABLE #tmpTimeLine
DROP TABLE #tmpUserRequisitionWorkflowSteps
DROP TABLE #tmpUserRequisitions
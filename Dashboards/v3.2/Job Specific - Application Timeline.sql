SET NOCOUNT ON;

CREATE TABLE #tmpTimeLine
(
	intMonth int,
	intYear int
)

DECLARE @dtePeriodDate datetime
DECLARE @intCount int
SELECT @intCount = 0

DECLARE @intFullPeriod int
SELECT @intFullPeriod = DATEDIFF(month, MIN(dteApplicationDate), GETDATE()) + 1 FROM relApplication WHERE uidRequisitionId = @uidRequisitionId

WHILE @intCount < @intFullPeriod
BEGIN
	SELECT @dtePeriodDate = DATEADD(month, 0 - @intCount, GETDATE())
	INSERT INTO #tmpTimeLine (intMonth, intYear) VALUES (MONTH(@dtePeriodDate), YEAR(@dtePeriodDate))

	SELECT @intCount = @intCount + 1
END

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
	
--Application Timeline
SELECT
	'1' as series,
	LEFT(DATENAME(month, DATEADD(month, TL.intMonth - 1, 0)), 3) + ' ' + RIGHT(CAST(TL.intYear as nvarchar), 2) as x,
	ISNULL(CTL.intApplications, 0) as y
FROM 
	#tmpTimeLine TL
	LEFT JOIN 		
	(
		SELECT
			MONTH(dteApplicationDate) as intMonth,
			YEAR(dteApplicationDate) intYear,
			COUNT(*) as intApplications
		FROM
			#tmpUserApplications
		WHERE
			dteApplicationDate > '1 ' + DATENAME(month, (DATEADD(month, 0-@intFullPeriod, GETDATE()))) + ' ' + CAST(YEAR(DATEADD(month, 0-@intFullPeriod, GETDATE())) as nvarchar)
		GROUP BY
			MONTH(dteApplicationDate), YEAR(dteApplicationDate)
	) as CTL ON TL.intMonth = CTL.intMonth AND TL.intYear = CTL.intYear
ORDER BY
	TL.intYear, TL.intMonth	

	
DROP TABLE #tmpTimeLine
DROP TABLE #tmpUserApplicationWorkflowSteps
DROP TABLE #tmpUserApplications
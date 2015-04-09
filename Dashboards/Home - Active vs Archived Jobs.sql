SET NOCOUNT ON;  


CREATE TABLE #tmpTimeLine 
(
  intMonth int,  
  intYear int,
  dteDayMonthYear datetime 
)  

DECLARE @dtePeriodDate datetime 
DECLARE @intCount int 
SELECT @intCount = 0  

WHILE @intCount < @intPeriod 
BEGIN  
	SELECT @dtePeriodDate = DATEADD(month, 0 - @intCount, GETDATE())  
	INSERT INTO #tmpTimeLine (intMonth, intYear, dteDayMonthYear) 
	VALUES (MONTH(@dtePeriodDate), YEAR(@dtePeriodDate), DATEADD(dd, -DAY(@dtePeriodDate) + 1, @dtePeriodDate))   
	
	SELECT @intCount = @intCount + 1 
END     

SELECT * INTO #tmpUserRequisitionWorkflowSteps 
FROM refRequisitionWorkflowStep 
WHERE uidId IN  
(  
	SELECT uidRequisitionWorkflowStepId   
	FROM relRequisitionWorkflowStepPermission   
	WHERE uidRoleId IN 
	(
		SELECT uidRoleId 
		FROM relRoleMembership 
		WHERE uidUserId = @uidUserId
	)  
) 
AND nvcName = 'Sourcing'
OR nvcName = 'Archived'


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
AND uidRequisitionWorkflowStepId IN 
(
	SELECT uidId FROM #tmpUserRequisitionWorkflowSteps
)   


CREATE TABLE #tmpUserRequisitionsSeries 
(
  nvcSeries nvarchar(MAX),  
  nvcYearMonth datetime, 
  nvcX nvarchar(MAX), 
  intY int
)
	

INSERT INTO #tmpUserRequisitionsSeries
SELECT 'Advertised' as series,
dteDayMonthYear,
LEFT(DATENAME(month, DATEADD(month, TL.intMonth - 1, 0)), 3) + ' ' + RIGHT(CAST(TL.intYear as nvarchar), 2) as x,
ISNULL(CTL.intRequisitions, 0) as y 
FROM #tmpTimeLine TL
LEFT JOIN     
(
	SELECT MONTH(B.dteCreationDate) as intMonth,
	YEAR(B.dteCreationDate) intYear,    
	COUNT(B.uidId) as intRequisitions  
	FROM #tmpUserRequisitionWorkflowSteps A
	JOIN #tmpUserRequisitions B
	ON A.uidId = B.uidRequisitionWorkflowStepId   
	WHERE dteCreationDate > '1 ' + DATENAME(month, (DATEADD(month, 0-@intPeriod, GETDATE()))) + ' ' + CAST(YEAR(DATEADD(month, 0-@intPeriod, GETDATE())) as nvarchar)
	AND A.nvcName = 'Sourcing'
	GROUP BY MONTH(dteCreationDate), YEAR(dteCreationDate)

) AS CTL 
ON TL.intMonth = CTL.intMonth AND TL.intYear = CTL.intYear 
ORDER BY TL.intYear, TL.intMonth  

INSERT INTO #tmpUserRequisitionsSeries
SELECT 'Archived' as series,
dteDayMonthYear,
LEFT(DATENAME(month, DATEADD(month, TL.intMonth - 1, 0)), 3) + ' ' + RIGHT(CAST(TL.intYear as nvarchar), 2) as x,
ISNULL(CTL.intRequisitions, 0) as y 
FROM #tmpTimeLine TL
LEFT JOIN     
(
	SELECT MONTH(B.dteCreationDate) as intMonth,
	YEAR(B.dteCreationDate) intYear,    
	COUNT(B.uidId) as intRequisitions  
	FROM #tmpUserRequisitionWorkflowSteps A
	JOIN #tmpUserRequisitions B
	ON A.uidId = B.uidRequisitionWorkflowStepId   
	WHERE dteCreationDate > '1 ' + DATENAME(month, (DATEADD(month, 0-@intPeriod, GETDATE()))) + ' ' + CAST(YEAR(DATEADD(month, 0-@intPeriod, GETDATE())) as nvarchar)
	AND A.nvcName = 'Archived'
	GROUP BY MONTH(dteCreationDate), YEAR(dteCreationDate)

) AS CTL 
ON TL.intMonth = CTL.intMonth AND TL.intYear = CTL.intYear 
ORDER BY TL.intYear, TL.intMonth 


SELECT CAST(YEAR(nvcYearMonth) as nvarchar) + ' - ' + CAST(MONTH(nvcYearMonth) as nvarchar) AS Period, [Advertised] AS Advertised, [Archived] AS Archived
FROM 
(
    SELECT nvcYearMonth, nvcSeries, intY
    FROM #tmpUserRequisitionsSeries
) as s
PIVOT
(
    SUM(intY)
    FOR nvcSeries IN ([Advertised], [Archived])
)AS pvt
ORDER BY pvt.nvcYearMonth 

DROP TABLE #tmpUserRequisitionsSeries
DROP TABLE #tmpTimeLine 
DROP TABLE #tmpUserRequisitionWorkflowSteps 
DROP TABLE #tmpUserRequisitions
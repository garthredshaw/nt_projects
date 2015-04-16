SET NOCOUNT ON;  

CREATE TABLE #tmpTimeLine (  intMonth int,  intYear int )  

DECLARE @dtePeriodDate datetime 
DECLARE @intCount int 


DECLARE @intPeriod int 
SET @intPeriod = 12

DECLARE @uidUserId uniqueIdentifier = '0EDC2E28-002E-4F3F-BCC7-21B44A54692B'

SELECT @intCount = 0  

WHILE @intCount < @intPeriod 
BEGIN  
	SELECT @dtePeriodDate = DATEADD(month, 0 - @intCount, GETDATE())  
	INSERT INTO #tmpTimeLine (intMonth, intYear) 
	VALUES (MONTH(@dtePeriodDate), YEAR(@dtePeriodDate))   
	SELECT @intCount = @intCount + 1 
END     

SELECT uidId INTO #tmpUserRequisitionWorkflowSteps 
FROM refRequisitionWorkflowStep 
WHERE uidId IN  
(  
	SELECT uidRequisitionWorkflowStepId   
	FROM relRequisitionWorkflowStepPermission   
	WHERE uidRoleId IN (SELECT uidRoleId FROM relRoleMembership WHERE uidUserId = @uidUserId)  
)  
 

SELECT uidRequisitionId, MIN(dteStartDate) AS 'dteStartDate' INTO #tmpUserRequisitions 
FROM relRequisitionWebsite 
WHERE  uidRequisitionId IN 
(
	SELECT uidRequisitionId 
	FROM relRecruiterRequisition 
	WHERE uidRecruiterId IN (SELECT uidId FROM dtlRecruiter WHERE uidUserId = @uidUserId)
)  
OR uidRequisitionId IN 
(
	SELECT uidRequisitionWorkflowStepId FROM dtlRequisition WHERE uidRequisitionWorkflowStepId IN 
	(
		SELECT uidId FROM #tmpUserRequisitionWorkflowSteps
	)  
)
GROUP BY uidRequisitionId
 

SELECT  '1' as series,  
LEFT(DATENAME(month, DATEADD(month, TL.intMonth - 1, 0)), 3) + ' ' + RIGHT(CAST(TL.intYear as nvarchar), 2) as x,  
ISNULL(CTL.intRequisitions, 0) as y 
FROM   #tmpTimeLine TL  
LEFT JOIN     
(   
	SELECT MONTH(dteStartDate) as intMonth,    
	YEAR(dteStartDate) intYear,    
	COUNT(*) as intRequisitions   
	FROM #tmpUserRequisitions   
	WHERE dteStartDate > '1 ' + DATENAME(month, (DATEADD(month, 0-@intPeriod, GETDATE()))) + ' ' + CAST(YEAR(DATEADD(month, 0-@intPeriod, GETDATE())) as nvarchar)   
	GROUP BY MONTH(dteStartDate), YEAR(dteStartDate)  
) as CTL ON TL.intMonth = CTL.intMonth AND TL.intYear = CTL.intYear 
ORDER BY  TL.intYear, TL.intMonth    

DROP TABLE #tmpTimeLine 
DROP TABLE #tmpUserRequisitionWorkflowSteps 
DROP TABLE #tmpUserRequisitions
-- Home: Application Timeline.sql
-- 20150507
-- Display the number of candidate applications by month for the past year, filtered by user.

SET NOCOUNT ON;  

CREATE TABLE #tmpTimeLine (intMonth int, intYear int)  

DECLARE @dtePeriodDate datetime 
DECLARE @intCount int 

SELECT @intCount = 0  WHILE @intCount < @intPeriod 
BEGIN  
	SELECT @dtePeriodDate = DATEADD(month, 0 - @intCount, GETDATE())  
	INSERT INTO #tmpTimeLine (intMonth, intYear) 
	VALUES (MONTH(@dtePeriodDate), YEAR(@dtePeriodDate))   
	SELECT @intCount = @intCount + 1 
END  

SELECT uidId INTO #tmpUserApplicationWorkflowSteps 
FROM refApplicationWorkflowStep 
WHERE uidId IN  
(  
	SELECT uidApplicationWorkflowStepId FROM relApplicationWorkflowStepPermission WHERE uidRoleId IN 
	(
		SELECT uidRoleId FROM relRoleMembership WHERE uidUserId = @uidUserId
	)  
)     

SELECT uidId INTO #tmpUserRequisitionWorkflowSteps 
FROM refRequisitionWorkflowStep 
WHERE uidId IN  
(  
	SELECT uidRequisitionWorkflowStepId   
	FROM relRequisitionWorkflowStepPermission   
	WHERE uidRoleId IN 
	(
		SELECT uidRoleId FROM relRoleMembership WHERE uidUserId = @uidUserId
	)  
) 
AND nvcName <> 'Cancelled'  

SELECT uidId INTO #tmpUserRequisitions 
FROM dtlRequisition 
WHERE  uidId IN 
(
	SELECT uidRequisitionId FROM relRecruiterRequisition WHERE uidRecruiterId IN 
		(SELECT uidId FROM dtlRecruiter WHERE uidUserId = @uidUserId)
)  
OR uidRequisitionWorkflowStepId IN 
	(SELECT uidId FROM #tmpUserRequisitionWorkflowSteps)  
	
	
SELECT uidId, dteApplicationDate INTO #tmpUserApplications 
FROM relApplication 
WHERE  uidRequisitionId IN 
	(SELECT uidId FROM #tmpUserRequisitions)  
AND uidApplicationWorkflowStepId IN 
	(SELECT uidId FROM #tmpUserApplicationWorkflowSteps)   
	
SELECT  '1' as series,  
LEFT(DATENAME(month, DATEADD(month, TL.intMonth - 1, 0)), 3) + ' ' + RIGHT(CAST(TL.intYear as nvarchar), 2) as x,  
ISNULL(CTL.intApplications, 0) as y 
FROM #tmpTimeLine TL  
LEFT JOIN     
(   
	SELECT MONTH(dteApplicationDate) as intMonth,    
	YEAR(dteApplicationDate) intYear,    
	COUNT(*) as intApplications   
	FROM #tmpUserApplications   
	WHERE dteApplicationDate > '1 ' + DATENAME(month, (DATEADD(month, 0-@intPeriod, GETDATE()))) + ' ' + CAST(YEAR(DATEADD(month, 0-@intPeriod, GETDATE())) as nvarchar)   
	GROUP BY MONTH(dteApplicationDate), YEAR(dteApplicationDate)  
) as CTL ON TL.intMonth = CTL.intMonth AND TL.intYear = CTL.intYear 
ORDER BY TL.intYear, TL.intMonth     
	
DROP TABLE #tmpTimeLine 
DROP TABLE #tmpUserApplicationWorkflowSteps 
DROP TABLE #tmpUserRequisitionWorkflowSteps 
DROP TABLE #tmpUserRequisitions 
DROP TABLE #tmpUserApplications
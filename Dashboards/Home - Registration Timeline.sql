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


SELECT  '1' as series,  
LEFT(DATENAME(month, DATEADD(month, TL.intMonth - 1, 0)), 3) + ' ' + RIGHT(CAST(TL.intYear as nvarchar), 2) as x,  
ISNULL(CTL.intRegistrations, 0) as y 
FROM   #tmpTimeLine TL  
LEFT JOIN     
(   
	SELECT MONTH(dteRegistrationDate) as intMonth,
	YEAR(dteRegistrationDate) intYear,    
	COUNT(*) as intRegistrations   
	FROM dtlCandidate   
	WHERE dteRegistrationDate > '1 ' + DATENAME(month, (DATEADD(month, 0-@intPeriod, GETDATE()))) + ' ' + CAST(YEAR(DATEADD(month, 0-@intPeriod, GETDATE())) as nvarchar)    
	AND    
	(     
		uidWebsiteId IN 
		(
			SELECT uidWebsiteId FROM relWebsitePermission WHERE enmPermission = 1 AND uidRoleId IN 
			(
				SELECT uidRoleId FROM relRoleMembership WHERE uidUserId = @uidUserId
			)
		)    
	)   
	GROUP BY MONTH(dteRegistrationDate), YEAR(dteRegistrationDate)  
) as CTL ON TL.intMonth = CTL.intMonth AND TL.intYear = CTL.intYear 
ORDER BY  TL.intYear, TL.intMonth  

DROP TABLE #tmpTimeLine
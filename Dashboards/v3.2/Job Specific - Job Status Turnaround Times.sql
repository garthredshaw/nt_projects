SET NOCOUNT ON;

declare @uidUserId uniqueidentifier = 'DC7B875D-BE65-42E8-AF96-6AAC55FB68C1'
declare @uidLanguageId uniqueidentifier ='4850874D-715B-4950-B188-738E2FFC1520'
declare @uidRequisitionId uniqueidentifier = 'E4EFE966-796F-4304-B09E-0039B7EC117D'
declare @intPeriod int = 12

SELECT * INTO #tmpUserRequisitionWorkflowSteps
FROM refRequisitionWorkflowStep
WHERE uidId IN (SELECT uidRequisitionWorkflowStepId FROM relRequisitionWorkflowStepPermission WHERE uidRoleId IN (SELECT uidRoleId FROM relRoleMembership WHERE uidUserId = @uidUserId))AND uidID NOT IN ('5A67B6EC-2576-4A1C-9356-3C5C0A235245','77052EE6-A45E-4C2C-BFEF-9C34F47E1F67','82288BB5-1977-4932-B035-70570820B4EF','5CFBBA0A-EAB9-45E5-A9AF-8AF292B0AAD4','67A567F0-196B-4868-BE56-CCD2800C3051','8C49E81E-B43B-4502-9921-F9EF8E84546A')
SELECT * INTO #tmpUserRequisitions FROM dtlRequisition 
WHERE uidId = @uidRequisitionId
;WITH sequencedRequisitionHistory AS 
(
	SELECT ROW_NUMBER() OVER (ORDER BY uidRequisitionId, dteLandingDate) as intOrder,*
	FROM relRequisitionWorkflowHistory
	WHERE uidRequisitionId = @uidRequisitionId
	AND dteLandingDate > '1 '+DATENAME(month,(DATEADD(month,0-@intPeriod,GETDATE())))+' '+CAST(YEAR(DATEADD(month,0-@intPeriod,GETDATE()))As nvarchar) 
	--AND uidRequisitionId IN(SELECT uidRequisitionId FROM #tmpUserRequisitions)		
)
SELECT C.series,C.x,C.y FROM
(
	SELECT'1' as series,S1T.nvcTranslation as x,AVG(ISNULL((CAST(DATEDIFF(DAY,H1.dteLandingDate,H2.dteLandingDate)as float)),-0))as y,S1.intSortOrder
	FROM
		sequencedRequisitionHistory H1
	RIGHT JOIN
		refRequisitionWorkflowStep S1 ON H1.uidRequisitionWorkflowStepId = S1.uidId AND S1.uidId IN (SELECT uidId FROM #tmpUserRequisitionWorkflowSteps)
	LEFT JOIN
		relUserDataTranslation S1T ON S1.uidUserDataItemId_InternalNameId= S1T.uidUserDataItemId AND S1t.uidLanguageId = @uidLanguageId
	LEFT JOIN
		sequencedRequisitionHistory H2 ON H1.uidRequisitionId = H2.uidRequisitionId AND H1.intOrder = H2.intOrder-1
	WHERE S1.uidId IN (SELECT uidId FROM #tmpUserRequisitionWorkflowSteps)
	GROUP BY
		S1.uidId, S1T.nvcTranslation, S1.nvcName, S1.intSortOrder	
	UNION
	SELECT'1','Advertised',AVG(ISNULL((CAST(DATEDIFF(DAY, RW.dteStartDate, RW.dteEndDate) as float)),-0)) as y,4
	FROM relRequisitionWebsite RW WHERE uidRequisitionId = @uidRequisitionId
	UNION
	SELECT'1','Not Yet Advertised',AVG(ISNULL((CAST(CASE WHEN DATEDIFF(DAY,H1.dteLandingDate,RW.dteStartDate)< 1 THEN 0 ELSE DATEDIFF(DAY,H1.dteLandingDate,RW.dteStartDate)END as float)),-0)),3
	FROM
		(SELECT H.uidRequisitionId,H.uidRequisitionWorkflowStepId,MIN(H.dteLandingDate)AS dteLandingDate FROM sequencedRequisitionHistory H group by H.uidRequisitionId,H.uidRequisitionWorkflowStepId) H1
	RIGHT JOIN
		refRequisitionWorkflowStep S1 ON H1.uidRequisitionWorkflowStepId = S1.uidId AND S1.uidId IN(SELECT uidId FROM #tmpUserRequisitionWorkflowSteps)
	LEFT OUTER JOIN (SELECT uidRequisitionId, MIN(dteStartDate) as dteStartDate from relRequisitionWebsite group by uidRequisitionId) RW ON H1.uidRequisitionId = RW.uidRequisitionId	
	WHERE S1.uidId IN(SELECT uidId FROM #tmpUserRequisitionWorkflowSteps)
	UNION
	SELECT'1','Previously Advertised',AVG(ISNULL((CAST(CASE WHEN DATEDIFF(DAY,RW.dteEndDate,H2.dteLandingDate)<1 THEN 0 ELSE DATEDIFF(DAY,RW.dteEndDate,H2.dteLandingDate)END as float)),-0)),5
	FROM
		sequencedRequisitionHistory H1
	RIGHT JOIN
		refRequisitionWorkflowStep S1 ON H1.uidRequisitionWorkflowStepId = S1.uidId AND S1.uidId IN (SELECT uidId FROM #tmpUserRequisitionWorkflowSteps)
	LEFT JOIN
		(SELECT uidRequisitionId,uidRequisitionWorkflowStepId,intOrder,MIN(dteLandingDate) AS dteLandingDate FROM sequencedRequisitionHistory group by uidRequisitionId,uidRequisitionWorkflowStepId,intOrder) H2 ON H1.uidRequisitionId = H2.uidRequisitionId AND H1.intOrder = H2.intOrder-1
	LEFT OUTER JOIN (SELECT uidRequisitionId,MAX(dteEndDate) as dteEndDate from relRequisitionWebsite group by uidRequisitionId) RW ON H1.uidRequisitionId = RW.uidRequisitionId	
	WHERE S1.uidId IN (SELECT uidId FROM #tmpUserRequisitionWorkflowSteps)
) C ORDER BY C.intSortOrder
DROP TABLE #tmpUserRequisitionWorkflowSteps
DROP TABLE #tmpUserRequisitions
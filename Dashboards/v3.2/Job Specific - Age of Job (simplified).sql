-- Jobs - Age of Active Job (simplified).sql
-- Requirements
-- ============
-- Active = (Jobs where RWF step = Review and jobs where published = true)
-- Age = (Days spent in steps where published = true + days spent in RWF step = review)
-- Data context = user specific based on Job access level (AllRequisitions | AsssignedRequisitions)

SET NOCOUNT ON;

DECLARE @varLastPublishedDate datetime

-- REMOVE NEXT LINE BEFORE DEPLOYING TO SYSTEM
DECLARE @uidUserId uniqueidentifier = '0EDC2E28-002E-4F3F-BCC7-21B44A54692B' --GR
DECLARE @uidRequisitionId uniqueidentifier = 'E4EFE966-796F-4304-B09E-0039B7EC117E'
			

SELECT R.uidId AS uidRequisitionId, RW.dteStartDate, RW.dteEndDate, DATEDIFF(dd, RW.dteStartDate, RW.dteEndDate) AS intDays
INTO #tmpRequisitionAgeDays
FROM dtlRequisition R
JOIN relRequisitionWebsite RW ON R.uidId = RW.uidRequisitionId
WHERE R.uidId = @uidRequisitionId
AND dteStartDate IS NOT NULL

UPDATE #tmpRequisitionAgeDays
SET dteEndDate = GETDATE(),
intDays = DATEDIFF(dd, dteStartDate, GETDATE())
WHERE dteEndDate IS NULL

SELECT @varLastPublishedDate = (SELECT TOP 1 dteEndDate FROM #tmpRequisitionAgeDays ORDER BY dteEndDate DESC)

INSERT INTO #tmpRequisitionAgeDays (uidRequisitionId, dteStartDate, dteEndDate,  intDays)
SELECT uidRequisitionId, @varLastPublishedDate, dteLandingDate, 0 
FROM relRequisitionWorkflowHistory 
WHERE uidRequisitionId = @uidRequisitionId
AND uidRequisitionWorkflowStepId = '8C49E81E-B43B-4502-9921-F9EF8E84546A'

UPDATE #tmpRequisitionAgeDays
SET dteEndDate = GETDATE(),
intDays = DATEDIFF(dd, dteStartDate, GETDATE())
WHERE dteEndDate IS NULL


SELECT '#AGEJOB#' as tag, SUM(intDays) as value
FROM #tmpRequisitionAgeDays
GROUP BY uidRequisitionId 

DROP TABLE #tmpRequisitionAgeDays
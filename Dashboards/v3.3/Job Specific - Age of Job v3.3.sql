-- Job Specific - Age of Job.sql
-- Requirements
-- ============
-- Age = (Days spent in steps = active and where published or previously published)
-- Count is job specific


SET NOCOUNT ON;

DECLARE @uidRequisitionId uniqueidentifier = 'E4EFE966-796F-4304-B09E-0039B7EC117E'


CREATE TABLE #tmpRequisitionWorkflowstepDates   
(
	uidRequisitionId uniqueidentifier,
	nvcStatus nvarchar(50),
	dteStartDate datetime,
	dteEndDate datetime,
	intStepDays int
)

INSERT INTO #tmpRequisitionWorkflowstepDates (uidRequisitionId,	nvcStatus, dteStartDate, dteEndDate)
SELECT
RWH.uidRequisitionId,
RWS.nvcName,
RWH.dteLandingDate as dteStartDate,
(
	SELECT TOP 1 dteLandingDate 
	FROM relRequisitionWorkflowHistory 
	WHERE uidRequisitionId = RWH.uidRequisitionId 
	AND dteLandingDate > RWH.dteLandingDate 
	ORDER BY dteLandingDate
) AS dteEndDate
FROM relRequisitionWorkflowHistory RWH
JOIN refRequisitionWorkflowStep RWS ON RWH.uidRequisitionWorkflowStepId = RWS.uidId AND RWS.uidId = 'DD84363C-D03D-46F1-9DD9-633806951E06'
WHERE RWH.uidRequisitionId = @uidRequisitionId
AND RWH.uidRequisitionId IN 
(
	-- FILTER ONLY JOBS THAT ARE CURRENTLY PUBLISHED OR HAVE BEEN PREVIOUSLY PUBLISHED
	SELECT uidRequisitionId FROM relRequisitionWebsite WHERE dteStartDate <= GETDATE()
)
ORDER BY uidRequisitionId, dteLandingDate


UPDATE #tmpRequisitionWorkflowstepDates
SET intStepDays = DATEDIFF(dd, dteStartDate , dteEndDate)
WHERE dteEndDate IS NOT NULL

UPDATE #tmpRequisitionWorkflowstepDates
SET intStepDays = DATEDIFF(dd, dteStartDate , GETDATE())
WHERE dteEndDate IS NULL


SELECT '#AGEJOB#' as tag, SUM(intStepDays) AS value
FROM #tmpRequisitionWorkflowstepDates


DROP TABLE #tmpRequisitionWorkflowstepDates
-- Jobs - Age of Jobs vs Age of Active Jobs - Recruiter Manager.sql
-- WORK IN PROGRESS

CREATE TABLE #tmpRequisitionWorkflowstepDates   
(
	ID INT Identity(1,1),
	uidRequisitionId uniqueidentifier,
	nvcStatus nvarchar(50),
	dteLandingDate datetime,
	intStepDays int,
	nvcStepStatus nvarchar(50),
	bitLastStep bit,
	intLastStepDays int
)

INSERT INTO #tmpRequisitionWorkflowstepDates
(
	uidRequisitionId,
	nvcStatus,
	dteLandingDate
)
SELECT RWA.uidRequisitionId, RWS.nvcName AS Status, RWA.dteLandingDate AS LandingDate
FROM refRequisitionWorkflowStep RWS
JOIN relRequisitionWorkflowAction RWA
ON RWS.uidId = RWA.uidRequisitionWorkflowStepId
WHERE RWA.uidRequisitionId IN ('CCD3CB3C-99B1-4F8C-BD13-93AAC39B95B8')
--(
--	SELECT DISTINCT uidRequisitionId FROM relRequisitionWorkflowAction WHERE uidRequisitionWorkflowStepId IN
--	(
--		SELECT uidId FROM refRequisitionWorkflowStep WHERE bitPublished = 1
--	)
--)
ORDER by RWA.uidRequisitionId, RWA.dteLandingDate

DECLARE @intCount int, @intThisStep int
DECLARE @nvcLastStepStatus nvarchar(50)
DECLARE @dteLastStepDate datetime
DECLARE @uidThisRequisitionId uniqueidentifier, @uidPreviousRequisitionId uniqueidentifier, @uidNextRequisitionId uniqueidentifier

SET @intCount = 1

WHILE @intCount <= (SELECT COUNT(*) FROM #tmpRequisitionWorkflowstepDates)
BEGIN
	
	SELECT @uidThisRequisitionId = uidRequisitionId 
	FROM #tmpRequisitionWorkflowstepDates 
	WHERE ID = @intCount
	
	IF @uidThisRequisitionId <> @uidPreviousRequisitionId
	BEGIN 
		SET @intThisStep = 1
		SET @nvcLastStepStatus = NULL
	END
	
	IF @uidPreviousRequisitionId IS NULL
	BEGIN 
		SET @intThisStep = 1
		SET @nvcLastStepStatus = NULL
	END
	
	IF @intThisStep = 1
		BEGIN
			UPDATE #tmpRequisitionWorkflowstepDates
			SET intStepDays = 0
			WHERE ID = @intCount
		END
	ELSE
		BEGIN
			UPDATE #tmpRequisitionWorkflowstepDates
			SET intStepDays = DATEDIFF(dd,@dteLastStepDate,dteLandingDate),
			nvcStepStatus = @nvcLastStepStatus 
			WHERE ID = @intCount
		END;
	
	SELECT @uidNextRequisitionId = uidRequisitionId
	FROM #tmpRequisitionWorkflowstepDates
	WHERE ID = (@intCount + 1)
	
	IF @uidThisRequisitionId <> @uidNextRequisitionId
	BEGIN 
		UPDATE #tmpRequisitionWorkflowstepDates
		SET bitLastStep = 1
		WHERE ID = @intCount
	END
	
	SELECT @uidPreviousRequisitionId = uidRequisitionId,
	@dteLastStepDate = dteLandingDate,
	@nvcLastStepStatus = nvcStatus  
	FROM #tmpRequisitionWorkflowstepDates
	WHERE ID = @intCount
	
	SELECT @intThisStep = @intThisStep + 1
	
	SELECT @intCount = @intCount + 1
	
END

UPDATE #tmpRequisitionWorkflowstepDates
SET intLastStepDays = DATEDIFF(dd, dteLandingDate, GETDATE())
WHERE bitLastStep = 1

SELECT uidRequisitionId,
nvcStepStatus,
intStepDays 
INTO #tmpRequisitionWorkflowstepDatesTotals
FROM #tmpRequisitionWorkflowstepDates

INSERT INTO #tmpRequisitionWorkflowstepDatesTotals
(
	uidRequisitionId,
	nvcStepStatus,
	intStepDays
)
SELECT uidRequisitionId,
nvcStatus,
intLastStepDays
FROM #tmpRequisitionWorkflowstepDates
WHERE bitLastStep = 1


SELECT * FROM #tmpRequisitionWorkflowstepDates
SELECT * FROM #tmpRequisitionWorkflowstepDatesTotals


DROP TABLE #tmpRequisitionWorkflowstepDates
DROP TABLE #tmpRequisitionWorkflowstepDatesTotals

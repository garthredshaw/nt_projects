-- Job Specific - Age of Job.sql
-- Requirements
-- ============
-- Age = (Days spent in steps where published = true + days spent in RWF step = review)
-- Count is job specific


SET NOCOUNT ON;

DECLARE @uidRequisitionId uniqueidentifier = 'FF62E57E-0E43-4AA0-ABB2-1F7F88178928'

DECLARE @intCount int, @intThisStep int
DECLARE @nvcLastStepStatus nvarchar(50)
DECLARE @dteLastStepDate datetime
DECLARE @uidThisRequisitionId uniqueidentifier, @uidPreviousRequisitionId uniqueidentifier, @uidNextRequisitionId uniqueidentifier

SELECT uidId AS 'uidRequisitionId',
NULL AS 'intDaysAdvertised',
NULL AS 'intDaysReview',
NULL AS 'intDaysActive'
INTO #tmpUserRequisitions
FROM dtlRequisition
WHERE uidId = @uidRequisitionId



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
SELECT BB.uidRequisitionId, AA.nvcName AS Status, BB.dteLandingDate AS LandingDate
FROM refRequisitionWorkflowStep AA
JOIN relRequisitionWorkflowAction BB
ON AA.uidId = BB.uidRequisitionWorkflowStepId
WHERE BB.uidRequisitionId IN
(
	SELECT uidRequisitionId 
	FROM #tmpUserRequisitions
)
ORDER by BB.uidRequisitionId, BB.dteLandingDate

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

UPDATE #tmpUserRequisitions
SET intDaysAdvertised = B.DaysAdvertised
FROM #tmpUserRequisitions A
LEFT JOIN 
(
	SELECT uidRequisitionId,
	nvcStepStatus,
	SUM(intStepDays) AS DaysAdvertised
	FROM #tmpRequisitionWorkflowstepDatesTotals
	WHERE nvcStepStatus = 'Sourcing'
	GROUP BY uidRequisitionId, nvcStepStatus
) B
ON A.uidRequisitionId = B.uidRequisitionId 

UPDATE #tmpUserRequisitions
SET intDaysReview = B.DaysReview
FROM #tmpUserRequisitions A
LEFT JOIN 
(
	SELECT uidRequisitionId,
	nvcStepStatus,
	SUM(intStepDays) AS DaysReview
	FROM #tmpRequisitionWorkflowstepDatesTotals
	WHERE nvcStepStatus = 'Review'
	GROUP BY uidRequisitionId, nvcStepStatus
) B
ON A.uidRequisitionId = B.uidRequisitionId 

UPDATE #tmpUserRequisitions
SET intDaysActive = intDaysAdvertised + intDaysReview

SELECT intDaysActive AS 'Age (Days)' FROM #tmpUserRequisitions


DROP TABLE #tmpUserRequisitions
DROP TABLE #tmpRequisitionWorkflowstepDates
DROP TABLE #tmpRequisitionWorkflowstepDatesTotals
SET NOCOUNT ON

SELECT REQ1.uidId AS 'uidRequisitionId',
REQ1.nvcReferenceCode AS 'JobRefNo', 
RWS1.nvcName AS 'JobStatus',
(
	SELECT TOP 1 R1.nvcFirstname + ' ' + R1.nvcLastname AS 'Creator'
	FROM dtlRecruiter R1
	JOIN relRecruiterRequisition RR1
	ON R1.uidId = RR1.uidRecruiterId 
	WHERE RR1.enmRecruiterRequisitionType = 1
	AND RR1.uidRequisitionId = REQ1.uidId
) AS 'JobCreator',
(
	SELECT TOP 1 R2.nvcFirstname + ' ' + R2.nvcLastname AS 'Owner'
	FROM dtlRecruiter R2
	JOIN relRecruiterRequisition RR2
	ON R2.uidId = RR2.uidRecruiterId 
	WHERE RR2.enmRecruiterRequisitionType = 2
	AND RR2.uidRequisitionId = REQ1.uidId
) AS 'JobOwner',
REQ1.dteCreationDate AS 'DateJobCreated',
(
	SELECT MIN(RWA2.dteLandingDate) 
	FROM refRequisitionWorkflowStep RWS2
	JOIN relRequisitionWorkflowAction RWA2
	ON RWS2.uidId = RWA2.uidRequisitionWorkflowStepId
	WHERE RWS2.bitPublished = 1
	AND RWA2.uidRequisitionId = REQ1.uidId
) AS 'DateJobFirstAdvertised',
0 AS 'DaysJobAdvertised',
0 AS 'DaysInReview',
0 AS 'TotalJobTAT',
(
	SELECT MIN(RWA4.dteLandingDate) 
	FROM refRequisitionWorkflowStep RWS4
	JOIN relRequisitionWorkflowAction RWA4
	ON RWS4.uidId = RWA4.uidRequisitionWorkflowStepId
	WHERE RWS4.uidId IN 
	(
		SELECT uidId FROM refRequisitionWorkflowStep WHERE nvcName = 'Review'
	)
	AND RWA4.uidRequisitionId = REQ1.uidId
) AS 'DateJobFirstReview',
(
	SELECT MIN(RWA3.dteLandingDate) 
	FROM refRequisitionWorkflowStep RWS3
	JOIN relRequisitionWorkflowAction RWA3
	ON RWS3.uidId = RWA3.uidRequisitionWorkflowStepId
	WHERE RWS3.uidId IN 
	(
		SELECT uidId FROM refRequisitionWorkflowStep WHERE nvcName = 'Archived'
	)
	AND RWA3.uidRequisitionId = REQ1.uidId
) AS 'DateJobArchived',
(
	SELECT COUNT(uidId) 
	FROM relApplication
	WHERE relApplication.uidRequisitionId = REQ1.uidId
) AS 'TotalApplications',
(
	SELECT COUNT(DISTINCT uidApplicationId)
	FROM relApplicationWorkflowHistory AWH
	JOIN relApplication APP
	ON APP.uidId = AWH.uidApplicationId
	WHERE AWH.uidApplicationWorkflowStepId IN 
	(
		SELECT uidId FROM refApplicationWorkflowStep WHERE nvcName = 'Unprocessed'
	)
	AND APP.uidRequisitionId = REQ1.uidId
	AND AWH.dteLandingDate >=
	(
		SELECT MAX(dteLandingDate) 
		FROM relApplicationWorkflowHistory 
		WHERE uidApplicationWorkflowStepId IN 
		(
			SELECT uidId FROM refApplicationWorkflowStep WHERE nvcName = 'Unprocessed'
		)
		AND uidApplicationId = AWH.uidApplicationId
	)	
) AS 'WFS_Unprocessed',
(
	SELECT COUNT(DISTINCT uidApplicationId)
	FROM relApplicationWorkflowHistory AWH
	JOIN relApplication APP
	ON APP.uidId = AWH.uidApplicationId
	WHERE AWH.uidApplicationWorkflowStepId IN 
	(
		SELECT uidId FROM refApplicationWorkflowStep WHERE nvcName = 'Longlist'
	)
	AND APP.uidRequisitionId = REQ1.uidId
	AND AWH.dteLandingDate >=
	(
		SELECT MAX(dteLandingDate) 
		FROM relApplicationWorkflowHistory 
		WHERE uidApplicationWorkflowStepId IN 
		(
			SELECT uidId FROM refApplicationWorkflowStep WHERE nvcName = 'Unprocessed'
		)
		AND uidApplicationId = AWH.uidApplicationId
	)
) AS 'WFS_Longlist',
(
	SELECT COUNT(DISTINCT uidApplicationId)
	FROM relApplicationWorkflowHistory AWH
	JOIN relApplication APP
	ON APP.uidId = AWH.uidApplicationId
	WHERE AWH.uidApplicationWorkflowStepId IN 
	(
		SELECT uidId FROM refApplicationWorkflowStep WHERE nvcName = 'Shortlist'
	)
	AND APP.uidRequisitionId = REQ1.uidId
	AND AWH.dteLandingDate >=
	(
		SELECT MAX(dteLandingDate) 
		FROM relApplicationWorkflowHistory 
		WHERE uidApplicationWorkflowStepId IN 
		(
			SELECT uidId FROM refApplicationWorkflowStep WHERE nvcName = 'Unprocessed'
		)
		AND uidApplicationId = AWH.uidApplicationId
	)
) AS 'WFS_Shortlist',
(
	SELECT COUNT(DISTINCT uidApplicationId)
	FROM relApplicationWorkflowHistory AWH
	JOIN relApplication APP
	ON APP.uidId = AWH.uidApplicationId
	WHERE AWH.uidApplicationWorkflowStepId IN 
	(
		SELECT uidId FROM refApplicationWorkflowStep WHERE nvcName = 'Interview'
	)
	AND APP.uidRequisitionId = REQ1.uidId
	AND AWH.dteLandingDate >=
	(
		SELECT MAX(dteLandingDate) 
		FROM relApplicationWorkflowHistory 
		WHERE uidApplicationWorkflowStepId IN 
		(
			SELECT uidId FROM refApplicationWorkflowStep WHERE nvcName = 'Unprocessed'
		)
		AND uidApplicationId = AWH.uidApplicationId
	)
) AS 'WFS_Interview',
(
	SELECT COUNT(DISTINCT uidApplicationId)
	FROM relApplicationWorkflowHistory AWH
	JOIN relApplication APP
	ON APP.uidId = AWH.uidApplicationId
	WHERE AWH.uidApplicationWorkflowStepId IN 
	(
		SELECT uidId FROM refApplicationWorkflowStep WHERE nvcName = 'Under Review'
	)
	AND APP.uidRequisitionId = REQ1.uidId
	AND AWH.dteLandingDate >=
	(
		SELECT MAX(dteLandingDate) 
		FROM relApplicationWorkflowHistory 
		WHERE uidApplicationWorkflowStepId IN 
		(
			SELECT uidId FROM refApplicationWorkflowStep WHERE nvcName = 'Unprocessed'
		)
		AND uidApplicationId = AWH.uidApplicationId
	)
) AS 'WFS_UnderReview',
(
	SELECT COUNT(DISTINCT uidApplicationId)
	FROM relApplicationWorkflowHistory AWH
	JOIN relApplication APP
	ON APP.uidId = AWH.uidApplicationId
	WHERE AWH.uidApplicationWorkflowStepId IN 
	(
		SELECT uidId FROM refApplicationWorkflowStep WHERE nvcName = 'Offer Made'
	)
	AND APP.uidRequisitionId = REQ1.uidId
	AND AWH.dteLandingDate >=
	(
		SELECT MAX(dteLandingDate) 
		FROM relApplicationWorkflowHistory 
		WHERE uidApplicationWorkflowStepId IN 
		(
			SELECT uidId FROM refApplicationWorkflowStep WHERE nvcName = 'Unprocessed'
		)
		AND uidApplicationId = AWH.uidApplicationId
	)
) AS 'WFS_OfferMade',
(
	SELECT COUNT(DISTINCT uidApplicationId)
	FROM relApplicationWorkflowHistory AWH
	JOIN relApplication APP
	ON APP.uidId = AWH.uidApplicationId
	WHERE AWH.uidApplicationWorkflowStepId IN 
	(
		SELECT uidId FROM refApplicationWorkflowStep WHERE nvcName = 'Hired'
	)
	AND APP.uidRequisitionId = REQ1.uidId
	AND AWH.dteLandingDate >=
	(
		SELECT MAX(dteLandingDate) 
		FROM relApplicationWorkflowHistory 
		WHERE uidApplicationWorkflowStepId IN 
		(
			SELECT uidId FROM refApplicationWorkflowStep WHERE nvcName = 'Unprocessed'
		)
		AND uidApplicationId = AWH.uidApplicationId
	)
) AS 'WFS_Hired',
(
	SELECT COUNT(DISTINCT uidApplicationId)
	FROM relApplicationWorkflowHistory AWH
	JOIN relApplication APP
	ON APP.uidId = AWH.uidApplicationId
	WHERE AWH.uidApplicationWorkflowStepId IN 
	(
		SELECT uidId FROM refApplicationWorkflowStep WHERE nvcName = 'Regretted'
	)
	AND APP.uidRequisitionId = REQ1.uidId
	AND AWH.dteLandingDate >=
	(
		SELECT MAX(dteLandingDate) 
		FROM relApplicationWorkflowHistory 
		WHERE uidApplicationWorkflowStepId IN 
		(
			SELECT uidId FROM refApplicationWorkflowStep WHERE nvcName = 'Unprocessed'
		)
		AND uidApplicationId = AWH.uidApplicationId
	)
) AS 'WFS_Regretted',
(
	SELECT COUNT(DISTINCT uidApplicationId)
	FROM relApplicationWorkflowHistory AWH
	JOIN relApplication APP
	ON APP.uidId = AWH.uidApplicationId
	WHERE AWH.uidApplicationWorkflowStepId IN 
	(
		SELECT uidId FROM refApplicationWorkflowStep WHERE nvcName = 'Declined'
	)
	AND APP.uidRequisitionId = REQ1.uidId
	AND AWH.dteLandingDate >=
	(
		SELECT MAX(dteLandingDate) 
		FROM relApplicationWorkflowHistory 
		WHERE uidApplicationWorkflowStepId IN 
		(
			SELECT uidId FROM refApplicationWorkflowStep WHERE nvcName = 'Unprocessed'
		)
		AND uidApplicationId = AWH.uidApplicationId
	)
) AS 'WFS_Declined',
(
	SELECT COUNT(DISTINCT uidApplicationId)
	FROM relApplicationWorkflowHistory AWH
	JOIN relApplication APP
	ON APP.uidId = AWH.uidApplicationId
	WHERE AWH.uidApplicationWorkflowStepId IN 
	(
		SELECT uidId FROM refApplicationWorkflowStep WHERE nvcName = 'Withdrawn'
	)
	AND APP.uidRequisitionId = REQ1.uidId
	AND AWH.dteLandingDate >=
	(
		SELECT MAX(dteLandingDate) 
		FROM relApplicationWorkflowHistory 
		WHERE uidApplicationWorkflowStepId IN 
		(
			SELECT uidId FROM refApplicationWorkflowStep WHERE nvcName = 'Unprocessed'
		)
		AND uidApplicationId = AWH.uidApplicationId
	)
) AS 'WFS_Withdrawn'
INTO #tmpJobReportSnapshot1
FROM dtlRequisition REQ1
JOIN refRequisitionWorkflowStep RWS1
ON RWS1.uidId = REQ1.uidRequisitionWorkflowStepId
WHERE REQ1.uidRequisitionWorkflowStepId IN 
(
	SELECT uidId FROM refRequisitionWorkflowStep WHERE nvcName = 'Archived'
)

DELETE FROM #tmpJobReportSnapshot1
WHERE uidRequisitionId NOT IN 
(
	SELECT uidRequisitionId FROM #tmpJobReportSnapshot1
	WHERE DATEPART(mm, DateJobArchived) = DATEPART(mm, DATEADD(mm, -1, GETDATE()))
	AND DATEPART(yyyy, DateJobArchived) = DATEPART(yyyy, DATEADD(mm, -1, GETDATE()))
)

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
	FROM #tmpJobReportSnapshot1
)
ORDER by BB.uidRequisitionId, BB.dteLandingDate

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

CREATE TABLE #tmpTemplateFields   
(
	ID INT Identity(1,1),
	FName VARCHAR(MAX),
	FieldId uniqueidentifier,
	SectionId uniqueidentifier,
	SortOrder int,
	DataType int
) 

INSERT INTO #tmpTemplateFields
(
	FName,
	FieldId,
	SortOrder,
	DataType
)
SELECT RF.nvcName, RF.uidId, RF.intSortOrder, RF.enmDataType 
FROM refRequisitionField RF
JOIN relRequisitionTemplateField RTF
ON RF.uidId = RTF.uidRequisitionFieldId
JOIN relRequisitionTemplateSection RTS
ON RTF.uidRequisitionTemplateSectionId = RTS.uidId 
AND RTS.uidRequisitionTemplateId = 
(
	SELECT uidId FROM refRequisitionTemplate WHERE nvcName = 'Requisition Report Fields'
)
ORDER BY RF.intSortOrder 

WHILE (SELECT MAX(PATINDEX('%[^a-zA-Z0-9]%', FName)) FROM #tmpTemplateFields) > 0
BEGIN

	UPDATE #tmpTemplateFields 
	SET FName = REPLACE(FName, SUBSTRING(FName, PATINDEX('%[^a-zA-Z0-9]%', FName), 1), '')
	
	
	IF (SELECT MAX(PATINDEX('%[^a-zA-Z0-9]%', FName)) FROM #tmpTemplateFields) = 0
		BREAK
	ELSE
		CONTINUE
END

DECLARE @nvcFieldName nvarchar(50), @nvcParameterDefinition nvarchar(4000), @nvcSql nvarchar(4000)
DECLARE @uidFieldId uniqueidentifier
DECLARE @enmDataType int

SET @intCount = 1

SELECT @nvcParameterDefinition = '
		@uidFIDParam uniqueidentifier,
		@intFieldNumberParam int'


CREATE TABLE #tmpTFDupValues
(
	ID INT Identity(1,1),
	FN int,
	RelId uniqueidentifier, 
	Value nvarchar(MAX)
)

WHILE @intCount <= (SELECT COUNT(*) FROM #tmpTemplateFields)
BEGIN
	SELECT @nvcFieldName = RTF.FName,
	@enmDataType = RTF.DataType,
	@uidFieldId = RTF.FieldId 
    FROM #tmpTemplateFields RTF
    WHERE RTF.ID = @intCount   
	
	IF @enmDataType = 0
	BEGIN
		SELECT @nvcSql = 'INSERT INTO #tmpTFDupValues
		(FN, RelId, Value)
		
		SELECT @intFieldNumberParam, RSV.uidRequisitionId, RFV.nvcStringValue
		FROM relRequisitionFieldValue RFV
		JOIN relRequisitionSectionValue RSV
		ON RSV.uidId = RFV.uidRequisitionSectionValueId
		AND RSV.uidRequisitionId IN(SELECT uidRequisitionId FROM #tmpJobReportSnapshot1)		
		WHERE RFV.uidRequisitionFieldId = @uidFIDParam'
	END
	
	IF @enmDataType = 1
	BEGIN
		SELECT @nvcSql = 'INSERT INTO #tmpTFDupValues
		(FN, RelId, Value)
		
		SELECT @intFieldNumberParam, RSV.uidRequisitionId, CAST(RFV.nvcStringValue as nvarchar(max))
		FROM relRequisitionFieldValue RFV
		JOIN relRequisitionSectionValue RSV
		ON RSV.uidId = RFV.uidRequisitionSectionValueId
		AND RSV.uidRequisitionId IN(SELECT uidRequisitionId FROM #tmpJobReportSnapshot1)
		WHERE RFV.uidRequisitionFieldId = @uidFIDParam'			
	END
	
	IF @enmDataType = 2
	BEGIN
		SELECT @nvcSql = 'INSERT INTO #tmpTFDupValues
		(FN, RelId, Value)
		
		SELECT @intFieldNumberParam, RSV.uidRequisitionId, CAST(RFV.intIntValue as nvarchar(max))
		FROM relRequisitionFieldValue RFV
		JOIN relRequisitionSectionValue RSV		
		ON RSV.uidId = RFV.uidRequisitionSectionValueId
		AND RSV.uidRequisitionId IN(SELECT uidRequisitionId FROM #tmpJobReportSnapshot1)
		WHERE RFV.uidRequisitionFieldId = @uidFIDParam'		
	END
	
	IF @enmDataType = 3
	BEGIN
		SELECT @nvcSql = 'INSERT INTO #tmpTFDupValues
		(FN, RelId, Value)
		
		SELECT @intFieldNumberParam, RSV.uidRequisitionId, CAST(RFV.fltFloatValue as nvarchar(max)) 
		FROM relRequisitionFieldValue RFV
		JOIN relRequisitionSectionValue RSV
		ON RSV.uidId = RFV.uidRequisitionSectionValueId
		AND RSV.uidRequisitionId IN(SELECT uidRequisitionId FROM #tmpJobReportSnapshot1)
		WHERE RFV.uidRequisitionFieldId = @uidFIDParam'				
	END
	
	IF @enmDataType = 4
	BEGIN
		SELECT @nvcSql = 'INSERT INTO #tmpTFDupValues
		(FN, RelId, Value)
		
		SELECT @intFieldNumberParam, RSV.uidRequisitionId, CAST(RFV.bitBitValue as nvarchar(max))
		FROM relRequisitionFieldValue RFV
		JOIN relRequisitionSectionValue RSV		
		ON RSV.uidId = RFV.uidRequisitionSectionValueId
		AND RSV.uidRequisitionId IN(SELECT uidRequisitionId FROM #tmpJobReportSnapshot1)
		WHERE RFV.uidRequisitionFieldId = @uidFIDParam'
	END
	
	IF @enmDataType = 5
	BEGIN
		SELECT @nvcSql = 'INSERT INTO #tmpTFDupValues
		(FN, RelId, Value)
		
		SELECT @intFieldNumberParam, RSV.uidRequisitionId, CONVERT(nvarchar(max), RFV.dteDateValue, 126)
		FROM relRequisitionFieldValue RFV
		JOIN relRequisitionSectionValue RSV		
		ON RSV.uidId = RFV.uidRequisitionSectionValueId
		AND RSV.uidRequisitionId IN(SELECT uidRequisitionId FROM #tmpJobReportSnapshot1)
		WHERE RFV.uidRequisitionFieldId = @uidFIDParam'
	END
	
	IF @enmDataType = 6
	BEGIN
		SELECT @nvcSql = 'INSERT INTO #tmpTFDupValues
		(FN, RelId, Value)
		
		SELECT @intFieldNumberParam, RSV.uidRequisitionId, RDI.nvcName 
		FROM relRequisitionFieldValue RFV
		JOIN relRequisitionSectionValue RSV
		ON RSV.uidId = RFV.uidRequisitionSectionValueId
		AND RSV.uidRequisitionId IN(SELECT uidRequisitionId FROM #tmpJobReportSnapshot1)
		JOIN refReferenceDataItem RDI
		ON RFV.uidIdValue = RDI.uidId 
		WHERE RFV.uidRequisitionFieldId = @uidFIDParam'					
	END
		
	EXEC sp_executeSql @nvcSql,
	@nvcParameterDefinition,
	@uidFIDParam = @uidFieldId,
	@intFieldNumberParam = @intCount
		
	SELECT @intCount = @intCount + 1
	
END

CREATE TABLE #tmpTFValues
(
	FN int,
	RelId uniqueidentifier, 
	Value nvarchar(MAX)
)

INSERT INTO #tmpTFValues (FN, RelId, Value)
SELECT FN, RelId, Value 
FROM #tmpTFDupValues
WHERE ID IN
(
	SELECT MIN(ID)
	FROM #tmpTFDupValues
	GROUP BY FN, RelId 
	HAVING COUNT(*) > 1
)
UNION
SELECT FN, RelId, Value 
FROM #tmpTFDupValues
WHERE ID IN
(
	SELECT MIN(ID)
	FROM #tmpTFDupValues
	GROUP BY FN, RelId 
	HAVING COUNT(*) < 2
)

CREATE TABLE #tmpRR_Result (uidRequisitionId uniqueidentifier)

SELECT @nvcSql = 'ALTER TABLE #tmpRR_Result ADD '
SELECT @nvcSql = @nvcSql + REPLACE(FName, ' ', '')
+ ' NVARCHAR(MAX) NULL, ' FROM (SELECT FName FROM #tmpTemplateFields) As #tmpDistinctCandidateFields1

SELECT @nvcSql = LEFT(@nvcSql, LEN(@nvcSql)-1)

EXEC sp_executeSql @nvcSql

SET @intCount = 1

IF (SELECT COUNT(*) FROM #tmpTFValues) > 0
BEGIN
	SELECT @nvcSql = 'INSERT INTO #tmpRR_Result
	SELECT R.uidID, '

	WHILE @intCount <= (SELECT COUNT(*) FROM #tmpTemplateFields)
	BEGIN
		SELECT @nvcSql = @nvcSql + ' 
		RTFV'+ CAST(@intCount as nvarchar) + '.Value AS V_' + CAST(@intCount as nvarchar) + ','
		
		SELECT @intCount = @intCount + 1
		
	END

	SET @intCount = 1

	SELECT @nvcSql = LEFT(@nvcSql, LEN(@nvcSql)-1) + ' 
	FROM dtlRequisition R
	LEFT JOIN #tmpTFValues RTFV' + CAST(@intCount as nvarchar) + ' ON R.uidId = RTFV' + CAST(@intCount as nvarchar) + '.RelId AND RTFV' + CAST(@intCount as nvarchar) + '.FN = ' + CAST(@intCount as nvarchar)

	SELECT @intCount = @intCount + 1

	WHILE @intCount <= (SELECT COUNT(*) FROM #tmpTemplateFields)
	BEGIN
		SELECT @nvcSql = @nvcSql + ' 
		LEFT JOIN #tmpTFValues RTFV' + CAST(@intCount as nvarchar) + ' ON R.uidId = RTFV' + CAST(@intCount as nvarchar) + '.RelId AND RTFV' + CAST(@intCount as nvarchar) + '.FN = ' + CAST(@intCount as nvarchar)

		SELECT @intCount = @intCount + 1
		
	END

	SELECT @nvcSql = @nvcSql + ' WHERE R.uidId IN(SELECT uidRequisitionId FROM #tmpJobReportSnapshot1)'

	EXEC sp_executeSql @nvcSql
END

UPDATE #tmpJobReportSnapshot1
SET DaysJobAdvertised = ISNULL(B.DaysAdvertised, 0)
FROM #tmpJobReportSnapshot1 A
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

UPDATE #tmpJobReportSnapshot1
SET DaysInReview = ISNULL(B.DaysReview, 0)
FROM #tmpJobReportSnapshot1 A
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

UPDATE #tmpJobReportSnapshot1
SET TotalJobTAT = ISNULL(DATEDIFF(day,DateJobCreated,DateJobArchived), 0)

SELECT JRS1.JobRefNo AS 'Job Reference Number',
JRS1.JobStatus AS 'Job Status',
JRS1.JobCreator AS 'Job Creator',
JRS1.JobOwner AS 'Job Owner',
JRS1.DateJobCreated AS 'Date Job Created',
JRS1.DateJobFirstAdvertised AS 'Date Job First Advertised',
JRS1.DaysJobAdvertised AS 'Days Job Advertised',
JRS1.DaysInReview AS 'Days Job in Review',
'Days Job Active' = ISNULL(JRS1.DaysJobAdvertised,0) + ISNULL(JRS1.DaysInReview,0),
JRS1.DateJobArchived AS 'Date Job Archived',
JRS1.TotalJobTAT AS 'Total Job TAT in Days',
JRS1.TotalApplications AS 'Total Applications',
JRS1.WFS_Unprocessed AS 'Count Unprocessed',
JRS1.WFS_LongList AS 'Count Longlist',
JRS1.WFS_ShortList AS 'Count Shortlist',
JRS1.WFS_Interview AS 'Count Interview',
JRS1.WFS_UnderReview AS 'Count Under Review',
JRS1.WFS_OfferMade AS 'Count Offer MAde',
JRS1.WFS_Hired AS 'Count Hired',
JRS1.WFS_Regretted AS 'Count Regretted',
JRS1.WFS_Declined AS 'Count Declined',
JRS1.WFS_Withdrawn AS 'Count Withdrawn',
RRR.*
FROM #tmpJobReportSnapshot1 JRS1
JOIN #tmpRR_Result RRR
ON JRS1.uidRequisitionId = RRR.uidRequisitionId


DROP TABLE #tmpJobReportSnapshot1
DROP TABLE #tmpRequisitionWorkflowstepDates
DROP TABLE #tmpRequisitionWorkflowstepDatesTotals
DROP TABLE #tmpTemplateFields
DROP TABLE #tmpTFDupValues
DROP TABLE #tmpTFValues
DROP TABLE #tmpRR_Result
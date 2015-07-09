-- Active Jobs Application History
-- 20150707
-- Jobs 'Active' and 'Published'

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
	SELECT TOP 1 dteStartDate 
	FROM relRequisitionWebsite 
	WHERE uidRequisitionId = REQ1.uidId 
	ORDER BY dteStartDate
) AS 'DateJobFirstAdvertised',
0 AS 'DaysJobAdvertised',
0 AS 'DaysActive',
0 AS 'TotalJobTAT',
(
	SELECT MIN(RWA4.dteLandingDate) 
	FROM refRequisitionWorkflowStep RWS4
	JOIN relRequisitionWorkflowHistory RWA4
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
	JOIN relRequisitionWorkflowHistory RWA3
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
) AS 'WFS_Withdrawn',
'some very long string to take up space' AS nvcPublishingStatus
INTO #tmpJobReportSnapshot1
FROM dtlRequisition REQ1
JOIN refRequisitionWorkflowStep RWS1
ON RWS1.uidId = REQ1.uidRequisitionWorkflowStepId
WHERE RWS1.uidId IN 
(
	SELECT uidId FROM refRequisitionWorkflowStep WHERE nvcName = 'Active'
)
AND REQ1.uidId IN 
(
	SELECT uidRequisitionId FROM relRequisitionWebsite WHERE dteStartDate <= GETDATE()
)

-- START REQUISITION PUBLISHING DAYS CALCULATIONS
DECLARE @tmpRequisitionPublishedDaysCount TABLE
(
intRowCount int,
uidRequisitionId uniqueidentifier,
intDaysPublished int,
nvcPublishingStatus nvarchar(max)
)

DECLARE @tmpRequisisitionPublishedDates TABLE
(
	dteDate datetime,
	intPublished int
)

DECLARE @tmpPublishedDatesBeginEnd TABLE
(
dteStartDate datetime,
dteEndDate datetime
)

INSERT INTO @tmpRequisitionPublishedDaysCount(intRowCount, uidRequisitionId)
SELECT ROW_NUMBER() OVER(ORDER BY dteCreationDate DESC) AS Row, uidId FROM dtlRequisition WHERE uidId IN (SELECT uidRequisitionId FROM #tmpJobReportSnapshot1)
 
DECLARE @uidRequisitionId uniqueidentifier
DECLARE @dteLastPublishDate datetime
DECLARE @dteDatePosition datetime
DECLARE @intIsPublished int
DECLARE @DaysPublished int
DECLARE @RowCount int
DECLARE @i int

SET @RowCount = (SELECT COUNT(uidRequisitionId) FROM @tmpRequisitionPublishedDaysCount) 

SET @i = 1

WHILE (@i <= @RowCount)
BEGIN
	SELECT @uidRequisitionId = uidRequisitionId FROM @tmpRequisitionPublishedDaysCount WHERE intRowCount = @i
	INSERT INTO @tmpPublishedDatesBeginEnd (dteStartDate, dteEndDate)
	SELECT dteStartDate, ISNULL(dteEndDate,GETDATE()) FROM relRequisitionWebsite where uidRequisitionId = @uidRequisitionId
	
	SELECT @dteLastPublishDate = MAX(dteEndDate) FROM @tmpPublishedDatesBeginEnd
	
	IF @dteLastPublishDate > GETDATE()
	BEGIN
		SET @dteLastPublishDate = GETDATE()
	END
	
	SELECT @dteDatePosition = MIN(dteStartDate) FROM relRequisitionWebsite WHERE uidRequisitionId = @uidRequisitionId
	
	WHILE @dteDatePosition <= @dteLastPublishDate
	BEGIN	
		SELECT @intIsPublished = 0
		SELECT @intIsPublished = COUNT(*) FROM relRequisitionWebsite 
		WHERE uidRequisitionId = @uidRequisitionId
		AND (dteStartDate <= @dteDatePosition AND ISNULL(dteEndDate,GETDATE()) >= @dteDatePosition)
		
		IF @intIsPublished > 1
		BEGIN
			SELECT @intIsPublished = 1
		END
		INSERT INTO @tmpRequisisitionPublishedDates (dteDate,intPublished) VALUES (@dteDatePosition, @intIsPublished)
		SELECT @dteDatePosition = DATEADD(dd, 1, @dteDatePosition)
	END
	
	SELECT @DaysPublished = SUM(intPublished) FROM @tmpRequisisitionPublishedDates
	
	UPDATE @tmpRequisitionPublishedDaysCount
	SET intDaysPublished = @DaysPublished
	WHERE intRowCount = @i
	
	DELETE FROM @tmpRequisisitionPublishedDates
	DELETE FROM @tmpPublishedDatesBeginEnd
	
SET @i = @i + 1
END
-- END REQUISITION PUBLISHING DAYS CALCULATIONS

UPDATE @tmpRequisitionPublishedDaysCount
SET nvcPublishingStatus = 'Currently Advertised'
WHERE uidRequisitionId IN 
(
	SELECT DISTINCT uidRequisitionId FROM relRequisitionWebsite WHERE (dteStartDate <= GETDATE() AND ISNULL(dteEndDate, GETDATE()) >= GETDATE())
)

UPDATE @tmpRequisitionPublishedDaysCount
SET nvcPublishingStatus = 'Previously Advertised'
WHERE nvcPublishingStatus IS NULL


DECLARE @tmpRequisitionWorkflowstepDays TABLE
(
	ID INT Identity(1,1),
	uidRequisitionId uniqueidentifier,
	nvcStepStatus nvarchar(50),
	dteStartDate datetime,
	dteEndDate datetime,
	intStepDays int
)

INSERT INTO @tmpRequisitionWorkflowstepDays
(
	uidRequisitionId,
	nvcStepStatus,
	dteStartDate,
	dteEndDate
)
select
RWH.uidRequisitionId,
RWS.nvcName,
RWH.dteLandingDate as dteStartDate,
(
	isnull((select top 1 dteLandingDate 
	from relRequisitionWorkflowHistory 
	where uidRequisitionId = RWH.uidRequisitionId 
	and dteLandingDate > RWH.dteLandingDate 
	order by dteLandingDate),getdate())
) as dteEndDate
from relRequisitionWorkflowHistory RWH
join refRequisitionWorkflowStep RWS on RWH.uidRequisitionWorkflowStepId = RWS.uidId
WHERE RWH.uidRequisitionId IN
(
	SELECT uidRequisitionId 
	FROM #tmpJobReportSnapshot1
)
AND RWS.nvcName IN 
(
	'Review',
	'Sourcing',
	'Active'
)
order by uidRequisitionId, dteLandingDate

DECLARE @tmpRequisitionWorkflowstepDaysTotals TABLE
(	
	uidRequisitionId uniqueidentifier,
	intStepDays int
)

INSERT INTO @tmpRequisitionWorkflowstepDaysTotals (uidRequisitionId, intStepDays)
SELECT uidRequisitionId, DATEDIFF(dd, MIN(dteStartDate), MAX(dteEndDate)) + 1
FROM @tmpRequisitionWorkflowstepDays GROUP BY uidRequisitionId 


DECLARE @intCount int 

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
SET DaysJobAdvertised = ISNULL((SELECT intDaysPublished FROM @tmpRequisitionPublishedDaysCount WHERE uidRequisitionId = #tmpJobReportSnapshot1.uidRequisitionId), 0)

UPDATE #tmpJobReportSnapshot1
SET TotalJobTAT = ISNULL(DATEDIFF(day,DateJobFirstAdvertised,DateJobArchived), 0)

UPDATE #tmpJobReportSnapshot1
SET DaysActive = (SELECT intStepDays FROM @tmpRequisitionWorkflowstepDaysTotals WHERE uidRequisitionId = #tmpJobReportSnapshot1.uidRequisitionId)

UPDATE #tmpJobReportSnapshot1
SET nvcPublishingStatus = (SELECT nvcPublishingStatus FROM @tmpRequisitionPublishedDaysCount WHERE uidRequisitionId = #tmpJobReportSnapshot1.uidRequisitionId)

SELECT JRS1.JobRefNo AS 'Job Reference Number',
JRS1.JobStatus AS 'Job Status',
JRS1.JobCreator AS 'Job Creator',
JRS1.JobOwner AS 'Job Owner',
CONVERT(varchar, JRS1.DateJobCreated, 106) AS 'Date Job Created',
CONVERT(varchar, JRS1.DateJobFirstAdvertised, 106) AS 'Date Job First Advertised',
JRS1.DaysJobAdvertised AS 'Days Job Advertised',
JRS1.nvcPublishingStatus AS 'Publishing Status',
JRS1.DaysActive AS 'Days Job Active',
CONVERT(varchar, JRS1.DateJobArchived, 106) AS 'Date Job Archived',
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
JOIN #tmpRR_Result RRR ON JRS1.uidRequisitionId = RRR.uidRequisitionId

DROP TABLE #tmpJobReportSnapshot1
DROP TABLE #tmpTemplateFields
DROP TABLE #tmpTFDupValues
DROP TABLE #tmpTFValues
DROP TABLE #tmpRR_Result
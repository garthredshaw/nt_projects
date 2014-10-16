SET NOCOUNT ON
SET DATEFORMAT DMY

SELECT RWA.uidRequisitionId
INTO #tmpRequisitionFilter
FROM relRequisitionWorkflowAction RWA
JOIN refRequisitionWorkflowStep RWS
ON RWA.uidRequisitionWorkflowStepId = RWS.uidId AND RWS.bitPublished = 1
WHERE CAST(FLOOR(CAST(RWA.dteLandingDate AS FLOAT))AS DATETIME) >= '@FromDate'
AND CAST(FLOOR(CAST(RWA.dteLandingDate AS FLOAT))AS DATETIME) <= '@ToDate'

SELECT AC.uidAgencyId AS uidAgencyId,
APP.uidRequisitionId AS uidRequisitionId,
RDT.nvcTranslation AS nvcRace,
COUNT(APP.uidId)AS intCountOfApplications
INTO #tmpAgencyApplicationsByRace
FROM relApplication APP
JOIN dtlCandidate C
ON APP.uidCandidateId = C.uidId 
JOIN relCandidateSectionValue CSV
ON C.uidId = CSV.uidCandidateId
JOIN neptune_dynamic_objects.relCandidateFieldValue_CBAE5C2B870E48D0A8C280B713CEB2B4 CFV
ON CSV.uidId = CFV.uidCandidateSectionValueId 
JOIN refReferenceDataItem RDI
ON CFV.uidIdValue = RDI.uidId AND CFV.uidCandidateFieldId = '37EA1626-39FC-4B1E-83C1-4EDFE03D66E8' -- Race
JOIN relReferenceDataTranslation RDT
ON RDI.uidId = RDT.uidReferenceDataItemId AND RDT.uidLanguageId = '4850874D-715B-4950-B188-738E2FFC1520' -- English
JOIN relAgencyCandidate AC 
ON C.uidId = AC.uidCandidateId 
WHERE APP.uidRequisitionId IN (SELECT uidRequisitionId FROM #tmpRequisitionFilter)
GROUP BY AC.uidAgencyId, APP.uidRequisitionId, RDT.nvcTranslation 

SELECT CC.uidRequisitionId, AA.uidId AS uidApplicationWorkflowStepId, COUNT(DISTINCT AA.uidId) AS AWFCount
INTO #tmpAgencyApplicationsAWFCounts
FROM refApplicationWorkflowStep AA
JOIN relApplicationWorkflowHistory BB ON AA.uidId = BB.uidApplicationWorkflowStepId 
JOIN relApplication CC ON BB.uidApplicationId = CC.uidId 
WHERE BB.uidApplicationId IN
(
	SELECT A1.uidId FROM relApplication A1
	JOIN dtlRequisition R1 ON A1.uidRequisitionId = R1.uidId 
	JOIN relAgencyRequisition AR1 ON R1.uidId = AR1.uidRequisitionId 
)
AND BB.dteLandingDate >=
(
	SELECT MAX(dteLandingDate)
	FROM relApplicationWorkflowHistory
	WHERE uidApplicationWorkflowStepId IN 
	(
		SELECT uidId FROM refApplicationWorkflowStep WHERE nvcName = 'Unprocessed'
	)
	AND uidApplicationId = BB.uidApplicationId 
)
AND CC.uidRequisitionId IN (SELECT uidRequisitionId FROM #tmpRequisitionFilter)
GROUP BY CC.uidRequisitionId, AA.uidId

SELECT R.uidId AS uidRequisitionId,
R.nvcReferenceCode,
A.nvcName AS 'AgencyName',
(
	SELECT nvcName
	FROM refRequisitionWorkflowStep
	WHERE uidId = R.uidRequisitionWorkflowStepId
) AS 'JobStatus',
(
	SELECT R1.nvcFirstname + ' ' + R1.nvcLastname AS 'Creator'
	FROM dtlRecruiter R1
	JOIN relRecruiterRequisition RR1
	ON R1.uidId = RR1.uidRecruiterId 
	WHERE RR1.enmRecruiterRequisitionType = 1
	AND RR1.uidRequisitionId = R.uidId
) AS 'JobCreator',
(
	SELECT TOP 1 R2.nvcFirstname + ' ' + R2.nvcLastname AS 'Owner'
	FROM dtlRecruiter R2
	JOIN relRecruiterRequisition RR2
	ON R2.uidId = RR2.uidRecruiterId 
	WHERE RR2.enmRecruiterRequisitionType = 2
	AND RR2.uidRequisitionId = R.uidId
) AS 'JobOwner',
R.dteCreationDate AS 'DateJobCreated',
(
	SELECT TOP 1 RWA2.dteLandingDate 
	FROM refRequisitionWorkflowStep RWS2
	JOIN relRequisitionWorkflowAction RWA2
	ON RWS2.uidId = RWA2.uidRequisitionWorkflowStepId
	WHERE RWS2.bitPublished = 1
	AND RWA2.uidRequisitionId = R.uidId
) AS 'DateJobFirstAdvertised',
AR.intMaxApplications AS 'TotalAllowedApps',
(
	SELECT COUNT(uidId)
	FROM relApplication 
	WHERE uidRequisitionId = R.uidId
	AND uidCandidateId IN
	(
		SELECT uidCandidateId FROM
		relAgencyCandidate 
		WHERE uidAgencyId = A.uidId
	)
) AS 'TotalAppsSubmitted',
(
	SELECT COUNT(AWH.uidId)
	FROM relApplicationWorkflowHistory AWH
	JOIN relApplication APP1
	ON AWH.uidApplicationId = APP1.uidId 
	JOIN dtlCandidate C1
	ON APP1.uidCandidateId = C1.uidId 
	JOIN relAgencyCandidate AC1
	ON C1.uidId = AC1.uidCandidateId 
	WHERE uidApplicationWorkflowPathId IN 
	(
		SELECT uidId FROM relApplicationWorkflowPath WHERE nvcName = 'Unprocessed-Regretted'
	)
	AND APP1.uidRequisitionId = R.uidId 
	AND AC1.uidAgencyId = A.uidId 
) AS 'TotalApps_UnporcessedToRegret',
(
	SELECT COUNT(AWFCount)AS 'WFS_Unprocessed'
	FROM #tmpAgencyApplicationsAWFCounts
	WHERE uidApplicationWorkflowStepId IN 
	(
		SELECT uidId FROM refApplicationWorkflowStep WHERE nvcName = 'Unprocessed'
	)
	AND uidRequisitionId = R.uidId
) AS 'WFS_Unprocessed',
(
	SELECT COUNT(AWFCount)AS 'WFS_Longlist'
	FROM #tmpAgencyApplicationsAWFCounts
	WHERE uidApplicationWorkflowStepId IN 
	(
		SELECT uidId FROM refApplicationWorkflowStep WHERE nvcName = 'Longlist'
	)
	AND uidRequisitionId = R.uidId
) AS 'WFS_Longlist',
(
	SELECT COUNT(AWFCount)AS 'WFS_Shortlist'
	FROM #tmpAgencyApplicationsAWFCounts
	WHERE uidApplicationWorkflowStepId IN 
	(
		SELECT uidId FROM refApplicationWorkflowStep WHERE nvcName = 'Shortlist'
	)
	AND uidRequisitionId = R.uidId
) AS 'WFS_Shortlist',
(
	SELECT COUNT(AWFCount)AS 'WFS_Interview'
	FROM #tmpAgencyApplicationsAWFCounts
	WHERE uidApplicationWorkflowStepId IN 
	(
		SELECT uidId FROM refApplicationWorkflowStep WHERE nvcName = 'Interview'
	)
	AND uidRequisitionId = R.uidId
) AS 'WFS_Interview',
(
	SELECT COUNT(AWFCount)AS 'WFS_UnderReview'
	FROM #tmpAgencyApplicationsAWFCounts
	WHERE uidApplicationWorkflowStepId IN 
	(
		SELECT uidId FROM refApplicationWorkflowStep WHERE nvcName = 'Under Review'
	)
	AND uidRequisitionId = R.uidId
) AS 'WFS_UnderReview',
(
	SELECT COUNT(AWFCount)AS 'WFS_OfferMade'
	FROM #tmpAgencyApplicationsAWFCounts
	WHERE uidApplicationWorkflowStepId IN 
	(
		SELECT uidId FROM refApplicationWorkflowStep WHERE nvcName = 'Offer Made'
	)
	AND uidRequisitionId = R.uidId
) AS 'WFS_OfferMade',
(
	SELECT COUNT(AWFCount)AS 'WFS_Hired'
	FROM #tmpAgencyApplicationsAWFCounts
	WHERE uidApplicationWorkflowStepId IN 
	(
		SELECT uidId FROM refApplicationWorkflowStep WHERE nvcName = 'Hired'
	)
	AND uidRequisitionId = R.uidId
) AS 'WFS_Hired',
(
	SELECT COUNT(AWFCount)AS 'WFS_Regretted'
	FROM #tmpAgencyApplicationsAWFCounts
	WHERE uidApplicationWorkflowStepId IN 
	(
		SELECT uidId FROM refApplicationWorkflowStep WHERE nvcName = 'Regretted'
	)
	AND uidRequisitionId = R.uidId
) AS 'WFS_Regretted',
(
	SELECT COUNT(AWFCount)AS 'WFS_Declined'
	FROM #tmpAgencyApplicationsAWFCounts
	WHERE uidApplicationWorkflowStepId IN 
	(
		SELECT uidId FROM refApplicationWorkflowStep WHERE nvcName = 'Declined'
	)
	AND uidRequisitionId = R.uidId
) AS 'WFS_Declined',
(
	SELECT COUNT(AWFCount)AS 'WFS_Withdrawn'
	FROM #tmpAgencyApplicationsAWFCounts
	WHERE uidApplicationWorkflowStepId IN 
	(
		SELECT uidId FROM refApplicationWorkflowStep WHERE nvcName = 'Withdrawn'
	)
	AND uidRequisitionId = R.uidId
) AS 'WFS_Withdrawn',
(
	SELECT intCountOfApplications 
	FROM #tmpAgencyApplicationsByRace
	WHERE nvcRace = 'Asian'
	AND uidRequisitionId = R.uidId
	AND uidAgencyId = A.uidId
) AS 'Race Count - Asian',
(
	SELECT intCountOfApplications 
	FROM #tmpAgencyApplicationsByRace
	WHERE nvcRace = 'Black'
	AND uidRequisitionId = R.uidId
	AND uidAgencyId = A.uidId
) AS 'Race Count - Black',
(
	SELECT intCountOfApplications 
	FROM #tmpAgencyApplicationsByRace
	WHERE nvcRace = 'Coloured'
	AND uidRequisitionId = R.uidId
	AND uidAgencyId = A.uidId
) AS 'Race Count - Coloured',
(
	SELECT intCountOfApplications 
	FROM #tmpAgencyApplicationsByRace
	WHERE nvcRace = 'Indian / Asian'
	AND uidRequisitionId = R.uidId
	AND uidAgencyId = A.uidId
) AS 'Race Count - Indian / Asian',
(
	SELECT intCountOfApplications 
	FROM #tmpAgencyApplicationsByRace
	WHERE nvcRace = 'White'
	AND uidRequisitionId = R.uidId
	AND uidAgencyId = A.uidId
) AS 'Race Count - White'
INTO #tmpAgencyAppsByJob
FROM dtlRequisition R
JOIN relAgencyRequisition AR
ON R.uidId = AR.uidRequisitionId
JOIN dtlAgency A
ON AR.uidAgencyId = A.uidId 
WHERE R.uidId IN
(
	SELECT uidRequisitionId
	FROM #tmpRequisitionFilter
)

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
DECLARE @intCount int, @enmDataType int

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
		AND RSV.uidRequisitionId IN(SELECT uidRequisitionId FROM #tmpAgencyAppsByJob)		
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
		AND RSV.uidRequisitionId IN(SELECT uidRequisitionId FROM #tmpAgencyAppsByJob)
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
		AND RSV.uidRequisitionId IN(SELECT uidRequisitionId FROM #tmpAgencyAppsByJob)
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
		AND RSV.uidRequisitionId IN(SELECT uidRequisitionId FROM #tmpAgencyAppsByJob)
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
		AND RSV.uidRequisitionId IN(SELECT uidRequisitionId FROM #tmpAgencyAppsByJob)
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
		AND RSV.uidRequisitionId IN(SELECT uidRequisitionId FROM #tmpAgencyAppsByJob)
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
		AND RSV.uidRequisitionId IN(SELECT uidRequisitionId FROM #tmpAgencyAppsByJob)
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

	WHILE @intCount <= (select COUNT(*) from #tmpTemplateFields)
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

	WHILE @intCount <= (select COUNT(*) from #tmpTemplateFields)
	BEGIN
		SELECT @nvcSql = @nvcSql + ' 
		LEFT JOIN #tmpTFValues RTFV' + CAST(@intCount as nvarchar) + ' ON R.uidId = RTFV' + CAST(@intCount as nvarchar) + '.RelId AND RTFV' + CAST(@intCount as nvarchar) + '.FN = ' + CAST(@intCount as nvarchar)

		SELECT @intCount = @intCount + 1
		
	END

	SELECT @nvcSql = @nvcSql + ' WHERE R.uidId IN(SELECT uidRequisitionId FROM #tmpAgencyAppsByJob)'

	EXEC sp_executeSql @nvcSql
END


SELECT AABJ.nvcReferenceCode AS 'Job Ref #',
AABJ.AgencyName AS 'Agency Name',
AABJ.JobStatus AS 'Job Status',
AABJ.JobCreator AS 'Job Creator',
AABJ.JobOwner AS 'Job Owner',
AABJ.DateJobCreated AS 'Date Job Created',
AABJ.DateJobFirstAdvertised AS 'Date Job First Advertised',
AABJ.TotalAllowedApps AS 'Total Allowed Apps',
AABJ.TotalAppsSubmitted AS 'Total Apps Submitted',
AABJ.TotalApps_UnporcessedToRegret  AS 'Total Apps Moved From Unprocessed To Regret',
AABJ.WFS_Unprocessed  AS 'Workflow Step: Unprocessed',
AABJ.WFS_Longlist  AS 'Workflow Step: LongList',
AABJ.WFS_Shortlist  AS 'Workflow Step: Shortlist',
AABJ.WFS_Interview  AS 'Workflow Step: Interview',
AABJ.WFS_UnderReview  AS 'Workflow Step: Under Review',
AABJ.WFS_OfferMade  AS 'Workflow Step: Offer Made',
AABJ.WFS_Hired  AS 'Workflow Step: Hired',
AABJ.WFS_Regretted  AS 'Workflow Step: Regretted',
AABJ.WFS_Declined  AS 'Workflow Step: Declined',
AABJ.WFS_Withdrawn  AS 'Workflow Step: Withdrawn',
AABJ.[Race Count - Asian]  AS 'Race Count - Asian',
AABJ.[Race Count - Black]  AS 'Race Count - Black',
AABJ.[Race Count - Coloured]  AS 'Race Count - Coloured',
AABJ.[Race Count - Indian / Asian]  AS 'Race Count - Indian / Asian',
AABJ.[Race Count - White]  AS 'Race Count - White',
RRR.* 
FROM
#tmpAgencyAppsByJob AABJ
JOIN #tmpRR_Result RRR
ON RRR.uidRequisitionId = AABJ.uidRequisitionId


DROP TABLE #tmpRequisitionFilter
DROP TABLE #tmpAgencyApplicationsByRace
DROP TABLE #tmpAgencyApplicationsAWFCounts	
DROP TABLE #tmpAgencyAppsByJob
DROP TABLE #tmpTemplateFields
DROP TABLE #tmpTFDupValues
DROP TABLE #tmpTFValues
DROP TABLE #tmpRR_Result
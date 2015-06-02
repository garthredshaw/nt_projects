-- Agency Application History (Date Range)
-- 20150528
SET NOCOUNT ON
SET DATEFORMAT DMY

DECLARE @tmpRequisitionFilter TABLE
(
	uidRequisitionId uniqueidentifier
)

INSERT INTO @tmpRequisitionFilter
SELECT DISTINCT RW.uidRequisitionId 
FROM relRequisitionWebsite RW
JOIN relRequisitionAgency RA ON RW.uidRequisitionId = RA.uidRequisitionId
WHERE (CAST(FLOOR(CAST(RW.dteStartDate AS FLOAT))AS DATETIME) >= '@FromDate'
AND CAST(FLOOR(CAST(RW.dteEndDate AS FLOAT))AS DATETIME) <= '@ToDate')
AND RW.uidWebsiteId IN (SELECT uidId FROM refWebsite WHERE nvcName = 'Agency')

DECLARE @tmpAgencyApplications TABLE
(
	uidApplicationId uniqueidentifier,
	uidRequisitionId uniqueidentifier,
	uidAgencyId uniqueidentifier	
)

INSERT INTO @tmpAgencyApplications
SELECT A.uidId,
A.uidRequisitionId,
AC.uidAgencyId
FROM relApplication A
JOIN relAgencyCandidate AC ON A.uidCandidateId = AC.uidCandidateID
WHERE 
A.uidRequisitionId IN (SELECT uidRequisitionId FROM @tmpRequisitionFilter)

DECLARE @tmpAgencyApplicationsByRace TABLE
(
	uidAgencyId uniqueidentifier,
	uidRequisitionId uniqueidentifier,
	nvcRace nvarchar(MAX),
	intCountOfApplications int
)

INSERT INTO @tmpAgencyApplicationsByRace
SELECT AC1.uidAgencyId AS uidAgencyId,
A2.uidRequisitionId AS uidRequisitionId,
RDT1.nvcTranslation AS nvcRace,
COUNT(A2.uidId)AS intCountOfApplications
FROM relApplication A2
JOIN dtlCandidate C1 ON A2.uidCandidateId = C1.uidId 
JOIN relCandidateSectionValue CSV1 ON C1.uidId = CSV1.uidCandidateId
JOIN neptune_dynamic_objects.relCandidateFieldValue_CBAE5C2B870E48D0A8C280B713CEB2B4 CFV1 ON CSV1.uidId = CFV1.uidCandidateSectionValueId 
JOIN refReferenceDataItem RDI1 ON CFV1.uidIdValue = RDI1.uidId AND CFV1.uidCandidateFieldId = '37EA1626-39FC-4B1E-83C1-4EDFE03D66E8' -- Race
JOIN relReferenceDataTranslation RDT1 ON RDI1.uidId = RDT1.uidReferenceDataItemId AND RDT1.uidLanguageId = '4850874D-715B-4950-B188-738E2FFC1520' -- English
JOIN relAgencyCandidate AC1 ON C1.uidId = AC1.uidCandidateId 
WHERE A2.uidId IN (SELECT uidApplicationId FROM @tmpAgencyApplications)
GROUP BY AC1.uidAgencyId, A2.uidRequisitionId, RDT1.nvcTranslation 


DECLARE @tmpAWSHistory TABLE
(
	uidRequisitionId uniqueidentifier,
	uidApplicationId uniqueidentifier,
	uidApplicationWorkflowStepId uniqueidentifier,
	uidAgencyId uniqueidentifier
)

INSERT INTO @tmpAWSHistory
SELECT APP.uidRequisitionId, 
APP.uidId,
APP.uidApplicationWorkflowStepId,
AC.uidAgencyId
FROM relApplication APP
JOIN dtlCandidate CAN ON APP.uidCandidateId = CAN.uidId 
JOIN relAgencyCandidate AC ON CAN.uidId = AC.uidCandidateId 
WHERE APP.uidId IN 
(
	SELECT uidApplicationID FROM @tmpAgencyApplications
)


SELECT REQ1.uidId AS uidRequisitionId,
REQ1.nvcReferenceCode,
A.nvcName AS 'AgencyName',
(
	SELECT nvcName
	FROM refRequisitionWorkflowStep
	WHERE uidId = REQ1.uidRequisitionWorkflowStepId
) AS 'JobStatus',
(
	SELECT R1.nvcFirstname + ' ' + R1.nvcLastname AS 'Creator'
	FROM dtlRecruiter R1
	JOIN relRecruiterRequisition RR1 ON R1.uidId = RR1.uidRecruiterId 
	WHERE RR1.enmRecruiterRequisitionType = 1
	AND RR1.uidRequisitionId = REQ1.uidId
) AS 'JobCreator',
(
	SELECT TOP 1 R2.nvcFirstname + ' ' + R2.nvcLastname AS 'Owner'
	FROM dtlRecruiter R2
	JOIN relRecruiterRequisition RR2 ON R2.uidId = RR2.uidRecruiterId 
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
RA.intMaxApplications AS 'TotalAllowedApps',
(
	SELECT COUNT(APP3.uidId)
	FROM relApplication APP3
	WHERE APP3.uidRequisitionId = REQ1.uidId
	AND APP3.uidCandidateId IN
	(
		SELECT AC2.uidCandidateId FROM
		relAgencyCandidate AC2
		WHERE AC2.uidAgencyId = A.uidId
	)
) AS 'TotalAppsSubmitted',
(
	SELECT COUNT(AWH1.uidId)
	FROM relApplicationWorkflowHistory AWH1
	JOIN relApplication APP4 ON AWH1.uidApplicationId = APP4.uidId 
	JOIN dtlCandidate C2 ON APP4.uidCandidateId = C2.uidId 
	JOIN relAgencyCandidate AC3 ON C2.uidId = AC3.uidCandidateId 
	WHERE AWH1.uidApplicationWorkflowPathId IN 
	(
		SELECT AWP1.uidId FROM relApplicationWorkflowPath AWP1 WHERE AWP1.nvcName = 'Unprocessed-Regretted'
	)
	AND APP4.uidRequisitionId = REQ1.uidId 
	AND AC3.uidAgencyId = A.uidId 
) AS 'TotalApps_UnporcessedToRegret',
(
	SELECT COUNT(AWSH1.uidApplicationId)AS 'WFS_Unprocessed'
	FROM @tmpAWSHistory AWSH1
	WHERE AWSH1.uidApplicationWorkflowStepId IN 
	(
		SELECT AWS1.uidId FROM refApplicationWorkflowStep AWS1 WHERE AWS1.nvcName = 'Unprocessed'
	)
	AND AWSH1.uidRequisitionId = REQ1.uidId
	AND AWSH1.uidAgencyId = A.uidId	
) AS 'WFS_Unprocessed',
(
	SELECT COUNT(AWSH2.uidApplicationId)AS 'WFS_Longlist'
	FROM @tmpAWSHistory AWSH2
	WHERE AWSH2.uidApplicationWorkflowStepId IN 
	(
		SELECT AWS2.uidId FROM refApplicationWorkflowStep AWS2 WHERE AWS2.nvcName = 'Longlist'
	)
	AND AWSH2.uidRequisitionId = REQ1.uidId
	AND AWSH2.uidAgencyId = A.uidId
) AS 'WFS_Longlist',
(
	SELECT COUNT(AWSH3.uidApplicationId)AS 'WFS_Shortlist'
	FROM @tmpAWSHistory AWSH3
	WHERE AWSH3.uidApplicationWorkflowStepId IN 
	(
		SELECT AWS3.uidId FROM refApplicationWorkflowStep AWS3 WHERE AWS3.nvcName = 'Shortlist'
	)
	AND AWSH3.uidRequisitionId = REQ1.uidId
	AND AWSH3.uidAgencyId = A.uidId
) AS 'WFS_Shortlist',
(
	SELECT COUNT(AWSH4.uidApplicationId)AS 'WFS_Interview'
	FROM @tmpAWSHistory AWSH4
	WHERE AWSH4.uidApplicationWorkflowStepId IN 
	(
		SELECT AWS4.uidId FROM refApplicationWorkflowStep AWS4 WHERE AWS4.nvcName = 'Interview'
	)
	AND AWSH4.uidRequisitionId = REQ1.uidId
	AND AWSH4.uidAgencyId = A.uidId
) AS 'WFS_Interview',
(
	SELECT COUNT(AWSH5.uidApplicationId)AS 'WFS_UnderReview'
	FROM @tmpAWSHistory AWSH5
	WHERE AWSH5.uidApplicationWorkflowStepId IN 
	(
		SELECT AWS5.uidId FROM refApplicationWorkflowStep AWS5 WHERE AWS5.nvcName = 'Under Review'
	)
	AND AWSH5.uidRequisitionId = REQ1.uidId
	AND AWSH5.uidAgencyId = A.uidId
) AS 'WFS_UnderReview',
(
	SELECT COUNT(AWSH6.uidApplicationId)AS 'WFS_OfferMade'
	FROM @tmpAWSHistory AWSH6
	WHERE AWSH6.uidApplicationWorkflowStepId IN 
	(
		SELECT AWS6.uidId FROM refApplicationWorkflowStep AWS6 WHERE AWS6.nvcName = 'Offer Made'
	)
	AND AWSH6.uidRequisitionId = REQ1.uidId
	AND AWSH6.uidAgencyId = A.uidId
) AS 'WFS_OfferMade',
(
	SELECT COUNT(AWSH7.uidApplicationId)AS 'WFS_Hired'
	FROM @tmpAWSHistory AWSH7
	WHERE AWSH7.uidApplicationWorkflowStepId IN 
	(
		SELECT AWS7.uidId FROM refApplicationWorkflowStep AWS7 WHERE AWS7.nvcName = 'Hired'
	)
	AND AWSH7.uidRequisitionId = REQ1.uidId
	AND AWSH7.uidAgencyId = A.uidId
) AS 'WFS_Hired',
(
	SELECT COUNT(AWSH8.uidApplicationId)AS 'WFS_Regretted'
	FROM @tmpAWSHistory AWSH8
	WHERE AWSH8.uidApplicationWorkflowStepId IN 
	(
		SELECT AWS8.uidId FROM refApplicationWorkflowStep AWS8 WHERE AWS8.nvcName = 'Regretted'
	)
	AND AWSH8.uidRequisitionId = REQ1.uidId
	AND AWSH8.uidAgencyId = A.uidId
) AS 'WFS_Regretted',
(
	SELECT COUNT(AWSH9.uidApplicationId)AS 'WFS_Declined'
	FROM @tmpAWSHistory AWSH9
	WHERE AWSH9.uidApplicationWorkflowStepId IN 
	(
		SELECT AWS9.uidId FROM refApplicationWorkflowStep AWS9 WHERE AWS9.nvcName = 'Declined'
	)
	AND AWSH9.uidRequisitionId = REQ1.uidId
	AND AWSH9.uidAgencyId = A.uidId
) AS 'WFS_Declined',
(
	SELECT COUNT(AWSH10.uidApplicationId)AS 'WFS_Withdrawn'
	FROM @tmpAWSHistory AWSH10
	WHERE uidApplicationWorkflowStepId IN 
	(
		SELECT AWS10.uidId FROM refApplicationWorkflowStep AWS10 WHERE AWS10.nvcName = 'Withdrawn'
	)
	AND AWSH10.uidRequisitionId = REQ1.uidId
	AND AWSH10.uidAgencyId = A.uidId
) AS 'WFS_Withdrawn',
(
	SELECT AABR1.intCountOfApplications 
	FROM @tmpAgencyApplicationsByRace AABR1
	WHERE AABR1.nvcRace = 'Asian'
	AND AABR1.uidRequisitionId = REQ1.uidId
	AND AABR1.uidAgencyId = A.uidId
) AS 'Race Count - Asian',
(
	SELECT AABR2.intCountOfApplications 
	FROM @tmpAgencyApplicationsByRace AABR2
	WHERE AABR2.nvcRace = 'Black'
	AND AABR2.uidRequisitionId = REQ1.uidId
	AND AABR2.uidAgencyId = A.uidId
) AS 'Race Count - Black',
(
	SELECT AABR3.intCountOfApplications 
	FROM @tmpAgencyApplicationsByRace AABR3
	WHERE AABR3.nvcRace = 'Coloured'
	AND AABR3.uidRequisitionId = REQ1.uidId
	AND AABR3.uidAgencyId = A.uidId
) AS 'Race Count - Coloured',
(
	SELECT AABR4.intCountOfApplications 
	FROM @tmpAgencyApplicationsByRace AABR4
	WHERE AABR4.nvcRace = 'Indian / Asian'
	AND AABR4.uidRequisitionId = REQ1.uidId
	AND AABR4.uidAgencyId = A.uidId
) AS 'Race Count - Indian / Asian',
(
	SELECT AABR5.intCountOfApplications 
	FROM @tmpAgencyApplicationsByRace AABR5
	WHERE AABR5.nvcRace = 'White'
	AND AABR5.uidRequisitionId = REQ1.uidId
	AND AABR5.uidAgencyId = A.uidId
) AS 'Race Count - White'
INTO #tmpAgencyAppsByJob
FROM dtlRequisition REQ1 
JOIN relRequisitionAgency RA ON REQ1.uidId = RA.uidRequisitionId
JOIN dtlAgency A ON RA.uidAgencyId = A.uidId 
WHERE REQ1.uidId IN
(
	SELECT RF2.uidRequisitionId	FROM @tmpRequisitionFilter RF2
)

DECLARE @tmpTemplateFields TABLE 
(
	ID INT Identity(1,1),
	FName VARCHAR(MAX),
	FieldId uniqueidentifier,
	SectionId uniqueidentifier,
	SortOrder int,
	DataType int
) 

INSERT INTO @tmpTemplateFields
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

WHILE (SELECT MAX(PATINDEX('%[^a-zA-Z0-9]%', FName)) FROM @tmpTemplateFields) > 0
BEGIN

	UPDATE @tmpTemplateFields 
	SET FName = REPLACE(FName, SUBSTRING(FName, PATINDEX('%[^a-zA-Z0-9]%', FName), 1), '')
	
	
	IF (SELECT MAX(PATINDEX('%[^a-zA-Z0-9]%', FName)) FROM @tmpTemplateFields) = 0
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

WHILE @intCount <= (SELECT COUNT(*) FROM @tmpTemplateFields)
BEGIN
	SELECT @nvcFieldName = RTF.FName,
	@enmDataType = RTF.DataType,
	@uidFieldId = RTF.FieldId 
    FROM @tmpTemplateFields RTF
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
+ ' NVARCHAR(MAX) NULL, ' FROM (SELECT FName FROM @tmpTemplateFields) As #tmpDistinctCandidateFields1

SELECT @nvcSql = LEFT(@nvcSql, LEN(@nvcSql)-1)

EXEC sp_executeSql @nvcSql

SET @intCount = 1

IF (SELECT COUNT(*) FROM #tmpTFValues) > 0
BEGIN
	SELECT @nvcSql = 'INSERT INTO #tmpRR_Result
	SELECT R.uidID, '

	WHILE @intCount <= (select COUNT(*) from @tmpTemplateFields)
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

	WHILE @intCount <= (select COUNT(*) from @tmpTemplateFields)
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
CONVERT(varchar, AABJ.DateJobCreated, 106) AS 'Date Job Created',
CONVERT(varchar, AABJ.DateJobFirstAdvertised, 106) AS 'Date Job First Advertised',
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
FROM #tmpAgencyAppsByJob AABJ
JOIN #tmpRR_Result RRR
ON RRR.uidRequisitionId = AABJ.uidRequisitionId

DROP TABLE #tmpAgencyAppsByJob
DROP TABLE #tmpTFDupValues
DROP TABLE #tmpTFValues
DROP TABLE #tmpRR_Result
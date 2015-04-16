-- Hired Candidates (Date Range)
-- 20141212
SET NOCOUNT ON;
SET DATEFORMAT DMY

CREATE TABLE #tmpReport_HiredCandidate 
(		
	uidApplicationId uniqueidentifier,		
	uidCandidateId uniqueidentifier,
	uidRequisitionId uniqueidentifier,
	dteApplicationDate datetime,
	uidApplicationWorkflowStepId uniqueidentifier,
	nvcOrigin nvarchar(50),
	dteCreationDate datetime,
	nvcJobReferenceCode nvarchar(255),
	nvcRequisitionJobStatus nvarchar(255),
	dteJobFirstAdvertised datetime,
	intDaysAdvertised int,
	intDaysReview int,
	intDaysActive int,
	dteJobDateArchived datetime,
	intTotalJobTat int,
	dteJobDateReview datetime,
	nvcJobCreator nvarchar(255),
	nvcJobOwner nvarchar(255),
	nvcRegistrationWebsite nvarchar(255),
	dteCandidateRegistrationDate datetime,
	dteCandidateLastAccessedDate datetime,
	nvcApplicationStatus nvarchar(255),
	dteHiredDate datetime,
	nvcHiredBy nvarchar(255),
	intApplicantTat int,
	intTimeToHire int,
	nvcAgencyName nvarchar(255),
	nvcCandidateEmail nvarchar(255),
	nvcCandidateMobileNumber nvarchar(255)
) 


INSERT INTO #tmpReport_HiredCandidate
(
	uidApplicationId,
	uidCandidateId,
	uidRequisitionId,
	dteApplicationDate,
	uidApplicationWorkflowStepId,
	nvcOrigin,
	dteCreationDate,
	nvcJobReferenceCode,
	nvcRequisitionJobStatus,
	dteJobFirstAdvertised,
	intDaysAdvertised,
	intDaysReview,
	intDaysActive,
	dteJobDateArchived,
	intTotalJobTat,
	dteJobDateReview,
	nvcJobCreator,
	nvcJobOwner,
	nvcRegistrationWebsite,
	dteCandidateRegistrationDate,
	dteCandidateLastAccessedDate,
	nvcApplicationStatus,
	dteHiredDate,
	nvcHiredBy,
	intApplicantTat,
	intTimeToHire,
	nvcAgencyName,
	nvcCandidateEmail,
	nvcCandidateMobileNumber
)
SELECT APP.uidId AS uidApplicationId,
APP.uidCandidateId,
APP.uidRequisitionId,
APP.dteApplicationDate,
APP.uidApplicationWorkflowStepId,
APP.nvcOrigin,
REQ.dteCreationDate,
REQ.nvcReferenceCode AS 'nvcJobReferenceCode',
RWFS.nvcName AS 'nvcRequisitionJobStatus',
(
	SELECT MIN(BB.dteLandingDate) 
	FROM refRequisitionWorkflowStep AA
	JOIN relRequisitionWorkflowAction BB
	ON AA.uidId = BB.uidRequisitionWorkflowStepId
	WHERE AA.bitPublished = 1
	AND BB.uidRequisitionId = APP.uidRequisitionId
) AS 'dteJobFirstAdvertised',
NULL AS 'intDaysAdvertised',
NULL AS 'intDaysReview',
NULL AS 'intDaysActive',
(
	SELECT TOP 1 BBB.dteLandingDate 
	FROM refRequisitionWorkflowStep AAA
	JOIN relRequisitionWorkflowAction BBB
	ON AAA.uidId = BBB.uidRequisitionWorkflowStepId
	WHERE AAA.nvcName = 'Archived'
	AND BBB.uidRequisitionId = APP.uidRequisitionId
) AS 'dteJobDateArchived',
NULL as 'intTotalJobTat',
(
	SELECT TOP 1 BBB.dteLandingDate 
	FROM refRequisitionWorkflowStep AAA
	JOIN relRequisitionWorkflowAction BBB
	ON AAA.uidId = BBB.uidRequisitionWorkflowStepId
	WHERE AAA.nvcName = 'Review'
	AND BBB.uidRequisitionId = APP.uidRequisitionId
) AS 'dteJobDateReview',
(
	SELECT TOP 1 R1.nvcFirstname + ' ' + R1.nvcLastname AS 'Creator'
	FROM dtlRecruiter R1
	JOIN relRecruiterRequisition RR1
	ON R1.uidId = RR1.uidRecruiterId 
	WHERE RR1.enmRecruiterRequisitionType = 1
	AND RR1.uidRequisitionId = APP.uidRequisitionId
) AS 'nvcJobCreator',
(
	SELECT TOP 1 R2.nvcFirstname + ' ' + R2.nvcLastname AS 'Owner'
	FROM dtlRecruiter R2
	JOIN relRecruiterRequisition RR2
	ON R2.uidId = RR2.uidRecruiterId 
	WHERE RR2.enmRecruiterRequisitionType = 2
	AND RR2.uidRequisitionId = APP.uidRequisitionId
) AS 'nvcJobOwner',
(
	SELECT TOP 1 WA.nvcHTTPAddress
	FROM dtlCandidate C
	JOIN refWebsite W
	ON C.uidWebsiteId = W.uidId 
	JOIN refWebsiteAddress WA
	ON WA.uidWebsiteId = W.uidId
	WHERE C.uidId = APP.uidCandidateId 
	AND WA.bitIsPrimary = 1
	AND WA.nvcHTTPAddress <> 'localhost'
) AS 'nvcRegistrationWebsite',
(
	SELECT dteRegistrationDate 
	FROM dtlCandidate
	WHERE dtlCandidate.uidId = APP.uidCandidateId
) AS 'dteCandidateRegistrationDate',
(
	SELECT U.dteLastLogin
	FROM dtlUser U
	JOIN dtlCandidate C
	ON U.uidId = C.uidUserId 
	WHERE C.uidId = APP.uidCandidateId
) AS 'dteCandidateLastAccessedDate',
(
	SELECT nvcName AS 'AppStatus'
	FROM refApplicationWorkflowStep AWS
	JOIN relApplication A
	ON A.uidApplicationWorkflowStepId = AWS.uidId
	WHERE A.uidId = APP.uidId
) AS 'nvcApplicationStatus',
(
	SELECT MIN(AWH.dteLandingDate)
	FROM relApplication A
	JOIN relApplicationWorkflowHistory AWH
	ON A.uidId = AWH.uidApplicationId
	WHERE AWH.uidApplicationWorkflowStepId IN 
	(
		SELECT uidId FROM refApplicationWorkflowStep WHERE nvcName = 'Hired'
	)
	AND A.uidRequisitionId = APP.uidRequisitionId
	AND A.uidCandidateId = APP.uidCandidateId 
) AS 'dteHiredDate',
(
	SELECT TOP 1 R.nvcFirstname + ' ' + R.nvcLastname AS 'RecruiterName'  
	FROM relApplication A
	JOIN relApplicationWorkflowHistory AWH
	ON A.uidId = AWH.uidApplicationId
	JOIN dtlUser U
	ON AWH.uidUserId = U.uidId 
	JOIN dtlRecruiter R
	ON U.uidId = R.uidUserId 
	WHERE AWH.uidApplicationWorkflowStepId IN 
	(
		SELECT uidId FROM refApplicationWorkflowStep WHERE nvcName = 'Hired'
	)
	AND A.uidRequisitionId = APP.uidRequisitionId
	AND A.uidCandidateId = APP.uidCandidateId 
) AS 'nvcHiredBy',
NULL AS 'intApplicantTat',
NULL AS 'intTimeToHire',
(
	SELECT A.nvcName AS 'AgencyName'
	FROM dtlAgency A
	JOIN relAgencyCandidate AC
	ON A.uidId = AC.uidAgencyId
	JOIN dtlCandidate CAN
	ON CAN.uidId = AC.uidCandidateId
	JOIN relApplication APP1
	ON CAN.uidId = APP1.uidCandidateId
	WHERE APP1.uidId = APP.uidId
) AS 'nvcAgencyName',
(
	SELECT U.nvcEmail 
	FROM dtlUser U
	JOIN dtlCandidate C
	ON U.uidId = C.uidUserId 
	WHERE C.uidId = APP.uidCandidateId
) AS 'nvcCandidateEmail',
(
	SELECT U.nvcMobileNumber  
	FROM dtlUser U
	JOIN dtlCandidate C
	ON U.uidId = C.uidUserId 
	WHERE C.uidId = APP.uidCandidateId
) AS 'nvcCandidateMobileNumber'
FROM relApplication APP
JOIN dtlRequisition REQ
ON APP.uidRequisitionId = REQ.uidId 
JOIN refRequisitionWorkflowStep RWFS
ON REQ.uidRequisitionWorkflowStepId = RWFS.uidId
WHERE APP.uidId IN 
(
	SELECT A.uidId 
	FROM relApplication A
	JOIN relApplicationWorkflowHistory AWH
	ON A.uidId = AWH.uidApplicationId 
	AND AWH.uidApplicationWorkflowStepId IN 
	(
		SELECT uidId FROM refApplicationWorkflowStep WHERE nvcName = 'Hired'
	)	
	WHERE CAST(FLOOR(CAST(AWH.dteLandingDate AS FLOAT))AS DATETIME) >= '@FromDate'
	AND CAST(FLOOR(CAST(AWH.dteLandingDate AS FLOAT))AS DATETIME) <= '@ToDate'
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
	FROM #tmpReport_HiredCandidate
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


UPDATE #tmpReport_HiredCandidate
SET intDaysAdvertised = B.DaysAdvertised
FROM #tmpReport_HiredCandidate A
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

UPDATE #tmpReport_HiredCandidate
SET intDaysReview = B.DaysReview
FROM #tmpReport_HiredCandidate A
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

UPDATE #tmpReport_HiredCandidate
SET intDaysActive = intDaysAdvertised + intDaysReview

UPDATE #tmpReport_HiredCandidate
SET intTotalJobTat = DATEDIFF(day, dteCreationDate, dteJobDateArchived)

UPDATE #tmpReport_HiredCandidate
SET intApplicantTat = DATEDIFF(day, dteApplicationDate, dteHiredDate)

UPDATE #tmpReport_HiredCandidate
SET intTimeToHire = DATEDIFF(day, dteCreationDate, dteHiredDate)


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
	SectionId,
	SortOrder,
	DataType
)
SELECT AF.nvcName, AF.uidId, AF.uidApplicationSectionId, AF.intSortOrder, AF.enmDataType 
FROM refApplicationField AF
JOIN relApplicationTemplateField ATF
ON AF.uidId = ATF.uidApplicationFieldId 
JOIN relApplicationTemplateSection ATS
ON ATF.uidApplicationTemplateSectionId = ATS.uidId 
AND ATS.uidApplicationTemplateId = 
(
	SELECT uidId FROM refApplicationTemplate WHERE nvcName = 'Application Report Fields'
)
ORDER BY AF.intSortOrder

WHILE (SELECT MAX(PATINDEX('%[^a-zA-Z0-9]%', FName)) FROM #tmpTemplateFields) > 0
BEGIN

	UPDATE #tmpTemplateFields 
	SET FName = REPLACE(FName, SUBSTRING(FName, PATINDEX('%[^a-zA-Z0-9]%', FName), 1), '')
	
	
	IF (SELECT MAX(PATINDEX('%[^a-zA-Z0-9]%', FName)) FROM #tmpTemplateFields) = 0
		BREAK
	ELSE
		CONTINUE
END

DECLARE @nvcFieldName nvarchar(50), @nvcParameterDefinition nvarchar(4000), @nvcSql nvarchar(MAX)
DECLARE @SectionId uniqueidentifier, @uidFieldId uniqueidentifier
DECLARE @enmDataType int

SET @intCount = 1

SELECT @nvcParameterDefinition = '
		@uidFIDParam uniqueidentifier,
		@intAppFieldNoParam int'

CREATE TABLE #tmpTFDupValues
(
	ID INT Identity(1,1),
	FN int,
	RelId uniqueidentifier, 
	Value nvarchar(MAX)
)

IF (EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'neptune_dynamic_objects' 
AND  TABLE_NAME = 'relApplicationFieldValue_' + REPLACE(CAST(@SectionId As varchar(64)),'-','')))
BEGIN
	WHILE @intCount <= (SELECT COUNT(*) FROM #tmpTemplateFields)
	BEGIN
		SELECT @nvcFieldName = ATF.FName,
		@enmDataType = ATF.DataType,
		@uidFieldId = ATF.FieldId,
		@SectionId =  SectionId
		FROM #tmpTemplateFields ATF
		WHERE ATF.ID = @intCount   
			
		IF @enmDataType = 0
		BEGIN
			SELECT @nvcSql = 'INSERT INTO #tmpTFDupValues
			(FN, RelId, Value)
			
			SELECT @intAppFieldNoParam, ASV.uidApplicationId, AFV.nvcStringValue
			FROM neptune_dynamic_objects.relApplicationFieldValue_' + REPLACE(CAST(@SectionId As varchar(64)),'-','') + ' AFV
			JOIN relApplicationSectionValue ASV
			ON ASV.uidId = AFV.uidApplicationSectionValueId
			AND ASV.uidApplicationId IN(SELECT uidApplicationID FROM #tmpReport_HiredCandidate)
			WHERE AFV.uidApplicationFieldId = @uidFIDParam'
		END
		
		IF @enmDataType = 1
		BEGIN
			SELECT @nvcSql = 'INSERT INTO #tmpTFDupValues
			(FN, RelId, Value)
			
			SELECT @intAppFieldNoParam, ASV.uidApplicationId, CAST(AFV.nvcStringValue as nvarchar(max))
			FROM neptune_dynamic_objects.relApplicationFieldValue_' + REPLACE(CAST(@SectionId As varchar(64)),'-','') + ' AFV
			JOIN relApplicationSectionValue ASV
			ON ASV.uidId = AFV.uidApplicationSectionValueId
			AND ASV.uidApplicationId IN(SELECT uidApplicationID FROM #tmpReport_HiredCandidate)
			WHERE AFV.uidApplicationFieldId = @uidFIDParam'			
		END
		
		IF @enmDataType = 2
		BEGIN
			SELECT @nvcSql = 'INSERT INTO #tmpTFDupValues
			(FN, RelId, Value)
			
			SELECT @intAppFieldNoParam, ASV.uidApplicationId, CAST(AFV.intIntValue as nvarchar(max))
			FROM neptune_dynamic_objects.relApplicationFieldValue_' + REPLACE(CAST(@SectionId As varchar(64)),'-','') + ' AFV
			JOIN relApplicationSectionValue ASV
			ON ASV.uidId = AFV.uidApplicationSectionValueId
			AND ASV.uidApplicationId IN(SELECT uidApplicationID FROM #tmpReport_HiredCandidate)
			WHERE AFV.uidApplicationFieldId = @uidFIDParam'		
		END
		
		IF @enmDataType = 3
		BEGIN
			SELECT @nvcSql = 'INSERT INTO #tmpTFDupValues
			(FN, RelId, Value)
			
			SELECT @intAppFieldNoParam, ASV.uidApplicationId, CAST(AFV.fltFloatValue as nvarchar(max))
			FROM neptune_dynamic_objects.relApplicationFieldValue_' + REPLACE(CAST(@SectionId As varchar(64)),'-','') + ' AFV
			JOIN relApplicationSectionValue ASV
			ON ASV.uidId = AFV.uidApplicationSectionValueId
			AND ASV.uidApplicationId IN(SELECT uidApplicationID FROM #tmpReport_HiredCandidate)
			WHERE AFV.uidApplicationFieldId = @uidFIDParam'				
		END
		
		IF @enmDataType = 4
		BEGIN
			SELECT @nvcSql = 'INSERT INTO #tmpTFDupValues
			(FN, RelId, Value)
			
			SELECT @intAppFieldNoParam, ASV.uidApplicationId, CAST(AFV.bitBitValue as nvarchar(max))
			FROM neptune_dynamic_objects.relApplicationFieldValue_' + REPLACE(CAST(@SectionId As varchar(64)),'-','') + ' AFV
			JOIN relApplicationSectionValue ASV
			ON ASV.uidId = AFV.uidApplicationSectionValueId
			AND ASV.uidApplicationId IN(SELECT uidApplicationID FROM #tmpReport_HiredCandidate)
			WHERE AFV.uidApplicationFieldId = @uidFIDParam'
		END
		
		IF @enmDataType = 5
		BEGIN
			SELECT @nvcSql = 'INSERT INTO #tmpTFDupValues
			(FN, RelId, Value)
			
			SELECT @intAppFieldNoParam, ASV.uidApplicationId, CONVERT(nvarchar(max), AFV.dteDateValue, 126)
			FROM neptune_dynamic_objects.relApplicationFieldValue_' + REPLACE(CAST(@SectionId As varchar(64)),'-','') + ' AFV
			JOIN relApplicationSectionValue ASV
			ON ASV.uidId = AFV.uidApplicationSectionValueId
			AND ASV.uidApplicationId IN(SELECT uidApplicationID FROM #tmpReport_HiredCandidate)
			WHERE AFV.uidApplicationFieldId = @uidFIDParam'
		END
		
		IF @enmDataType = 6
		BEGIN
			SELECT @nvcSql = 'INSERT INTO #tmpTFDupValues
			(FN, RelId, Value)
			
			SELECT @intAppFieldNoParam, ASV.uidApplicationId, RDI.nvcName 
			FROM neptune_dynamic_objects.relApplicationFieldValue_' + REPLACE(CAST(@SectionId As varchar(64)),'-','') + ' AFV
			JOIN relApplicationSectionValue ASV
			ON ASV.uidId = AFV.uidApplicationSectionValueId
			AND ASV.uidApplicationId IN(SELECT uidApplicationID FROM #tmpReport_HiredCandidate)
			JOIN refReferenceDataItem RDI
			ON AFV.uidIdValue = RDI.uidId 
			WHERE AFV.uidApplicationFieldId = @uidFIDParam'					
		END
		
		EXEC sp_executeSql @nvcSql,
		@nvcParameterDefinition,
		@uidFIDParam = @uidFieldId,
		@intAppFieldNoParam = @intCount
		
		SELECT @intCount = @intCount + 1
		
	END
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

CREATE TABLE #tmpAR_Result (uidApplicationId uniqueidentifier)

SELECT @nvcSql = 'ALTER TABLE #tmpAR_Result ADD '
SELECT @nvcSql = @nvcSql + REPLACE(FName, 'IfYes', '')
+ ' NVARCHAR(MAX) NULL, ' FROM (SELECT FName FROM #tmpTemplateFields) As #tmpDistinctCandidateFields1

SELECT @nvcSql = LEFT(@nvcSql, LEN(@nvcSql)-1)

EXEC sp_executeSql @nvcSql

SET @intCount = 1

IF (SELECT COUNT(*) FROM #tmpTFValues) > 0
BEGIN
	SELECT @nvcSql = 'INSERT INTO #tmpAR_Result
	SELECT A.uidID, '

	WHILE @intCount <= (SELECT COUNT(*) FROM #tmpTemplateFields)
	BEGIN
		SELECT @nvcSql = @nvcSql + ' 
		ATFV'+ CAST(@intCount as nvarchar) + '.Value AS V_'+ CAST(@intCount as nvarchar) + ','
		
		SELECT @intCount = @intCount + 1
		
	END

	SET @intCount = 1

	SELECT @nvcSql = LEFT(@nvcSql, LEN(@nvcSql)-1) + ' 
	FROM relApplication A
	LEFT JOIN #tmpTFValues ATFV' + CAST(@intCount as nvarchar) + ' ON A.uidId = ATFV' + CAST(@intCount as nvarchar) + '.RelId AND ATFV' + CAST(@intCount as nvarchar) + '.FN = ' + CAST(@intCount as nvarchar)

	SELECT @intCount = @intCount + 1

	WHILE @intCount <= (SELECT COUNT(*) FROM #tmpTemplateFields)
	BEGIN
		SELECT @nvcSql = @nvcSql + ' 
		LEFT JOIN #tmpTFValues ATFV' + CAST(@intCount as nvarchar) + ' ON A.uidId = ATFV' + CAST(@intCount as nvarchar) + '.RelId AND ATFV' + CAST(@intCount as nvarchar) + '.FN = ' + CAST(@intCount as nvarchar)

		SELECT @intCount = @intCount + 1
		
	END

	SELECT @nvcSql = @nvcSql + ' WHERE A.uidId IN(SELECT uidApplicationID FROM #tmpReport_HiredCandidate)'

	EXEC sp_executeSql @nvcSql
END

TRUNCATE TABLE #tmpTemplateFields

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

SET @intCount = 1

SELECT @nvcParameterDefinition = '
		@uidFIDParam uniqueidentifier,
		@intFieldNumberParam int'

TRUNCATE TABLE #tmpTFDupValues

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
		AND RSV.uidRequisitionId IN(SELECT uidRequisitionId FROM #tmpReport_HiredCandidate)
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
		AND RSV.uidRequisitionId IN(SELECT uidRequisitionId FROM #tmpReport_HiredCandidate)
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
		AND RSV.uidRequisitionId IN(SELECT uidRequisitionId FROM #tmpReport_HiredCandidate)
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
		AND RSV.uidRequisitionId IN(SELECT uidRequisitionId FROM #tmpReport_HiredCandidate)
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
		AND RSV.uidRequisitionId IN(SELECT uidRequisitionId FROM #tmpReport_HiredCandidate)
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
		AND RSV.uidRequisitionId IN(SELECT uidRequisitionId FROM #tmpReport_HiredCandidate)
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
		AND RSV.uidRequisitionId IN(SELECT uidRequisitionId FROM #tmpReport_HiredCandidate)
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

TRUNCATE TABLE #tmpTFValues

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

	SELECT @nvcSql = @nvcSql + ' WHERE R.uidId IN(SELECT uidRequisitionId FROM #tmpReport_HiredCandidate)'

	EXEC sp_executeSql @nvcSql
END

TRUNCATE TABLE #tmpTemplateFields;

INSERT INTO #tmpTemplateFields
(
	FName,
	FieldId,
	SectionId,
	SortOrder,
	DataType
)
SELECT CF.nvcName, CF.uidId, CF.uidCandidateSectionId, CF.intSortOrder, CF.enmDataType 
FROM refCandidateField CF
JOIN relCandidateTemplateField CTF
ON CF.uidId = CTF.uidCandidateFieldId 
JOIN relCandidateTemplateSection CTS
ON CTF.uidCandidateTemplateSectionId = CTS.uidId 
AND CTS.uidCandidateTemplateId = 
(
	SELECT uidId FROM refCandidateTemplate WHERE nvcName = 'Candidate Report Fields'
)
ORDER BY CF.intSortOrder 

WHILE (SELECT MAX(PATINDEX('%[^a-zA-Z0-9]%', FName)) FROM #tmpTemplateFields) > 0
BEGIN

	UPDATE #tmpTemplateFields 
	SET FName = REPLACE(FName, SUBSTRING(FName, PATINDEX('%[^a-zA-Z0-9]%', FName), 1), '')
	
	
	IF (SELECT MAX(PATINDEX('%[^a-zA-Z0-9]%', FName)) FROM #tmpTemplateFields) = 0
		BREAK
	ELSE
		CONTINUE
END

SET @intCount = 1

SELECT @nvcParameterDefinition = '
		@uidFIDParam uniqueidentifier,
		@intFNParam int'

TRUNCATE TABLE #tmpTFDupValues

BEGIN	
	WHILE @intCount <= (SELECT COUNT(*) FROM #tmpTemplateFields)
	BEGIN
		SELECT @nvcFieldName = CTF.FName,
		@enmDataType = CTF.DataType,
		@uidFieldId = CTF.FieldId,
		@SectionId =  SectionId
		FROM #tmpTemplateFields CTF
		WHERE CTF.ID = @intCount   
		
		
		IF @enmDataType = 0
		BEGIN
			SELECT @nvcSql = 'INSERT INTO #tmpTFDupValues
			(FN, RelId, Value)
			
			SELECT @intFNParam, CSV.uidCandidateId, CFV.nvcStringValue
			FROM neptune_dynamic_objects.relCandidateFieldValue_' + REPLACE(CAST(@SectionId As varchar(64)),'-','') + ' CFV
			JOIN relCandidateSectionValue CSV
			ON CSV.uidId = CFV.uidCandidateSectionValueId
			AND CSV.uidCandidateId IN(SELECT uidCandidateId FROM #tmpReport_HiredCandidate)
			WHERE CFV.uidCandidateFieldId = @uidFIDParam'
		END
				
		IF @enmDataType = 1
		BEGIN
			SELECT @nvcSql = 'INSERT INTO #tmpTFDupValues
			(FN, RelId, Value)
			
			SELECT @intFNParam, CSV.uidCandidateId, CAST(CFV.nvcStringValue as nvarchar(max))
			FROM neptune_dynamic_objects.relCandidateFieldValue_' + REPLACE(CAST(@SectionId As varchar(64)),'-','') + ' CFV
			JOIN relCandidateSectionValue CSV
			ON CSV.uidId = CFV.uidCandidateSectionValueId
			AND CSV.uidCandidateId IN(SELECT uidCandidateId FROM #tmpReport_HiredCandidate)
			WHERE CFV.uidCandidateFieldId = @uidFIDParam'			
		END
		
		IF @enmDataType = 2
		BEGIN
			SELECT @nvcSql = 'INSERT INTO #tmpTFDupValues
			(FN, RelId, Value)
			
			SELECT @intFNParam, CSV.uidCandidateId, CAST(CFV.intIntValue as nvarchar(max))
			FROM neptune_dynamic_objects.relCandidateFieldValue_' + REPLACE(CAST(@SectionId As varchar(64)),'-','') + ' CFV
			JOIN relCandidateSectionValue CSV
			ON CSV.uidId = CFV.uidCandidateSectionValueId
			AND CSV.uidCandidateId IN(SELECT uidCandidateId FROM #tmpReport_HiredCandidate)
			WHERE CFV.uidCandidateFieldId = @uidFIDParam'		
		END
		
		IF @enmDataType = 3
		BEGIN
			SELECT @nvcSql = 'INSERT INTO #tmpTFDupValues
			(FN, RelId, Value)
			
			SELECT @intFNParam, CSV.uidCandidateId, CAST(CFV.fltFloatValue as nvarchar(max))
			FROM neptune_dynamic_objects.relCandidateFieldValue_' + REPLACE(CAST(@SectionId As varchar(64)),'-','') + ' CFV
			JOIN relCandidateSectionValue CSV
			ON CSV.uidId = CFV.uidCandidateSectionValueId
			AND CSV.uidCandidateId IN(SELECT uidCandidateId FROM #tmpReport_HiredCandidate)
			WHERE CFV.uidCandidateFieldId = @uidFIDParam'				
		END
		
		IF @enmDataType = 4
		BEGIN
			SELECT @nvcSql = 'INSERT INTO #tmpTFDupValues
			(FN, RelId, Value)
			
			SELECT @intFNParam, CSV.uidCandidateId, CAST(CFV.bitBitValue as nvarchar(max))
			FROM neptune_dynamic_objects.relCandidateFieldValue_' + REPLACE(CAST(@SectionId As varchar(64)),'-','') + ' CFV
			JOIN relCandidateSectionValue CSV
			ON CSV.uidId = CFV.uidCandidateSectionValueId
			AND CSV.uidCandidateId IN(SELECT uidCandidateId FROM #tmpReport_HiredCandidate)
			WHERE CFV.uidCandidateFieldId = @uidFIDParam'
		END
		
		IF @enmDataType = 5
		BEGIN
			SELECT @nvcSql = 'INSERT INTO #tmpTFDupValues
			(FN, RelId, Value)
			
			SELECT @intFNParam, CSV.uidCandidateId, CONVERT(nvarchar(max), CFV.dteDateValue, 126)
			FROM neptune_dynamic_objects.relCandidateFieldValue_' + REPLACE(CAST(@SectionId As varchar(64)),'-','') + ' CFV
			JOIN relCandidateSectionValue CSV
			ON CSV.uidId = CFV.uidCandidateSectionValueId
			AND CSV.uidCandidateId IN(SELECT uidCandidateId FROM #tmpReport_HiredCandidate)
			WHERE CFV.uidCandidateFieldId = @uidFIDParam'
		END
		
		IF @enmDataType = 6
		BEGIN
			SELECT @nvcSql = 'INSERT INTO #tmpTFDupValues
			(FN, RelId, Value)
			
			SELECT @intFNParam, CSV.uidCandidateId, RDI.nvcName 
			FROM neptune_dynamic_objects.relCandidateFieldValue_' + REPLACE(CAST(@SectionId As varchar(64)),'-','') + ' CFV
			JOIN relCandidateSectionValue CSV
			ON CSV.uidId = CFV.uidCandidateSectionValueId
			AND CSV.uidCandidateId IN(SELECT uidCandidateId FROM #tmpReport_HiredCandidate)
			JOIN refReferenceDataItem RDI
			ON CFV.uidIdValue = RDI.uidId 
			WHERE CFV.uidCandidateFieldId = @uidFIDParam'					
		END
		
		EXEC sp_executeSql @nvcSql,
		@nvcParameterDefinition,
		@uidFIDParam = @uidFieldId,
		@intFNParam = @intCount
		
		SELECT @intCount = @intCount + 1
		
	END
END
TRUNCATE TABLE #tmpTFValues

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

CREATE TABLE #tmpCR_Result (uidCandidateId uniqueidentifier)

SELECT @nvcSql = 'ALTER TABLE #tmpCR_Result ADD '
SELECT @nvcSql = @nvcSql + REPLACE(FName, 'IfYes', '')
+ ' NVARCHAR(MAX) NULL, ' FROM (SELECT FName FROM #tmpTemplateFields) As #tmpDistinctCandidateFields1

SELECT @nvcSql = LEFT(@nvcSql, LEN(@nvcSql)-1)

EXEC sp_executeSql @nvcSql

SET @intCount = 1

IF (SELECT COUNT(*) FROM #tmpTFValues) > 0
BEGIN
	SELECT @nvcSql = 'INSERT INTO #tmpCR_Result
	SELECT C.uidID, '

	WHILE @intCount <= (SELECT COUNT(*) FROM #tmpTemplateFields)
	BEGIN
		SELECT @nvcSql = @nvcSql + ' 
		CTFV'+ CAST(@intCount as nvarchar) + '.Value AS V_'+ CAST(@intCount as nvarchar) + ','
		
		SELECT @intCount = @intCount + 1
		
	END

	SET @intCount = 1

	SELECT @nvcSql = LEFT(@nvcSql, LEN(@nvcSql)-1) + ' 
	FROM dtlCandidate C
	LEFT JOIN #tmpTFValues CTFV' + CAST(@intCount as nvarchar) + ' ON C.uidId = CTFV' + CAST(@intCount as nvarchar) + '.RelId AND CTFV' + CAST(@intCount as nvarchar) + '.FN = ' + CAST(@intCount as nvarchar)

	SELECT @intCount = @intCount + 1

	WHILE @intCount <= (SELECT COUNT(*) FROM #tmpTemplateFields)
	BEGIN
		SELECT @nvcSql = @nvcSql + ' 
		LEFT JOIN #tmpTFValues CTFV' + CAST(@intCount as nvarchar) + ' ON C.uidId = CTFV' + CAST(@intCount as nvarchar) + '.RelId AND CTFV' + CAST(@intCount as nvarchar) + '.FN = ' + CAST(@intCount as nvarchar)

		SELECT @intCount = @intCount + 1
		
	END

	SELECT @nvcSql = @nvcSql + ' WHERE C.uidId IN(SELECT uidCandidateId FROM #tmpReport_HiredCandidate)'

	EXEC sp_executeSql @nvcSql
END

SELECT RHC.nvcJobReferenceCode AS 'Job Reference #',
RHC.nvcRequisitionJobStatus AS 'Job Status',
RHC.nvcJobCreator AS 'Job Creator',
RHC.nvcJobOwner AS 'Job Owner',
RHC.dteCreationDate AS 'Date Job Created',
RHC.dteJobFirstAdvertised AS 'Date Job First Advertised',
RHC.intDaysAdvertised AS 'Days Job Advertised',
RHC.intDaysReview AS 'Days Job In Review',
RHC.intDaysActive AS 'Days Job Active',
RHC.dteJobDateArchived AS 'Date Job Archived',
RHC.intTotalJobTat AS 'Total Job TAT in Days',
RHC.nvcRegistrationWebsite AS 'Registration Website',
RHC.dteCandidateRegistrationDate AS 'Registration Date',
RHC.dteCandidateLastAccessedDate AS 'Last Accessed Date',
RHC.dteApplicationDate AS 'Application Date',
RHC.nvcApplicationStatus AS 'Application Status',
RHC.dteHiredDate AS 'Hired Date',
RHC.nvcHiredBy AS 'Hired By',
RHC.intApplicantTat AS 'Applicant TAT',
RHC.intTimeToHire AS 'Time To Hire',
RHC.nvcOrigin AS 'Application Origin',
RHC.nvcAgencyName AS 'Agency Name',
ARR.*,
RRR.*, 
RHC.nvcCandidateEmail AS 'Email',
RHC.nvcCandidateMobileNumber AS 'Cell/Mobile Number',
CRR.*
FROM #tmpReport_HiredCandidate RHC
LEFT JOIN #tmpAR_Result ARR
on RHC.uidApplicationId = ARR.uidApplicationId
LEFT JOIN #tmpRR_Result RRR
ON RHC.uidRequisitionId = RRR.uidRequisitionId
LEFT JOIN #tmpCR_Result CRR
ON RHC.uidCandidateId = CRR.uidCandidateId
ORDER BY RHC.nvcJobReferenceCode

DROP TABLE #tmpReport_HiredCandidate
DROP TABLE #tmpRequisitionWorkflowstepDates
DROP TABLE #tmpRequisitionWorkflowstepDatesTotals
DROP TABLE #tmpTemplateFields
DROP TABLE #tmpTFDupValues
DROP TABLE #tmpTFValues
DROP TABLE #tmpAR_Result
DROP TABLE #tmpRR_Result
DROP TABLE #tmpCR_Result
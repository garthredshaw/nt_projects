SET NOCOUNT ON;

DECLARE @StartDate nvarchar(14) = DATENAME(DAY, SUBSTRING('@FromDate', 7, 4) + '-' + SUBSTRING('@FromDate', 4, 2) + '-' + SUBSTRING('@FromDate', 1, 2)) 
+ ' ' + DATENAME(MONTH,SUBSTRING('@FromDate', 7, 4) + '-' + SUBSTRING('@FromDate', 4, 2) + '-' + SUBSTRING('@FromDate', 1, 2)) 
+ ' ' + DATENAME(YEAR,SUBSTRING('@FromDate', 7, 4) + '-' + SUBSTRING('@FromDate', 4, 2) + '-' + SUBSTRING('@FromDate', 1, 2))

DECLARE @EndDate nvarchar(14) = DATENAME(DAY, SUBSTRING('@ToDate', 7, 4) + '-' + SUBSTRING('@ToDate', 4, 2) + '-' + SUBSTRING('@ToDate', 1, 2)) 
+ ' ' + DATENAME(MONTH,SUBSTRING('@ToDate', 7, 4) + '-' + SUBSTRING('@ToDate', 4, 2) + '-' + SUBSTRING('@ToDate', 1, 2)) 
+ ' ' + DATENAME(YEAR,SUBSTRING('@ToDate', 7, 4) + '-' + SUBSTRING('@ToDate', 4, 2) + '-' + SUBSTRING('@ToDate', 1, 2))


SELECT APP.uidId AS uidApplicationId
,AC.uidAgencyId 
,APP.uidCandidateId
,APP.uidRequisitionId
,AWS.nvcName AS nvcStatus
,APP.dteApplicationDate
INTO #tmpAgencyApplications
FROM relApplication APP
LEFT JOIN refApplicationWorkflowStep AWS ON APP.uidApplicationWorkflowStepId = AWS.uidId
JOIN dtlCandidate C ON APP.uidCandidateId = C.uidId 
JOIN relAgencyCandidate AC ON C.uidId = AC.uidCandidateId
WHERE CAST(FLOOR(CAST(APP.dteApplicationDate AS FLOAT))AS DATETIME) >= @StartDate
AND CAST(FLOOR(CAST(APP.dteApplicationDate AS FLOAT))AS DATETIME) <= @EndDate


SELECT AC.uidAgencyId AS uidAgencyId,
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
WHERE APP.uidId IN
(
	SELECT uidApplicationId
	FROM #tmpAgencyApplications
) 
GROUP BY AC.uidAgencyId, RDT.nvcTranslation 

SELECT nvcName AS 'Agency Name',
(
	SELECT COUNT(uidId)
	FROM relAgencyRequisition 
	WHERE uidAgencyId = dtlAgency.uidId
) AS 'Total Allowable Jobs',
(
	SELECT SUM(intMaxApplications)
	FROM relAgencyRequisition 
	WHERE uidAgencyId = dtlAgency.uidId	
) AS 'Total Allowable Apps',
(
	SELECT COUNT(AA.uidApplicationId) 
	FROM #tmpAgencyApplications AA
	WHERE AA.uidAgencyId = dtlAgency.uidId 
) AS 'Total Apps Submitted',
(
	SELECT COUNT(AWH.uidId)
	FROM relApplicationWorkflowHistory AWH
	JOIN #tmpAgencyApplications AA
	ON AWH.uidApplicationId = AA.uidApplicationId 
	JOIN dtlCandidate C1
	ON AA.uidCandidateId = C1.uidId 
	JOIN relAgencyCandidate AC1
	ON C1.uidId = AC1.uidCandidateId 
	WHERE uidApplicationWorkflowPathId IN 
	(
		SELECT uidId FROM relApplicationWorkflowPath WHERE nvcName = 'Unprocessed-Regretted'
	)
	AND AC1.uidAgencyId = dtlAgency.uidId 
) AS 'Total Apps moved from Unprocessed to Regret',
(	
	SELECT COUNT(uidApplicationId) 
	FROM #tmpAgencyApplications 
	WHERE uidAgencyId = dtlAgency.uidId
	AND nvcStatus = 'Unprocessed'
) AS 'Count Unprocessed',
(	
	SELECT COUNT(uidApplicationId) 
	FROM #tmpAgencyApplications 
	WHERE uidAgencyId = dtlAgency.uidId
	AND nvcStatus = 'Longlist'
) AS 'Count Longlist',
(	
	SELECT COUNT(uidApplicationId) 
	FROM #tmpAgencyApplications 
	WHERE uidAgencyId = dtlAgency.uidId
	AND nvcStatus = 'Shortlist'
) AS 'Count Shortlist',
(	
	SELECT COUNT(uidApplicationId) 
	FROM #tmpAgencyApplications 
	WHERE uidAgencyId = dtlAgency.uidId
	AND nvcStatus = 'Interview'
) AS 'Count Interview',
(	
	SELECT COUNT(uidApplicationId) 
	FROM #tmpAgencyApplications 
	WHERE uidAgencyId = dtlAgency.uidId
	AND nvcStatus = 'Under Review'
) AS 'Count Under Review',
(	
	SELECT COUNT(uidApplicationId) 
	FROM #tmpAgencyApplications 
	WHERE uidAgencyId = dtlAgency.uidId
	AND nvcStatus = 'Offer Made'
) AS 'Count Offer Made',
(	
	SELECT COUNT(uidApplicationId) 
	FROM #tmpAgencyApplications 
	WHERE uidAgencyId = dtlAgency.uidId
	AND nvcStatus = 'Hired'
) AS 'Count Hired',
(	
	SELECT COUNT(uidApplicationId) 
	FROM #tmpAgencyApplications 
	WHERE uidAgencyId = dtlAgency.uidId
	AND nvcStatus = 'Regretted'
) AS 'Count Regretted',
(	
	SELECT COUNT(uidApplicationId) 
	FROM #tmpAgencyApplications 
	WHERE uidAgencyId = dtlAgency.uidId
	AND nvcStatus = 'Declined'
) AS 'Count Declined',
(	
	SELECT COUNT(uidApplicationId) 
	FROM #tmpAgencyApplications 
	WHERE uidAgencyId = dtlAgency.uidId
	AND nvcStatus = 'Withdrawn'
) AS 'Count Withdrawn',
(
	SELECT intCountOfApplications 
	FROM #tmpAgencyApplicationsByRace
	WHERE nvcRace = 'Asian'
	AND uidAgencyId = dtlAgency.uidId
) AS 'Race Count - Asian',
(
	SELECT intCountOfApplications 
	FROM #tmpAgencyApplicationsByRace
	WHERE nvcRace = 'Black'
	AND uidAgencyId = dtlAgency.uidId
) AS 'Race Count - Black',
(
	SELECT intCountOfApplications 
	FROM #tmpAgencyApplicationsByRace
	WHERE nvcRace = 'Coloured'
	AND uidAgencyId = dtlAgency.uidId
) AS 'Race Count - Coloured',
(
	SELECT intCountOfApplications 
	FROM #tmpAgencyApplicationsByRace
	WHERE nvcRace = 'Indian / Asian'
	AND uidAgencyId = dtlAgency.uidId
) AS 'Race Count - Indian / Asian',
(
	SELECT intCountOfApplications 
	FROM #tmpAgencyApplicationsByRace
	WHERE nvcRace = 'White'
	AND uidAgencyId = dtlAgency.uidId
) AS 'Race Count - White'
FROM dtlAgency
WHERE uidId IN
(
	SELECT uidAgencyId FROM #tmpAgencyApplications
)
ORDER BY nvcName 

DROP TABLE #tmpAgencyApplications
DROP TABLE #tmpAgencyApplicationsByRace
-- Candidates - Candidates By Gender By Race.sql

SET NOCOUNT ON;

-- REMOVE NEXT FOUR LINES BEFORE DEPLOYING TO SYSTEM
DECLARE @uidLanguageId uniqueidentifier = '4850874D-715B-4950-B188-738E2FFC1520'

DECLARE @nvcSql nvarchar(4000)  
DECLARE @uidColumnsFieldId uniqueidentifier 
DECLARE @uidRowsFieldId uniqueidentifier  

SELECT @uidColumnsFieldId = '9119C19F-1736-4D23-8723-F856D741F326' 
SELECT @uidRowsFieldId = '37EA1626-39FC-4B1E-83C1-4EDFE03D66E8'  

DECLARE @uidColumnsSectionId uniqueidentifier 
DECLARE @uidRowsSectionId uniqueidentifier  

SELECT @uidColumnsSectionId = uidCandidateSectionId 
FROM refCandidateField 
WHERE uidId = @uidColumnsFieldId 

SELECT @uidRowsSectionId = uidCandidateSectionId 
FROM refCandidateField 
WHERE uidId = @uidRowsFieldId  

CREATE TABLE #tmpCanadidateRace
(
	uidCandidateId uniqueidentifier,
	nvcGender nvarchar(MAX) NULL,
	nvcRace nvarchar(MAX) NULL
)

SELECT @nvcSql = 'INSERT INTO #tmpCanadidateRace (uidCandidateId, nvcGender, nvcRace)

SELECT C.uidid, RIT_G.nvcTranslation as Gender,   
RIT_R.nvcTranslation as Race  
FROM dtlCandidate C  
JOIN relCandidateSectionValue CSV ON CSV.uidCandidateId = C.uidId  
JOIN neptune_dynamic_objects.relCandidateFieldValue_' + REPLACE(CAST(@uidColumnsSectionId as nvarchar(50)), '-', '') + ' CFV_G ON CFV_G.uidCandidateSectionValueId = CSV.uidId AND CFV_G.uidCandidateFieldId = ''' + CAST(@uidColumnsFieldId as nvarchar(50)) + '''  
JOIN relReferenceDataTranslation RIT_G ON RIT_G.uidReferenceDataItemId = CFV_G.uidIdValue AND RIT_G.uidLanguageId = @uidLIdParam  
JOIN neptune_dynamic_objects.relCandidateFieldValue_' + REPLACE(CAST(@uidRowsSectionId as nvarchar(50)), '-', '') + ' CFV_R ON CFV_R.uidCandidateSectionValueId = CSV.uidId AND CFV_R.uidCandidateFieldId = ''' + CAST(@uidRowsFieldId as nvarchar(50)) + '''  
JOIN relReferenceDataTranslation RIT_R ON RIT_R.uidReferenceDataItemId = CFV_R.uidIdValue AND RIT_R.uidLanguageId = @uidLIdParam '

EXEC sp_executeSql @nvcSql, N'@uidLIdParam uniqueidentifier', 
@uidLIdParam = @uidLanguageId

SELECT CR.nvcGender AS Gender, CR.nvcRace AS Race, COUNT(*) AS Num
INTO #tmpResults
FROM dtlCandidate C
LEFT JOIN #tmpCanadidateRace CR ON C.uidid = CR.uidCandidateId 
GROUP BY CR.nvcGender, CR.nvcRace

UPDATE #tmpResults 
SET Gender = 'Unknown'
WHERE Gender IS NULL

UPDATE #tmpResults 
SET Race = 'Unknown'
WHERE Race IS NULL

 SELECT * FROM 
(  
	SELECT * FROM #tmpResults
) as SourceData 
PIVOT 
(  
	SUM(Num) FOR Gender IN 
	([Male],[Female],[Unknown]) ) as PivotData

DROP TABLE #tmpCanadidateRace
DROP TABLE #tmpResults
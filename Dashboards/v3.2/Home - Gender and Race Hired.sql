-- Home - Gender and Race Hired.sql
-- Requirements
-- ============
-- Count (just once) any application that has been in RWF step = Hired
-- Data context = user specific based on Job access level (AllRequisitions | AsssignedRequisitions)


SET NOCOUNT ON;  

-- REMOVE NEXT THREE LINES BEFORE DEPLOYING TO SYSTEM
DECLARE @uidLanguageId uniqueidentifier = '4850874D-715B-4950-B188-738E2FFC1520'
DECLARE @uidUserId uniqueidentifier = 'F765E20E-B816-46CC-B0EC-5BB9B106C7F9' --'3427F1F9-B3C3-4A14-9579-C82F5BAD73AF' --Ian
DECLARE @intPeriod int = 12

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

--#tmpUserApplicationWorkflowSteps 
SELECT uidId  
INTO #tmpUserApplicationWorkflowSteps 
FROM refApplicationWorkflowStep 
WHERE uidId = 'D48D37A6-FF45-4A2A-B6C4-C87FE3123809' -- Hired
--OR uidId = '9AE8ECCF-5C79-49C8-BD38-E548401CD56C'     
AND uidId IN
(
	SELECT uidApplicationWorkflowStepId 
	FROM relApplicationWorkflowStepPermission 
	WHERE uidRoleId IN
	(SELECT uidRoleId FROM relRoleMembership WHERE uidUserId = @uidUserId)
)

--#tmpUserApplications
SELECT uidId, uidCandidateId INTO #tmpUserApplications 
FROM relApplication 
WHERE uidApplicationWorkflowStepId IN  
(
	SELECT uidId FROM #tmpUserApplicationWorkflowSteps
)
OR uidRequisitionId IN
(
	SELECT uidRequisitionId 
	FROM relRecruiterRequisition 
	WHERE uidRecruiterId IN 
	(
		SELECT uidId 
		FROM dtlRecruiter 
		WHERE uidUserId = @uidUserId
	)
)	
		
SELECT @nvcSql = ' SELECT * FROM 
(  
	SELECT RIT_G.nvcTranslation as Gender,   
	RIT_R.nvcTranslation as Race,   
	COUNT(*) as Num  
	FROM dtlCandidate C  
	JOIN relCandidateSectionValue CSV ON CSV.uidCandidateId = C.uidId  
	JOIN neptune_dynamic_objects.relCandidateFieldValue_' + REPLACE(CAST(@uidColumnsSectionId as nvarchar(50)), '-', '') + ' CFV_G ON CFV_G.uidCandidateSectionValueId = CSV.uidId AND CFV_G.uidCandidateFieldId = ''' + CAST(@uidColumnsFieldId as nvarchar(50)) + '''  
	JOIN relReferenceDataTranslation RIT_G ON RIT_G.uidReferenceDataItemId = CFV_G.uidIdValue AND RIT_G.uidLanguageId = @uidLIdParam  
	JOIN neptune_dynamic_objects.relCandidateFieldValue_' + REPLACE(CAST(@uidRowsSectionId as nvarchar(50)), '-', '') + ' CFV_R ON CFV_R.uidCandidateSectionValueId = CSV.uidId AND CFV_R.uidCandidateFieldId = ''' + CAST(@uidRowsFieldId as nvarchar(50)) + '''  
	JOIN relReferenceDataTranslation RIT_R ON RIT_R.uidReferenceDataItemId = CFV_R.uidIdValue AND RIT_R.uidLanguageId = @uidLIdParam  
	WHERE  
	(   
		C.uidId IN    
		(    
			SELECT uidCandidateId FROM #tmpUserApplications  
		)  
	)  
	GROUP BY RIT_G.nvcTranslation, RIT_R.nvcTranslation 
) as SourceData 
PIVOT 
(  
	SUM(Num) FOR Gender IN 
	('   
	SELECT @nvcSql = @nvcSql + '[' + RT.nvcTranslation + '],' 
	FROM refCandidateField CF 
	JOIN refReferenceDataSection RS ON CF.uidReferenceDataSectionId = RS.uidId JOIN refReferenceDataItem RI ON RS.uidId = RI.uidReferenceDataSectionId 
	JOIN relReferenceDataTranslation RT ON RI.uidId = RT.uidReferenceDataItemId AND RT.uidLanguageId = @uidLanguageId 
	WHERE CF.uidId = @uidColumnsFieldId   
	SELECT @nvcSql = LEFT(@nvcSql, LEN(@nvcSql)-1) + ') ) as PivotData'  
	
	--PRINT @nvcSql   
	
	EXEC sp_executeSql @nvcSql, N'@uidLIdParam uniqueidentifier', 
	@uidLIdParam = @uidLanguageId
	
DROP TABLE #tmpUserApplicationWorkflowSteps 
DROP TABLE #tmpUserApplications
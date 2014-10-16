SET NOCOUNT ON;

DECLARE @nvcSql nvarchar(4000)

DECLARE @uidColumnsFieldId uniqueidentifier
DECLARE @uidRowsFieldId uniqueidentifier

SELECT @uidColumnsFieldId = '37EA1626-39FC-4B1E-83C1-4EDFE03D66E8'
SELECT @uidRowsFieldId = '1b34ed6b-c148-4193-8138-56987b576680'

DECLARE @uidColumnsSectionId uniqueidentifier
DECLARE @uidRowsSectionId uniqueidentifier

SELECT @uidColumnsSectionId = uidCandidateSectionId FROM refCandidateField WHERE uidId = @uidColumnsFieldId
SELECT @uidRowsSectionId = uidCandidateSectionId FROM refCandidateField WHERE uidId = @uidRowsFieldId


SELECT @nvcSql = '
SELECT
	*
FROM
(
	SELECT
		RIT_G.nvcTranslation as Race, RIT_R.nvcTranslation as Expertise, COUNT(*) as Num
	FROM
		dtlCandidate C
	JOIN
		relCandidateSectionValue CSV ON CSV.uidCandidateId = C.uidId
		
	JOIN
		neptune_dynamic_objects.relCandidateFieldValue_' + REPLACE(CAST(@uidColumnsSectionId as nvarchar(50)), '-', '') + ' CFV_G ON CFV_G.uidCandidateSectionValueId = CSV.uidId AND CFV_G.uidCandidateFieldId = ''' + CAST(@uidColumnsFieldId as nvarchar(50)) + '''
	JOIN
		relReferenceDataTranslation RIT_G ON RIT_G.uidReferenceDataItemId = CFV_G.uidIdValue AND RIT_G.uidLanguageId = @uidLIdParam

	JOIN
		neptune_dynamic_objects.relCandidateFieldValue_' + REPLACE(CAST(@uidRowsSectionId as nvarchar(50)), '-', '') + ' CFV_R ON CFV_R.uidCandidateSectionValueId = CSV.uidId AND CFV_R.uidCandidateFieldId = ''' + CAST(@uidRowsFieldId as nvarchar(50)) + '''
	JOIN
		relReferenceDataTranslation RIT_R ON RIT_R.uidReferenceDataItemId = CFV_R.uidIdValue AND RIT_R.uidLanguageId = @uidLIdParam

	WHERE
	(
		C.uidWebsiteId IN (SELECT uidWebsiteId FROM relWebsitePermission WHERE enmPermission = 1 AND uidRoleId IN (SELECT uidRoleId FROM relRoleMembership WHERE uidUserId = @uidUIdParam))
	)

	GROUP BY
		RIT_G.nvcTranslation, RIT_R.nvcTranslation
) as SourceData
PIVOT
(
	SUM(Num)
	FOR	Race
	IN ('
	
SELECT
	@nvcSql = @nvcSql + '[' + RT.nvcTranslation + '],'
FROM	
	refCandidateField CF
JOIN
	refReferenceDataSection RS ON CF.uidReferenceDataSectionId = RS.uidId
JOIN
	refReferenceDataItem RI ON RS.uidId = RI.uidReferenceDataSectionId
JOIN
	relReferenceDataTranslation RT ON RI.uidId = RT.uidReferenceDataItemId AND RT.uidLanguageId = @uidLanguageId
WHERE
	CF.uidId = @uidColumnsFieldId
	
SELECT @nvcSql = LEFT(@nvcSql, LEN(@nvcSql)-1) + ')
) as PivotData'

PRINT @nvcSql
	
EXEC sp_executeSql @nvcSql, N'@uidLIdParam uniqueidentifier, @uidUIdParam uniqueidentifier', @uidLIdParam = @uidLanguageId, @uidUIdParam = @uidUserId
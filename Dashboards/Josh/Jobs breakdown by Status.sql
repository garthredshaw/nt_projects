--Jobs breakdown by Status
SET NOCOUNT ON;
	
SELECT * INTO #tmpUserRequisitionWorkflowSteps
FROM refRequisitionWorkflowStep
WHERE uidId IN 
(
	SELECT uidRequisitionWorkflowStepId 
	FROM relRequisitionWorkflowStepPermission 
	WHERE uidRoleId IN (SELECT uidRoleId FROM relRoleMembership WHERE uidUserId = '181D1924-2095-49E7-80B4-620538B8D4AF') 
)
AND uidId <> '67A567F0-196B-4868-BE56-CCD2800C3051'
AND uidId <> '5CFBBA0A-EAB9-45E5-A9AF-8AF292B0AAD4'

DECLARE @tmpRequisitionWebsitesPublishedBeforeRange TABLE 
(
	uidId uniqueidentifier,
	uidRequisitionId uniqueidentifier,
	uidWebsiteId uniqueidentifier,
	dteStartDate datetime,
	dteEndDate datetime,
	bitEndDateIndefinate bit,
	enmCommunicationStatus int
)	


DECLARE @tmpRequisitionWebsitesPublishedDuring TABLE 
(
	uidId uniqueidentifier,
	uidRequisitionId uniqueidentifier,
	uidWebsiteId uniqueidentifier,
	dteStartDate datetime,
	dteEndDate datetime,
	bitEndDateIndefinate bit,
	enmCommunicationStatus int
)	


DECLARE @tmpRequisitionWebsitesPublishedAfterRange TABLE 
(
	uidId uniqueidentifier,
	uidRequisitionId uniqueidentifier,
	uidWebsiteId uniqueidentifier,
	dteStartDate datetime,
	dteEndDate datetime,
	bitEndDateIndefinate bit,
	enmCommunicationStatus int
)		


DECLARE @dtePublishedDateFromFilter datetime
DECLARE @dtePublishedDateToFilter datetime

SELECT @dtePublishedDateFromFilter = DATEADD(second, -1, GETDATE()), @dtePublishedDateToFilter = DATEADD(second, -1, GETDATE())
INSERT INTO @tmpRequisitionWebsitesPublishedBeforeRange EXEC custom_spRequisitionWebsiteFilterWithPublishingCriteria @enmPublishStatus=2, @dtePublishedDateFrom=@dtePublishedDateFromFilter, @dtePublishedDateTo=@dtePublishedDateToFilter

SELECT @dtePublishedDateFromFilter = DATEADD(second, -1, GETDATE()), @dtePublishedDateToFilter = DATEADD(second, +1, GETDATE())
INSERT INTO @tmpRequisitionWebsitesPublishedDuring EXEC custom_spRequisitionWebsiteFilterWithPublishingCriteria @enmPublishStatus=3, @dtePublishedDateFrom=@dtePublishedDateFromFilter, @dtePublishedDateTo=@dtePublishedDateToFilter

SELECT @dtePublishedDateFromFilter = DATEADD(second, -1, GETDATE()), @dtePublishedDateToFilter = DATEADD(second, +1, GETDATE())
INSERT INTO @tmpRequisitionWebsitesPublishedAfterRange EXEC custom_spRequisitionWebsiteFilterWithPublishingCriteria @enmPublishStatus=4, @dtePublishedDateFrom=@dtePublishedDateFromFilter, @dtePublishedDateTo=@dtePublishedDateToFilter


SELECT DISTINCT
R.uidId AS 'uidRequisitionId', 
RWS.nvcName,
RWS.uidId as RWFSuidId,
'XXXXXXXXXXXXXXXXXXXXXXXXX' AS 'nvcPublishedState'
INTO #tmpUserRequisitions
FROM dtlRequisition R
JOIN refRequisitionWorkflowStep RWS ON R.uidRequisitionWorkflowStepId = RWS.uidId
WHERE R.uidId IN (SELECT uidRequisitionId FROM relRecruiterRequisition WHERE uidRecruiterId IN (SELECT uidId FROM dtlRecruiter WHERE uidUserId = '181D1924-2095-49E7-80B4-620538B8D4AF'))
OR R.uidRequisitionWorkflowStepId IN (SELECT uidId FROM #tmpUserRequisitionWorkflowSteps)

UPDATE 
	UR
SET 
	nvcPublishedState = 
	CASE
		WHEN CP.uidId IS NOT NULL THEN 'Currently Advertised'
		WHEN (PP.uidId IS NOT NULL AND CP.uidId IS NULL) AND (CASE WHEN CRWFS.uidId IS NOT NULL THEN RWFSuidId END in(CRWFS.uidId)) THEN 'Previously Advertised'
		WHEN (RW.uidId IS NULL OR (NYP.uidId IS NOT NULL AND CP.uidId IS NULL)) AND (CASE WHEN CRWFS.uidId IS NOT NULL THEN RWFSuidId END in (CRWFS.uidId)) THEN 'Not Yet Advertised' 	
		ELSE 'None'
	END 
FROM 
	#tmpUserRequisitions UR
	LEFT OUTER JOIN relRequisitionWebsite RW on UR.uidRequisitionId = RW.uidRequisitionId
	LEFT OUTER JOIN @tmpRequisitionWebsitesPublishedAfterRange NYP ON UR.uidRequisitionId = NYP.uidRequisitionId
	LEFT OUTER JOIN @tmpRequisitionWebsitesPublishedDuring CP ON UR.uidRequisitionId = CP.uidRequisitionId
	LEFT OUTER JOIN @tmpRequisitionWebsitesPublishedBeforeRange PP ON UR.uidRequisitionId = PP.uidRequisitionId
	LEFT OUTER JOIN ((SELECT uidId FROM refRequisitionWorkflowStep WHERE bitIsCurrent = 1)) CRWFS ON UR.RWFSuidId = CRWFS.uidId

DELETE FROM #tmpUserRequisitions WHERE nvcPublishedState = 'None'

SELECT nvcName + ' - ' + nvcPublishedState AS 'nvcStatus', COUNT(*) AS 'intCount'
INTO #tmpUserRequisitionsFinal
FROM #tmpUserRequisitions	
GROUP BY nvcName, nvcPublishedState	

SELECT '1' AS 'series', nvcStatus AS 'x', intCount AS 'y' FROM #tmpUserRequisitionsFinal
	
DROP TABLE #tmpUserRequisitionWorkflowSteps	
DROP TABLE #tmpUserRequisitions
DROP TABLE #tmpUserRequisitionsFinal
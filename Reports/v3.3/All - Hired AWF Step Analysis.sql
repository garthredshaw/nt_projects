/*
select A.uidId, COUNT(AWH.dteLandingDate)
from relApplication A
join relApplicationWorkflowHistory AWH on A.uidId = AWH.uidApplicationId 
where AWH.uidApplicationWorkflowStepId = 'D48D37A6-FF45-4A2A-B6C4-C87FE3123809'
group by A.uidId 
having COUNT(AWH.dteLandingDate) > 1
*/

/*
-- Agency Application History filter
SELECT DISTINCT RWH.uidRequisitionId
INTO #tmpRequisitionFilter
FROM relRequisitionWorkflowHistory RWH
JOIN refRequisitionWorkflowStep RWS
ON RWH.uidRequisitionWorkflowStepId = RWS.uidId
AND RWH.uidRequisitionId IN 
(
	'3BB1A302-EFFD-4B0C-9007-798372BA79CC'
)
*/


select A.uidRequisitionId, A.uidId as uidApplicationId, 
AWH.dteLandingDate,
(
	select AGY.nvcName 
	from dtlAgency AGY 
	join relAgencyCandidate AC on AGY.uidId = AC.uidAgencyId 
	where AC.uidCandidateId = A.uidCandidateId 
) as 'Agency Name'
from relApplication A
join relApplicationWorkflowHistory AWH on A.uidId = AWH.uidApplicationId 
where AWH.uidApplicationWorkflowStepId = 'D48D37A6-FF45-4A2A-B6C4-C87FE3123809'
--and A.uidRequisitionId = '3BB1A302-EFFD-4B0C-9007-798372BA79CC'
order by A.uidRequisitionId, A.uidId
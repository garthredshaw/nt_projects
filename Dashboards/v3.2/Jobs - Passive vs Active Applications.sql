-- Jobs - Passive vs Active Applications.sql
-- 20150507
-- Count the total candidates, candidates who have not applied for any jobs, 
-- and candidates who have applied for at least one job.

SELECT 'All Candidates' as Type,  
COUNT(*) as Total 
FROM dtlCandidate  
UNION  
SELECT 'Passive Candidates' as Type,  
COUNT(*) as Total 
FROM dtlCandidate 
WHERE uidId NOT IN 
	(SELECT uidCandidateId FROM relApplication)  
UNION  
SELECT 'Active Candidates' as Type,  COUNT(*)  as Total 
FROM dtlCandidate 
WHERE uidId IN 
	(SELECT uidCandidateId FROM relApplication)
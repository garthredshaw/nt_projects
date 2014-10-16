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
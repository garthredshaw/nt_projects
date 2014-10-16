SET NOCOUNT ON;

SELECT * INTO #tmpUserRequisitionWorkflowSteps
FROM refRequisitionWorkflowStep
WHERE uidId IN 
(
	SELECT uidRequisitionWorkflowStepId 
	FROM relRequisitionWorkflowStepPermission 
	WHERE uidRoleId IN (SELECT uidRoleId FROM relRoleMembership WHERE uidUserId = @uidUserId) 
)

SELECT * INTO #tmpUserRequisitions
FROM dtlRequisition
WHERE
      (
         uidId IN (
            SELECT uidId FROM dtlRequisition WHERE
            uidRequisitionWorkflowStepId IN (
               SELECT uidRequisitionWorkflowStepId FROM relRequisitionWorkflowStepPermission WHERE enmAccessLevel = 1 AND uidRoleId IN (SELECT uidRoleId FROM relRoleMembership WHERE uidUserId = @uidUserId)
            )
            AND
            uidId IN (
               SELECT uidRequisitionId FROM relRecruiterRequisition WHERE uidRecruiterId IN (SELECT uidId FROM dtlRecruiter WHERE uidUserId = @uidUserId)
            )
         )
         OR
         uidId IN (
            SELECT uidId FROM dtlRequisition WHERE
            uidRequisitionWorkflowStepId IN (
               SELECT uidRequisitionWorkflowStepId FROM relRequisitionWorkflowStepPermission WHERE (enmAccessLevel = 2 OR enmAccessLevel = 3) AND uidRoleId IN (SELECT uidRoleId FROM relRoleMembership WHERE uidUserId = @uidUserId)
            )
         )
      )

SELECT '#REQUISITIONCOUNT#' as tag, COUNT(*) as value FROM #tmpUserRequisitions

DROP TABLE #tmpUserRequisitionWorkflowSteps
DROP TABLE #tmpUserRequisitions
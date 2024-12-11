USE [butte];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14433';
DECLARE @Comments nvarchar(Max) = 
	'Created Admin report to copy chaffeys weeklys queue report';
DECLARE @Developer nvarchar(50) = 'Nathan Westergard';
DECLARE @ScriptTypeId int = 1; /*  Default 1 is Support,  
For a complete list run the following query

Select * from history.ScriptType
*/

SELECT
 @@servername AS 'Server Name' 
,DB_NAME() AS 'Database Name'
,@JiraTicketNumber as 'Jira Ticket Number';

SET XACT_ABORT ON
BEGIN TRAN

INSERT INTO History.ScriptsRunOnDatabase
(TicketNumber,Developer,Comments,ScriptTypeId)
VALUES
(@JiraTicketNumber, @Developer, @Comments, @ScriptTypeId); 

/*--------------------------------------------------------------------
Please do not alter the script above this comment� except to set
the Use statement and the variables. 

Notes:  
	1.   In comments put a brief description of what the script does.
         You can also use this to document if we are doing somehting 
		 that is against meta best practices but the client is 
		 insisting on, and that the client has been made aware of 
		 the potential consequences
	2.   ScriptTypeId
		 Note:  For Pre and Post Deploy we should follow the following 
		 script naming convention Release Number/Ticket Number/either the word Predeploy or PostDeploy
		 Example: Release3.103.0_DST-4645_PostDeploy.sql

-----------------Script details go below this line------------------*/
SET QUOTED_IDENTIFIER OFF 
 
DECLARE @adminReportId INT;
DECLARE @sql NVARCHAR(MAX) =
"
SELECT Subject_Course.SubjectCode AS ""Course_Subject Code"", Course.CourseNumber AS ""Course Number"", Course.Title AS ""Course Title"", ProposalType_Course.Title AS ""Proposal Type"", CourseYesNoDetail_CourseYesNo_Course.YesNo21_Title AS ""Distance Education"", CASE WHEN CourseYesNoDetail_CourseYesNo_Course.YesNo21_Title = 'Yes' THEN DeliveryMethod_CourseDistanceEducation_Course.Description ELSE '' END AS ""Distance Education Type"", User_UserId_Course.Email AS Originator, Proposal_Course.LaunchDate AS ""Launch Date"", StepLevel_Step_CurrentLevelOpenProcessStep_Proposal_Course.SortOrder AS ""Step in Workflow"" 
FROM ((((((((((((select * from dbo.[Subject]) Subject_Course
     RIGHT OUTER JOIN dbo.Course AS Course ON (Subject_Course.Id  = Course.SubjectId ))
     LEFT OUTER JOIN (select * from dbo.ProposalType) ProposalType_Course ON (ProposalType_Course.Id  = Course.ProposalTypeId ))
     LEFT OUTER JOIN (SELECT
    Course.Id AS CourseId,
    YesNo21.Title AS YesNo21_Title
FROM Course
INNER JOIN CourseYesNo ON CourseYesNo.CourseId = Course.Id
LEFT JOIN YesNo AS YesNo21 ON YesNo21.Id = CourseYesNo.YesNo21Id
) CourseYesNoDetail_CourseYesNo_Course ON (CourseYesNoDetail_CourseYesNo_Course.CourseId  = Course.Id ))
     LEFT OUTER JOIN (select * from dbo.CourseDistanceEducation) CourseDistanceEducation_Course ON (CourseDistanceEducation_Course.CourseId  = Course.Id ))
     LEFT OUTER JOIN (select * from dbo.DeliveryMethod) DeliveryMethod_CourseDistanceEducation_Course ON (DeliveryMethod_CourseDistanceEducation_Course.Id  = CourseDistanceEducation_Course.DeliveryMethodId ))
     INNER JOIN (select * from dbo.[User]) User_UserId_Course ON (User_UserId_Course.Id  = Course.UserId ))
     LEFT OUTER JOIN (select * from dbo.Proposal) Proposal_Course ON (Proposal_Course.Id  = Course.ProposalId ))
     INNER JOIN (select
    plah.ProposalId,
    plah.Id as ProcessLevelActionHistoryId,
    psah.Id as ProcessStepActionHistoryId,
    psah.Source_ProcessStepActionHistoryId,
    plah.CreatedDate as ProcessLevelActionHistory_CreatedDate,
    plah.StepLevelId as ProcessLevelActionHistory_StepLevelId,
    plah.LevelActionResultTypeId as ProcessLevelActionHistory_LevelActionResultTypeId,
    psah.CreatedDate,
    psah.StepId,
    psah.StepActionResultTypeId,
    psah.ResultDate,
    psah.UserId,
    psah.Comments,
    psah.ActionLevelRouteId,
    psah.AgingWorkflowDefaultActionReminderQueued,
    psah.CommentIsPrivate,
	isnull(oc.OriginatorChanges,0) as WaitingForChanges
from ProcessLevelActionHistory plah
inner join ProcessStepActionHistory psah
    on psah.ProcessLevelActionHistoryId = plah.Id
left join (select psah1.ProcessLevelActionHistoryId, 1 as OriginatorChanges
	from ProcessStepActionHistory psah1
	join ProcessStepActionHistory psah2 
		on psah1.Id = psah2.Source_ProcessStepActionHistoryId
	where psah2.ResultDate IS NULL
	group by psah1.ProcessLevelActionHistoryId) oc on oc.ProcessLevelActionHistoryId = plah.Id
where 1=1
    and (plah.LevelActionResultTypeId = 1
		or (psah.Source_ProcessStepActionHistoryId is not null 
			and psah.ResultDate is null))
    and	psah.StepActionResultTypeId = 1) CurrentLevelOpenProcessStep_Proposal_Course ON (CurrentLevelOpenProcessStep_Proposal_Course.ProposalId  = Proposal_Course.Id ))
     INNER JOIN (select * from dbo.Step) Step_CurrentLevelOpenProcessStep_Proposal_Course ON (Step_CurrentLevelOpenProcessStep_Proposal_Course.Id  = CurrentLevelOpenProcessStep_Proposal_Course.StepId ))
     INNER JOIN (select * from dbo.StepLevel) StepLevel_Step_CurrentLevelOpenProcessStep_Proposal_Course ON (StepLevel_Step_CurrentLevelOpenProcessStep_Proposal_Course.Id  = Step_CurrentLevelOpenProcessStep_Proposal_Course.StepLevelId ))
     LEFT OUTER JOIN (select * from dbo.StatusAlias) StatusAlias_Course ON (StatusAlias_Course.Id  = Course.StatusAliasId ))
WHERE
(
  StatusAlias_Course.Title LIKE 'in review%' )
GROUP BY Subject_Course.SubjectCode, Course.CourseNumber, Course.Title, ProposalType_Course.Title, CourseYesNoDetail_CourseYesNo_Course.YesNo21_Title, DeliveryMethod_CourseDistanceEducation_Course.Description, User_UserId_Course.Email, Proposal_Course.LaunchDate, StepLevel_Step_CurrentLevelOpenProcessStep_Proposal_Course.SortOrder
HAVING count(*) > 0 
ORDER BY  ""Course_Subject Code"", ""Course Number""
";

SET QUOTED_IDENTIFIER ON 

INSERT INTO AdminReport (ReportName, ReportSQL, OutputFormatId, ShowOnMenu)
VALUES ('Weekly Queue Check Report', @sql, 1, 1)
SET @adminReportId = SCOPE_IDENTITY ()


INSERT INTO AdminReportClient (AdminReportId, ClientId)
VALUES (@adminReportId, 1)
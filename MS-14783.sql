USE [ucdavis];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14783';
DECLARE @Comments nvarchar(Max) = 
	'Update Failing Adhoc reports';
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
Please do not alter the script above this comment  except to set
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
UPDATE AdHocReport
SET Definition = '{"id":"74","modelId":"9114741f-cfe6-4d46-8060-c30fc2f293a5","modelName":"ApprovalProcess","modelVersion":49,"title":"InReview_SelectStep","description":"","outputFormatId":"1","isPublic":false,"columns":[{"caption":"Course.Proposal.Step Action History Step Title","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Step.Title3"}},{"caption":"Course.Proposal.Step Action History Comments","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"ProcessStepActionHistory_Course_Proposal.Comments"}},{"caption":"Course.Proposal.Step Action History Action Date","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"ProcessStepActionHistory_Course_Proposal.ResultDate"}},{"caption":"Course.Proposal.Step Action History User Last Name","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"{User}.LastName3"}},{"caption":"Course.Proposal.Step Action History Action","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"ActionId_ActionLevelRoute_ProcessStepActionHistory.Title"}},{"caption":"Course.Subject Code","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"SubjectId_Subject_Course.SubjectSubjectCode"}},{"caption":"Course Course Number","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Course.CourseNumber"}},{"caption":"Course.Status Alias Title","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"StatusAliasId_StatusAlias_Course.StatusAliasTitle"}},{"caption":"Course.Course Proposal.Semester Code","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Semester_SemesterId_CourseProposal_Course.Code"}}],"justsorted":[],"root":{"linkType":"All","enabled":true,"conditions":[{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"Contains","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"Step.Title3"},{"typeName":"CONST","dataType":"String","kind":"Scalar","value":"COCI Chair","text":"COCI Chair"}]}]}}'
WHERE Id = 74

UPDATE AdHocReport
SET Definition = '{"id":"39","modelId":"9114741f-cfe6-4d46-8060-c30fc2f293a5","modelName":"ApprovalProcess","modelVersion":49,"title":"Program Detail -  Desc, Status,  Multiple Fields","description":"Program Information with status, college, department, title, description and multiple fields","outputFormatId":"1","isPublic":true,"columns":[{"caption":"Program Status Alias Title","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"StatusAliasId_StatusAlias_Program.StatusAliasTitle"}},{"caption":"Program Tier 1 Organization Entity Title","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Tier1_OrganizationEntityId_OrganizationEntity_Program.OrganizationEntityTitle"}},{"caption":"Program Tier 2 Organization Entity Title","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Tier2_OrganizationEntityId_OrganizationEntity_Program.OrganizationEntityTitle"}},{"caption":"Program Award Type Title","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"AwardTypeId_AwardType_Program.AwardTypeTitle"}},{"caption":"Program Title","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Program.Title"}},{"caption":"Program Status Alias Title","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"StatusAliasId_StatusAlias_Program.StatusAliasTitle"}},{"caption":"Program Introduction","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Program.Introduction"}},{"caption":"Program Admission Requirements","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Program.AdmissionRequirements"}},{"caption":"Program Rationale","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Program.Rationale"}},{"caption":"Program Administration Plan","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Program.AdministrationPlan"}},{"caption":"Program Associations","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Program.Associations"}},{"caption":"Program Advisory Committee Member List","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Program.AdvisoryCommitteeMemberList"}},{"caption":"Program Institutional Code","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Program.InstitutionalCode"}},{"caption":"Program Title Alias","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Program.TitleAlias"}},{"caption":"Program.Program Proposal Student System Award Level Id","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"StudentSystemAwardLevel_ProgramProposal_Program.Title"}},{"caption":"Program CIP Code","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CipCodeId_CipCode_Program.Code"}},{"caption":"Program Unique Code","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Program.UniqueCode"}},{"caption":"Program.Program Proposal Actual Begin Semester","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"ActualBeginSemesterId_Semester_ProgramProposal.Title"}},{"caption":"Program.Program Proposal End Semester Id","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Semesters_ProgramProposal.End_SemesterTitle"}},{"caption":"Program Overlap Analysis","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Program.OverlapAnalysis"}}],"justsorted":[],"root":{"linkType":"All","enabled":true,"conditions":[]}}'
WHERE Id = 39
USE [palomar];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15017';
DECLARE @Comments nvarchar(Max) = 
	'Update Adhoc report ';
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
SET Definition = '
{"id":"124","modelId":"9114741f-cfe6-4d46-8060-c30fc2f293a5","modelName":"ApprovalProcess","modelVersion":49,"title":"Program Course Block Detail","description":"","outputFormatId":"1","isPublic":true,"columns":[{"caption":"Division","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Tier1_OrganizationEntityId_OrganizationEntity_Program.OrganizationEntityTitle"}},{"caption":"Department","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Tier2_OrganizationEntityId_OrganizationEntity_Program.OrganizationEntityTitle"}},{"caption":"Award Type","sorting":"Ascending","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"AwardTypeId_AwardType_Program.AwardTypeTitle"}},{"caption":"Program Title","sorting":"Ascending","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Program.Title"}},{"caption":"Block Order","sorting":"Ascending","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CourseOption_Program.SortOrder"}},{"caption":"Block Title","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Block_Program.CourseOptionNote"}},{"caption":"Group Title","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"VEA_20"}},{"caption":"Item Order","sorting":"Ascending","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Program_Course.SortOrder"}},{"caption":"Item Type","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"ListItemType_ProgramCourse.Title"}},{"caption":"Course Title","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Course_ProgramCourse_CourseOption_Program.EntityTitle"}},{"caption":"Item Condition","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"VEA_19"}},{"caption":"Crse Min Units","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CourseInfo_ProgramCourse_CourseOption_Program.MinCreditHour"}},{"caption":"Crse Max Units","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"VEA_22"}},{"caption":"Block Min Unit Override","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Block_Program.ValueLow"}},{"caption":"Block Max Unit Override","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Block_Program.ValueHigh"}},{"caption":"Item Min Unit Override","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"VEA_18"}},{"caption":"Item Max Unit Override","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"VEA_17"}},{"caption":"Non-Course Requirement Description","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"ProgramCourse_CourseOption_Program.Header"}},{"caption":"Program Discipline","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"SubjectId_Subject_Program.SubjectSubjectCode"}},{"caption":"Chancelor’s Nbr Ads","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"ProgramProposal_Program.ChancelorNumber"}},{"caption":"Chancelor’s Nbr Certs","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Generic255Text_Program.Text25514"}}],"justsorted":[],"root":{"linkType":"All","enabled":true,"conditions":[{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"IsTrue","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"Program.Active"}]},{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"Equal","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"StatusAliasId_StatusAlias_Program.StatusAliasTitle"},{"typeName":"CONST","dataType":"String","kind":"Scalar","value":"Active","text":"Active"}]}]}}
'
WHERE Id = 124
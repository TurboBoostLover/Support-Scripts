USE [sac];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14675';
DECLARE @Comments nvarchar(Max) = 
	'New Adhoc Report';
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
INSERT INTO AdHocReport
(ClientId, Title, Definition, OutputFormatId, IsPublic, Active)
VALUES
(1, 'CTE Cross Listed', '{"id":0,"modelId":"9114741f-cfe6-4d46-8060-c30fc2f293a5","modelName":"ApprovalProcess","modelVersion":49,"title":"CTE Cross Listed","description":"","outputFormatId":1,"isPublic":false,"columns":[{"caption":"Subject","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Subject_Course.Title"}},{"caption":"Number","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Course.CourseNumber"}},{"caption":"Course Title","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Course.Title"}},{"caption":"C-ID Number","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"GenericMaxText_Course.TextMax09"}},{"caption":"Launch Date","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CourseProposal.ImplementDate"}},{"caption":"CB03","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CB03.Description2"}},{"caption":"CB05","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CB05.Code2"}},{"caption":"Status","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"StatusAliasId_StatusAlias_Course.StatusAliasTitle"}},{"caption":"Cross Listed","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"RelatedCourseInfo_CourseRelatedCourse_Course.RelatedCourse_Active"}}],"justsorted":[],"root":{"linkType":"All","enabled":true,"conditions":[{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"IsTrue","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"CB03.Vocational2"}]},{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"InList","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"CB05.Code2"},{"typeName":"CONST","dataType":"String","kind":"List","value":"A,B","text":"A,B"}]},{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"InList","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"StatusAliasId_StatusAlias_Course.StatusAliasTitle"},{"typeName":"CONST","dataType":"String","kind":"List","value":"Active,In Review","text":"Active,In Review"}]},{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"IsTrue","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"RelatedCourseInfo_CourseRelatedCourse_Course.RelatedCourse_Active"}]}]}}', 1, 0, 1)
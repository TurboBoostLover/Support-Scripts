USE [compton];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14982';
DECLARE @Comments nvarchar(Max) = 
	'Create Adhoc report for them "Credit by Examination"';
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
(ClientId, Title, Description, Definition, OutputFormatId, IsPublic, Active)
VALUES
(1, 'Credit by Examination', 'Credit by Examination Report #38501', '{"id":0,"modelId":"9114741f-cfe6-4d46-8060-c30fc2f293a5","modelName":"ApprovalProcess","modelVersion":49,"title":"Credit by Examination","description":"","outputFormatId":1,"isPublic":false,"columns":[{"caption":"Course Title","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Course.Title"}},{"caption":"Course Number","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Course.CourseNumber"}},{"caption":"Course Subject","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Subject_Course.Title"}},{"caption":"Status","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"StatusAliasId_StatusAlias_Course.StatusAliasTitle"}},{"caption":"Credit By Examination","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CampusId_Campus_Course.CampusTitle"}}],"justsorted":[],"root":{"linkType":"All","enabled":true,"conditions":[{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"InList","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"StatusAliasId_StatusAlias_Course.StatusAliasTitle"},{"typeName":"CONST","dataType":"String","kind":"List","value":"Active,Approved","text":"Active,Approved"}]}]}}', 1, 0, 1)
USE [stpetersburg];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17497';
DECLARE @Comments nvarchar(Max) = 
	'Update Admin Report';
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

If exists(select top 1 1 from History.ScriptsRunOnDatabase where TicketNumber = @JiraTicketNumber and Developer = @Developer and Comments = @Comments)
	THROW 51000, 'This Script has already been run', 1;

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
UPDATE AdminReport
SET ReportSQL = '
Declare @queryString nvarchar(max) = (select customSql from MetaForeignKeyCriteriaClient where Id = 31)

select 
concat(S.SubjectCode,'' '',C.CourseNumber) as [COURSE]
,C.Title as [COURSE TITLE]
,concat(''"'',dbo.stripHtml(C.Description),''"'') as [COURSE DESCRIPTION]
,concat(format(CD.MinCreditHour,''#.#'') ,case when CD.MinCreditHour <> CD.MaxCreditHour then '' - '' + format(CD.MaxCreditHour,''#.#'') else '''' end) as [CREDITS]
,OE.Title as [COLLEGE SCHOOL DEPARTMENT],
a.Text AS [Conditions of Enrollment Catalog View]
From course C
	inner join Subject S on C.SubjectId = S.Id
	inner join CourseDescription CD on C.id = CD.CourseId
	inner join CourseDetail CD2 on C.id = CD2.CourseId
	inner join OrganizationEntity OE on CD2.Tier2_OrganizationEntityId = OE.id
	cross Apply (SELECT * FROM fnBulkResolveCustomSqlQuery(@queryString, 1, c.Id, 1, 744, 1, NULL))a
where C.active = 1 
	and C.StatusAliasid = 1
order by s.SubjectCode, dbo.fnCourseNumberToNumeric(c.CourseNumber),C.Title
'
WHERE Id = 75
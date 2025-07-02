USE [sbccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19096';
DECLARE @Comments nvarchar(Max) = 
	'Update Agenda Report';
DECLARE @Developer nvarchar(50) = 'Nathan Westergard';
DECLARE @ReqTicket nvarchar(20) = 'MS-'
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

IF NOT EXISTS(select top 1 Id from History.ScriptsRunOnDatabase where TicketNumber = @ReqTicket) AND LEN(@ReqTicket) > 5
    RAISERROR('This script has a dependency on ticket %s which needs to be run first.', 16, 1, @ReqTicket);

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
UPDATE Report.AgendaReportQuery
SET QueryText = 
'SET @_entityData =
	( 
		SELECT c.Id AS [Id],
		( CASE 
			WHEN c.[Title] IS NULL THEN '''' 
			ELSE dbo.fnHtmlField(''div'', ''span'',''span'', dbo.fnHtmlElement(''span'', ''Title'', NULL), CONCAT(@_entityTitle,'' '',''''), ''{ "Key" :"class", "Value" :"field-wrapper-first-child" }'', NULL, NULL, '': '', 0) 
			END ) AS [Title], 
		( CASE 
			WHEN s.[Title] IS NULL THEN '''' 
			ELSE dbo.fnHtmlStandardSimplefield(''Course Subject/Number'', CONCAT(''(<a href="https://sbccd.curriqunet.com/DynamicReports/AllFieldsReportByEntity/'',C.id,''?entityType=Course&reportId=337">'',s.[SubjectCode],'' '', C.[CourseNumber], ''</a>)''), NULL, NULL, '': '', 0 ) 
			END ) AS [Subject],
		( CASE 
			WHEN C.[Rationale] IS NULL THEN '''' 
			WHEN c.ProposalTypeId = 149 THEN dbo.fnHtmlStandardSimplefield(''Rationale'', cd.Rationale , NULL, NULL, '': '', 0)
			WHEN c.ProposalTypeId = 148 THEN ''''
			ELSE dbo.fnHtmlStandardSimplefield(''Rationale'', coalesce(GMT.TextMax06,C.Rationale), NULL, NULL, '': '', 0 ) 
			END) AS [Rationale] ,
		( CASE 
			WHEN c.[CrossListedCourses] IS NULL OR c.[CrossListedCourses] = '''' THEN '''' 
			ELSE dbo.fnHtmlStandardSimplefield(''Crosslisting'', CONCAT(REPLACE(C.[CrosslistedCourses], ''h2'', ''h5''), ''<br><br>''), NULL, NULL, '':'', 0 ) 
			END) AS [CrossListing] 
FROM [course] c 
	inner join GenericMaxText GMT on C.id = GMT.CourseId 
	INNER JOIN [subject] s ON c.SubjectId = s.Id 
	INNER JOIN CourseDescription AS cd on cd.CourseId = c.Id
	INNER JOIN @entity e ON c.Id = e.[EntityId] AND c.Id = @entityId FOR JSON AUTO ); 


SET @_entitySummary = 
	( SELECT CONCAT( dbo.fnHtmlOpenTag( ''div'', [dbo].[fnHtmlConcatTagAttributes](''[{"Key":"class","Value":"section"},{"Key":"title","Value":"Course Basics"}]'', 0 ) ), 
					[Subject], 
					[Title],
					[Rationale], 
					[CrossListing],
					dbo.fnHtmlCloseTag(''div'') ) 
	FROM OPENJSON(@_entityData) 
	WITH ( [Subject] nvarchar(max) ''$.Subject'',[Title] nvarchar(max) ''$.Title'',[Rationale] nvarchar(max) ''$.Rationale'', [CrossListing] nvarchar(max) ''$.CrossListing'' ) ); 


SELECT ( CASE WHEN @_entitySummary IS NULL THEN '' '' ELSE @_entitySummary END ) AS [Text], @entityId AS [Value];
'
WHERE Id = 4
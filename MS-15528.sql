USE [sbccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15528';
DECLARE @Comments nvarchar(Max) = 
	'Update Agenda Report';
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
-- configuration (new) 
	update Report.AgendaReportEntityGroup
	set UpperCaseTitle = 1
	, [UsePluralTitleForProposalType] = 1
	, DisplayLevelIndentation = 0

-- make the font size bigger for the proposal type and reduce the colspan to 1 instead of 2. The colspan is one now to remove the two columns for the entity where the first column is the marker (e.g. 1) 
	update g
	set AttributesJson = '[{"Key":"colspan","Value":"1"}, {"Key":"style","Value":"font-size: 14pt"}]'
	from Report.AgendaReportEntityGroup g
	where id = 1

-- add plural title to the DE proposal type.
	update pt
	set pt.PluralTitle = 'DE Additions ONLY'
	from ProposalType pt
	where Title = 'DE Addition ONLY'

-- Turns off the numebering for proposal types and sets the numbering for entities to 'alpha'
	update ar
	set AttributesJson = '
	{
		"ListNumberStrategy": [
			{
				"Id": 1,
				"Level": 0,
				"NumberStyle": "roman"
			},
			{
				"Id": 2,
				"Level": 1,
				"NumberStyle": "none"
			},
			{
				"Id": 3,
				"Level": 2,
				"NumberStyle": "alpha"
			}
		]
	}
	'
	from Report.AgendaReportLayout ar
	where Id = 2


-- remove the indentation of the entities
	-- Key: #level-2 .section, #level-2 > td > span
	update Report.AgendaReportAttribute
	set [Value] = 'margin-left: 0pt'
	where id = 10;

	update Report.AgendaReportAttribute
	set [key] = '.reqtype-title' -- before: .field-wrapper,.reqtype-title
	where id = 16;

	-- Key: .field-wrapper-first-child
	update Report.AgendaReportAttribute
	set [Value] = 'margin-left: 0pt;'
	where Id = 15

-- remove numbering from the first column and add numbering inside the entity (Courses)
	delete
	from Report.[AgendaReportQueryMapping]
	where AgendaReportQueryId = 3
	and EntityTypeId = 1

	update Report.AgendaReportQuery
	set QueryText = '
	SET @_entityData = (
		SELECT c.Id AS [Id],
		( CASE WHEN c.[Title] IS NULL THEN '''' ELSE dbo.fnHtmlField(''div'', ''span'',''span'', dbo.fnHtmlElement(''span'', ''Title'', NULL), CONCAT(@_entityTitle,'' '',''''), ''{ "Key" :"class", "Value" :"field-wrapper-first-child" }'', NULL, NULL, '': '', 0) END ) AS [Title],
		( 
			CASE 
				WHEN s.[Title] IS NULL THEN '''' 
				ELSE dbo.fnHtmlStandardSimplefield(
					concat(lower(@_entityNumber), ''Course Subject/Number''),
					CONCAT(''(<a href="https://sbccd.curriqunet.com/DynamicReports/AllFieldsReportByEntity/'',C.id,''?entityType=Course&reportId=337">'',s.[Title],'' '', C.[CourseNumber], ''</a>)''), NULL, NULL, '': '', 0
				)
				END 
		) AS [Subject],
		( CASE WHEN C.[Rationale] IS NULL THEN '''' ELSE dbo.fnHtmlStandardSimplefield(''Rationale'', coalesce(GMT.TextMax06,C.Rationale), NULL, NULL, '': '', 0 ) END ) AS [Rationale] 
		FROM [course] c 
			inner join GenericMaxText GMT on C.id = GMT.CourseId 
			INNER JOIN [subject] s ON c.SubjectId = s.Id 
			INNER JOIN @entity e ON c.Id = e.[EntityId] 
			AND c.Id = @entityId 
		FOR JSON AUTO
	);

	SET @_entitySummary = ( SELECT CONCAT( dbo.fnHtmlOpenTag( ''div'', [dbo].[fnHtmlConcatTagAttributes](''[{"Key":"class","Value":"section"},{"Key":"title","Value":"Course Basics"}]'', 0 ) ), [Subject], [Title],[Rationale], dbo.fnHtmlCloseTag(''div'') ) FROM OPENJSON(@_entityData) WITH ( [Subject] nvarchar(max) ''$.Subject'',[Title] nvarchar(max) ''$.Title'',[Rationale] nvarchar(max) ''$.Rationale'' ) ); SELECT ( CASE WHEN @_entitySummary IS NULL THEN '' '' ELSE @_entitySummary END ) AS [Text], @entityId AS [Value];
	'
	where Id = 4

-- remove numbering from the first column and add numbering inside the entity (Programs) 
	delete from Report.AgendaReportQueryMapping
	where id = 3


	update Report.AgendaReportQuery
	set QueryText = '
	SET @_entityData =( SELECT p.[Id] AS [Id], dbo.fnHtmlField( ''div'', ''span'', ''span'', dbo.fnHtmlElement(''span'', concat(lower(@_entityNumber), ''Program Title''), NULL), concat(''<a href="https://sbccd.curriqunet.com/DynamicReports/AllFieldsReportByEntity/'',P.id,''?entityType=Program&reportId=355">'',@_entityTitle, ''</a>''), ''{ "Key" :"class", "Value" :"field-wrapper-first-child" }'', NULL, NULL, '': '', 0) AS [Title],( CASE WHEN oe.[Title] IS NULL THEN '''' ELSE dbo.fnHtmlStandardSimplefield(''Discipline'', oe.[Title], null, null, '': '', 0) END ) AS [Discipline], ( CASE WHEN at.[Title] IS NULL THEN '''' ElSE dbo.fnHtmlStandardSimplefield(''Award Type'', at.[Title], null, null, '': '', 0) END ) AS [AwardType] FROM [program] p INNER JOIN OrganizationEntity oe ON p.[Tier1_OrganizationEntityId] = oe.[Id] INNER JOIN AwardType at ON p.[AwardTypeId] = at.[Id] INNER JOIN @entity e ON p.[Id] = e.[EntityId] and p.[Id] = @entityId FOR JSON AUTO ) SET @_EntitySummary = ( SELECT CONCAT( dbo.fnHtmlOpenTag( ''div'', [dbo].[fnHtmlConcatTagAttributes]( ''[{"Key":"class","Value":"section"},{"Key":"title","Value":"Program Basics"}]'', 0 ) ), [Title], [Discipline], [AwardType], dbo.fnHtmlCloseTag(''section'') ) FROM OPENJSON(@_entityData) with ( [Title] nvarchar(max) ''$.Title'', [Discipline] nvarchar(max) ''$.Discipline'', [AwardType] nvarchar(max) ''$.AwardType'' ) ) SELECT ( CASE WHEN @_entitySummary IS NULL THEN '' '' ELSE @_entitySummary END ) AS [Text], @entityId AS [Value];
	'
	where id = 7
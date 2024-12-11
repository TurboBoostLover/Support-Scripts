USE [hkapa];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18062';
DECLARE @Comments nvarchar(Max) = 
	'Add Agenda Report';
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
declare @hasPackages bit = (CASE
    WHEN exists(
        select top 1 Id
        from ProposalType
        where EntityTypeId = 3
    )
    THEN 1
    ELSE 0
END);
declare @clientId int = (select Id from Client);
insert into [Report].[AgendaReportLayout]
VALUES
('Agenda Report','Default Agenda Config',@clientId,'{"ListNumberStrategy":[{"Id":1,"Level":0,"NumberStyle":"roman","UpperCase":1},{"Id":2,"Level":1,"NumberStyle":"alpha","UpperCase":1},{"Id":3,"Level":2,"NumberStyle":"null","UpperCase":0}]}',1);
declare @layoutId int = SCOPE_IDENTITY();
insert into [Report].[AgendaReportEntityGroupType]
VALUES
(1,'ProcessActionType')
,(2,'Department')
,(3,'EntityType')
,(4,'ProposalType');
insert into [Report].[AgendaReportEntityGroup]
VALUES
(null,4,'[{"ComparisonPredicate":"ProcessActionTypeId","ComparisonOperator":35,"ComparisonValue":0}]',1,'[{"Key":"colspan","Value":"2"}]');
declare @groupId int = SCOPE_IDENTITY();
declare @sectionAttributes nvarchar(max) = '[{"Key":"valign","Value":"top"},{"Key":"colspan","Value":"2"}]';
insert into [Report].[AgendaReportSection]
VALUES
(null,'Agenda Report',null,JSON_MODIFY(@sectionAttributes, 'append $', JSON_QUERY('{"Key":"style","Value":"border-bottom:1px solid;"}')),0,null,1,0,@clientId),
(null,'Call to Order',null,@sectionAttributes,1,null,1,0,@clientId),
(null,'Minutes of',null,@sectionAttributes,2,null,1,0,@clientId),
(null,'Announcements',null,@sectionAttributes,3,null,1,0,@clientId),
(null,'Action Items',null,@sectionAttributes,4,null,1,0,@clientId),
(null,'Consent Calendar',null,'[{"Key":"valign","Value":"top"},{"Key":"colspan","Value":"2"},{"ColumnHeaders":[{"Key":"1","Value":"Agenda Item"},{"Key":"2","Value":"Proposal Information"}]}]',5,1,1,0,@clientId),
(null,'Resumption of Regular Agenda',null,@sectionAttributes,6,null,1,0,@clientId),
(null,'Information/Discussion',null,@sectionAttributes,7,null,1,0,@clientId),
(null,'Reports',null,@sectionAttributes,8,null,1,0,@clientId),
(null,'Future Items for Discussion',null,@sectionAttributes,9,null,1,0,@clientId),
(null,'Next Meeting',null,@sectionAttributes,10,null,1,0,@clientId),
(null,'adjournment',null,@sectionAttributes,11,null,1,0,@clientId);
insert into [Report].[AgendaReportLayoutMapping]
select l.Id as [AgendaReportLayoutId], s.Id as [AgendaReportSectionId]
from [Report].[AgendaReportLayout] l
cross apply (
    select Id
    from [Report].[AgendaReportSection]
) s
where l.Id = @layoutId;

declare @queryAttributes nvarchar(max) = '[{"Type":"layout","columnId":"2","Key":"class","Value":"col2"},{"Key":"valign","Value":"top"}]';

insert into [Report].[AgendaReportQuery]
VALUES
('Header Section',null,'SELECT( CASE WHEN [DisplayTitle] = 1 THEN CONCAT( dbo.[fnHtmlOpenTag](''div'', dbo.[fnHtmlAttribute](''class'',''header'')), dbo.[fnHtmlOpenTag](''h1'', dbo.[fnHtmlAttribute](''class'',''client-title'')), ( SELECT TOP 1 Title FROM CLient WHERE Id = @clientId), dbo.[fnHtmlCloseTag](''h1''), dbo.[fnHtmlOpenTag](''h2'', null), [Title], dbo.[fnHtmlCloseTag](''h2''), dbo.[fnHtmlOpenTag](''div'',null), FORMAT(getdate(), ''MMMM dd, yyyy''), dbo.[fnHtmlCloseTag](''div''), dbo.[fnHtmlCloseTag](''div'') ) END ) AS [Text], @entityId AS [Value] FROM @section WHERE Id = @entityId;',0,'[{"Type":"layout","columnId":"1","Key":"class","Value":"col1"},{"Key":"valign","Value":"top"}]'),
('Layout Section',null,'SELECT( CASE WHEN [DisplayTitle] = 1 THEN CONCAT( dbo.fnHtmlOpenTag(''div'', dbo.[fnHtmlAttribute](''class'',''section'')), @_rowNum, dbo.fnHtmlOpenTag(''span'', null), [Title], dbo.fnHtmlCloseTag(''span''), dbo.fnHtmlCloseTag(''div'')) END ) AS [Text], @entityId AS [Value] FROM @section WHERE Id = @entityId;',0,'[{"Type":"layout","columnId":"1","Key":"class","Value":"col1"},{"Key":"valign","Value":"top"}]'),
('Item Number',null,'SELECT @_entityNumber AS [Text],@entityId AS [Value];',1,'[{"Type":"layout","columnId":"1","Key":"class","Value":"col1"},{"Key":"valign","Value":"middle"}]'),
('Course Basics',null,'SET @_entityData =( SELECT c.Id AS [Id],( CASE WHEN c.[Title] IS NULL THEN '''' ELSE dbo.fnHtmlField(''div'', ''span'',''span'', dbo.fnHtmlElement(''span'', ''Course Number & Title'', NULL), CONCAT(@_entityTitle,'' '',c.[CourseNumber]), ''{ "Key" :"class", "Value" :"field-wrapper-first-child" }'', NULL, NULL, '': '', 0) END ) AS [Title], ( CASE WHEN c.[ShortTitle] IS NULL THEN '''' ELSE dbo.fnHtmlStandardSimplefield( ''Short Title'', c.[ShortTitle], NULL, NULL, '': '', 0 ) END ) AS [ShortTitle], ( CASE WHEN s.[Title] IS NULL THEN '''' ELSE dbo.fnHtmlStandardSimplefield(''Subject'', CONCAT(s.[Title], ''('', s.[SubjectCode], '') ''), NULL, NULL, '': '', 0 ) END ) AS [Subject] FROM [course] c INNER JOIN [subject] s ON c.SubjectId = s.Id INNER JOIN @entity e ON c.Id = e.[EntityId] AND c.Id = @entityId FOR JSON AUTO ); SET @_entitySummary = ( SELECT CONCAT( dbo.fnHtmlOpenTag( ''div'', [dbo].[fnHtmlConcatTagAttributes](''[{"Key":"class","Value":"section"},{"Key":"title","Value":"Course Basics"}]'', 0 ) ), [Title], [ShortTitle], [Subject], dbo.fnHtmlCloseTag(''div'') ) FROM OPENJSON(@_entityData) WITH ( [Title] nvarchar(max) ''$.Title'', [ShortTitle] nvarchar(max) ''$.ShortTitle'', [Subject] nvarchar(max) ''$.Subject'' ) ); SELECT ( CASE WHEN @_entitySummary IS NULL THEN '' '' ELSE @_entitySummary END ) AS [Text], @entityId AS [Value];',1,@queryAttributes),
('Course Requisites',null,'SET @_entityData =( SELECT t.[Id] AS Id, t.ReqTypeId AS ReqTypeId, CONCAT( dbo.fnHtmlOpenTag(''div'',dbo.fnHtmlAttribute(''class'',''reqtype-title'')), t.[ReqTypeTitle], dbo.fnHtmlCloseTag(''div''), dbo.ConcatOrdered_Agg(t.cr_Id,t.[ReqText],1)) AS [ReqText] FROM ( SELECT c1.[Id] AS Id, rt.[Id] AS ReqTypeId, cr.Id AS cr_Id, COALESCE(rt.[Title],''No Requisite Type'') AS ReqTypeTitle, CONCAT( dbo.fnHtmlOpenTag(''div'',dbo.fnHtmlAttribute(''class'',''req-text'')), CONCAT( (CASE WHEN cr.[EnrollmentLimitation] IS NOT NULL THEN dbo.[fnHtmlElement](''span'',cr.[EnrollmentLimitation],null) END), (CASE WHEN cr.[Requisite_CourseId] IS NOT NULL THEN dbo.[fnHtmlElement](''span'',CONCAT(s.[SubjectCode],'' '',c2.[CourseNumber],'' '',c2.Title),null) END), (CASE WHEN cr.[CourseRequisiteComment] IS NOT NULL THEN dbo.[fnHtmlElement](''span'',cr.[CourseRequisiteComment],null) END), (CASE WHEN cr.[ConditionId] IS NOT NULL THEN CONCAT(''; '', dbo.[fnHtmlElement](''span'',con.[Title],''[{"Key":"class","Value":"'' + con.Title + ''-condition"}]'')) END) ), dbo.fnHtmlCloseTag(''div'') ) AS ReqText FROM Course c1 INNER JOIN CourseRequisite cr on c1.[Id] = cr.[CourseId] INNER JOIN Course c2 on cr.[Requisite_CourseId] = c2.[Id] INNER JOIN [Subject] s on s.[Id] = c2.[SubjectId] INNER JOIN StatusAlias sa on sa.[Id] = c2.[StatusAliasId] INNER JOIN requisiteType rt on cr.[RequisiteTypeId] = rt.[Id] INNER JOIN Condition con on cr.[ConditionId] = con.[Id] INNER JOIN @entity e on c1.[Id] = e.[EntityId] and c1.[Id] = @entityId ) AS t GROUP BY Id, ReqTypeId, ReqTypeTitle FOR JSON AUTO ) SET @_entitySummary = ( SELECT CONCAT( dbo.fnHtmlOpenTag( ''div'', [dbo].[fnHtmlConcatTagAttributes]( ''[{"Key":"class","Value":"section"},{"Key":"title","Value":"Course Requisites"}]'', 0 ) ), dbo.concat_agg([ReqText]), dbo.fnHtmlCloseTag(''div'') ) FROM OPENJSON(@_entityData) WITH ( [ReqText] nvarchar(max) ''$.ReqText'' ) ) SELECT (CASE WHEN @_entitySummary IS NULL THEN '' '' ELSE @_entitySummary END) AS [Text], @entityId AS [Value];',2,@queryAttributes),
('Course in Programs',null,'SET @_entityData =( SELECT c1.[Id] AS [Key], dbo.concat_agg( dbo.fnHtmlElement( ''div'', CONCAT( p.[EntityTitle], '' ('', dbo.fnHtmlElement(''span'', p.[Status], ''{"Key":"class","Value":"status-alias"}''), '')''), NULL ) ) AS [Text] FROM Course c1 INNER JOIN @entity e on c1.[Id] = e.[EntityId] AND c1.[Id] = @entityId CROSS APPLY ( SELECT p.[Id] AS ProgramId, p.[EntityTitle], p.[StatusAliasId], sa.[Title] AS [Status] FROM Program P INNER JOIN StatusAlias sa on p.[StatusAliasId] = sa.[Id] WHERE EXISTS ( SELECT TOP 1 1 FROM CourseOption co INNER JOIN ProgramCourse pc on co.[Id] = pc.[CourseOptionId] WHERE pc.CourseId = c1.[Id] AND co.ProgramId = p.[Id] ) AND sa.statusBaseId NOT IN (3,5,7,8) ) p GROUP BY c1.Id FOR JSON PATH ) SET @_entitySummary = ( SELECT CONCAT( dbo.fnHtmlOpenTag(''div'', dbo.fnHtmlAttribute(''class'', ''section'')), dbo.fnHtmlStandardLargeField( ''Course in Programs'', [Text], NULL, NULL, '': '', 0 ), dbo.fnHtmlCloseTag(''div'') ) FROM OPENJSON(@_entityData) WITH ( [Text] nvarchar(max) ''$.Text'' ) ) SELECT (CASE WHEN @_entitySummary IS NULL THEN '' '' ELSE @_entitySummary END) AS [Text], @entityId AS [Value];',4,@queryAttributes),
('Program Basics',null,'SET @_entityData =( SELECT p.[Id] AS [Id], dbo.fnHtmlField( ''div'', ''span'', ''span'', dbo.fnHtmlElement(''span'', ''Program Title'', NULL), @_entityTitle, ''{ "Key" :"class", "Value" :"field-wrapper-first-child" }'', NULL, NULL, '': '', 0) AS [Title],( CASE WHEN oe.[Title] IS NULL THEN '''' ELSE dbo.fnHtmlStandardSimplefield(''Discipline'', oe.[Title], null, null, '': '', 0) END ) AS [Discipline], ( CASE WHEN at.[Title] IS NULL THEN '''' ElSE dbo.fnHtmlStandardSimplefield(''Award Type'', at.[Title], null, null, '': '', 0) END ) AS [AwardType] FROM [program] p INNER JOIN OrganizationEntity oe ON p.[Tier1_OrganizationEntityId] = oe.[Id] INNER JOIN AwardType at ON p.[AwardTypeId] = at.[Id] INNER JOIN @entity e ON p.[Id] = e.[EntityId] and p.[Id] = @entityId FOR JSON AUTO ) SET @_EntitySummary = ( SELECT CONCAT( dbo.fnHtmlOpenTag( ''div'', [dbo].[fnHtmlConcatTagAttributes]( ''[{"Key":"class","Value":"section"},{"Key":"title","Value":"Program Basics"}]'', 0 ) ), [Title], [Discipline], [AwardType], dbo.fnHtmlCloseTag(''section'') ) FROM OPENJSON(@_entityData) with ( [Title] nvarchar(max) ''$.Title'', [Discipline] nvarchar(max) ''$.Discipline'', [AwardType] nvarchar(max) ''$.AwardType'' ) ) SELECT ( CASE WHEN @_entitySummary IS NULL THEN '' '' ELSE @_entitySummary END ) AS [Text], @entityId AS [Value];',0,@queryAttributes),
('Empty Cell',null,'SELECT '' '' AS [Text],@entityId AS [Value];',100,@queryAttributes);


insert into [Report].[AgendaReportQueryMapping]
VALUES
(1,1,null),
(3,null,1),
(3,null,2),
(3,null,3),
(4,null,1),
(5,null,1),
(6,null,1),
(7,null,2),
(8,null,1),
(8,null,2);


if (@hasPackages = 1)
BEGIN
    insert into [Report].[AgendaReportQuery]
    VALUES
    ('Package Basics',null,'select concat( @_entityTitle, dbo.[fnHtmlStandardSimplefield]( ''Subject'', s.Title, null,null,'': '',0) ) as [Text], @entityId as [Value] from Package p inner Join [Subject] s on p.SubjectId = s.Id inner join @entity e on p.Id = e.EntityId where e.EntityId = @entityId;',0,@queryAttributes),
    ('Package Courses',null,'declare @_entityQueryResults [dbo].[StringPair]; declare @_entities TABLE( [EntityId] int, [Level] int, [LevelNumStyle] nvarchar(max), [ReportLink] nvarchar(max), [Title] nvarchar(max), [Number] nvarchar(max), [GroupId] int, [Text] nvarchar(max), [EntityTypeId] int, [SortOrder] int); INSERT INTO @_entities select c.Id as [EntityId], e.[Level] + 1 AS [Level], null AS [LevelNumStyle], NULL [ReportLink], c.Title as [Title], null as [Number], p.Id as [GroupId], null as [Text], 1 as [EntityTypeId], ROW_NUMBER() OVER(ORDER BY c.Id) as [SortOrder] from Package p inner join PackageCourse pc on p.Id = pc.PackageId inner join Course c on pc.CourseId = c.Id inner join @entity e on p.Id = e.EntityId where p.Id = @entityId; declare @_params NVARCHAR(max) =( SELECT * FROM @_entities FOR JSON AUTO, INCLUDE_NULL_VALUES ); declare @_paramsJson nvarchar(max) = JSON_MODIFY(''{"name":"entityParams", "type":"string"}'', ''$.value'', @_params); DECLARE @_prefix NVARCHAR(max) = '' DECLARE @entity Table( [EntityId] int, [Level] int, [LevelNumStyle] nvarchar(max), [ReportLink] nvarchar(max), [Title] nvarchar(max), [Number] nvarchar(max), [SortOrder] int ); INSERT INTO @entity SELECT * FROM OPENJSON(@entityParams) WITH ( [EntityId] int ''''$.EntityId'''', [Level] int ''''$.Level'''', [LevelNumStyle] nvarchar(max) ''''$.LevelNumStyle'''', [ReportLink] nvarchar(max) ''''$.ReportLink'''', [Title] nvarchar(max) ''''$.Title'''', [Number] nvarchar(max) ''''$.Number'''', [SortOrder] int ''''$.SortOrder'''' ); DECLARE @_entityData nvarchar(max), @_entitySummary nvarchar(max), @_entityNumber nvarchar(max) = ( SELECT (CASE WHEN [Number] IS NOT NULL THEN CONCAT( [dbo].[fnHtmlOpenTag](''''span'''', [dbo].[fnHtmlAttribute](''''class'''', ''''marker'''')), (CASE WHEN [Number] IS NOT NULL THEN [Number] WHEN [Number] IS NULL OR [Number] = '''''''' THEN CAST([SortOrder] AS nvarchar(max)) END), ''''. '''', [dbo].[fnHtmlClosetag](''''span'''') ) ELSE CONCAT( [dbo].[fnHtmlOpenTag](''''span'''', [dbo].[fnHtmlAttribute](''''class'''', ''''marker'''')), [dbo].[fnHtmlListMarker]([SortOrder], LevelNumStyle, 0, ''''. ''''), [dbo].[fnHtmlClosetag](''''span'''') ) END) FROM @entity WHERE [EntityId] = @entityId ), @_entityTitle nvarchar(max) = ( SELECT (CASE WHEN [ReportLink] IS NOT NULL THEN CONCAT ( [dbo].[fnHtmlOpenTag](''''a'''', dbo.fnHtmlAttribute(''''href'''', [ReportLink])), [Title], [dbo].[fnHtmlCloseTag](''''a'''') ) ELSE [Title] END) FROM @entity WHERE [EntityId] = @entityId );''; INSERT INTO @_entityQueryResults SELECT ( SELECT r.[Value] AS [Key], ( Select [Value] FROM [dbo].[fnSearchJson](arq.[AttributesJson], ''columnId'', null, ''1'') ) AS [ColumnId], e.[Level] AS [Level] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER ) AS [String1], CONCAT( [dbo].[fnHtmlOpenTag](''td'', [dbo].[fnHtmlConcatTagAttributes](arq.[AttributesJson], 0)), [dbo].[ConcatOrdered_Agg]([arq].[SortOrder], [r].[Text], 1), [dbo].[fnHtmlCloseTag](''td'') ) AS [String2] FROM [Report].[AgendaReportQuery] arq INNER JOIN [Report].[AgendaReportQueryMapping] arqm ON arq.[Id] = arqm.[AgendaReportQueryId] CROSS APPLY ( SELECT CONCAT(''['',@_paramsJson,'']'') AS [Params] ) ep CROSS APPLY ( SELECT [EntityId], [SortOrder], [EntityTypeId], [Level] FROM @_entities ) e CROSS APPLY dbo.[fnBulkResolveCustomSqlQuery]( CONCAT(@_prefix, arq.[QueryText]), 0, e.[EntityId], @clientId, null, null, ep.[Params] ) r WHERE arqm.[EntityTypeId] = e.[EntityTypeId] AND r.[Text] IS NOT NULL GROUP BY r.[Value], JSON_VALUE(arq.[AttributesJson], ''$[0].ColumnId''), arq.[AttributesJson], e.[Level]; UPDATE e SET e.[Text] = CONCAT( dbo.[fnHtmlOpenTag](''tr'', dbo.[fnHtmlAttribute](''class'',CONCAT(''level-'',res.[Level]))), res.[Text], dbo.[fnHtmlCloseTag](''tr'') ) FROM @_entities e INNER JOIN ( SELECT JSON_VALUE(d.[String1], ''$.Key'') AS [Id], JSON_VALUE(d.[String1], ''$.Level'') AS [Level], dbo.[ConcatOrdered_Agg](JSON_VALUE(d.[String1], ''$.ColumnId''),d.[String2],1) AS [Text] FROM @_entityQueryResults d GROUP BY JSON_VALUE(d.[String1], ''$.Key''), JSON_VALUE(d.[String1], ''$.Level'') ) AS res ON e.[EntityId] = res.[Id]; SET @_entitySummary = ( SELECT CONCAT( dbo.fnHtmlOpenTag(''table'',dbo.[fnHtmlConcatTagAttributes](''[{"Key":"class","Value":"section"},{"Key":"title","Value":"Package Courses"}]'',0)), dbo.[ConcatOrdered_Agg](e.[SortOrder], e.[Text], 1), dbo.fnHtmlCloseTag(''table'') ) FROM @_entities e WHERE e.[GroupId] = @entityId ) SELECT (CASE WHEN @_entitySummary IS NULL THEN '' '' ELSE @_entitySummary END) AS [Text], @entityId AS [Value];',1,@queryAttributes),
    ('Package Programs',null,'declare @_entityQueryResults [dbo].[StringPair]; declare @_entities TABLE( [EntityId] int, [Level] int, [LevelNumStyle] nvarchar(max), [ReportLink] nvarchar(max), [Title] nvarchar(max), [Number] nvarchar(max), [GroupId] int, [Text] nvarchar(max), [EntityTypeId] int, [SortOrder] int); INSERT INTO @_entities select c.Id as [EntityId], e.[Level] + 1 AS [Level], null AS [LevelNumStyle], NULL [ReportLink], c.Title as [Title], null as [Number], p.Id as [GroupId], null as [Text], 2 as [EntityTypeId], ROW_NUMBER() OVER(ORDER BY pr.Id) as [SortOrder] from Package p inner join PackageProgram pp on p.Id = pp.PackageId inner join Program pr on pp.ProgramId = pr.Id inner join @entity e on p.Id = e.EntityId where p.Id = @entityId; declare @_params NVARCHAR(max) =( SELECT * FROM @_entities FOR JSON AUTO, INCLUDE_NULL_VALUES ); declare @_paramsJson nvarchar(max) = JSON_MODIFY(''{"name":"entityParams", "type":"string"}'', ''$.value'', @_params); DECLARE @_prefix NVARCHAR(max) = '' DECLARE @entity Table( [EntityId] int, [Level] int, [LevelNumStyle] nvarchar(max), [ReportLink] nvarchar(max), [Title] nvarchar(max), [Number] nvarchar(max), [SortOrder] int ); INSERT INTO @entity SELECT * FROM OPENJSON(@entityParams) WITH ( [EntityId] int ''''$.EntityId'''', [Level] int ''''$.Level'''', [LevelNumStyle] nvarchar(max) ''''$.LevelNumStyle'''', [ReportLink] nvarchar(max) ''''$.ReportLink'''', [Title] nvarchar(max) ''''$.Title'''', [Number] nvarchar(max) ''''$.Number'''', [SortOrder] int ''''$.SortOrder'''' ); DECLARE @_entityData nvarchar(max), @_entitySummary nvarchar(max), @_entityNumber nvarchar(max) = ( SELECT (CASE WHEN [Number] IS NOT NULL THEN CONCAT( [dbo].[fnHtmlOpenTag](''''span'''', [dbo].[fnHtmlAttribute](''''class'''', ''''marker'''')), (CASE WHEN [Number] IS NOT NULL THEN [Number] WHEN [Number] IS NULL OR [Number] = '''''''' THEN CAST([SortOrder] AS nvarchar(max)) END), ''''. '''', [dbo].[fnHtmlClosetag](''''span'''') ) ELSE CONCAT( [dbo].[fnHtmlOpenTag](''''span'''', [dbo].[fnHtmlAttribute](''''class'''', ''''marker'''')), [dbo].[fnHtmlListMarker]([SortOrder], LevelNumStyle, 0, ''''. ''''), [dbo].[fnHtmlClosetag](''''span'''') ) END) FROM @entity WHERE [EntityId] = @entityId ), @_entityTitle nvarchar(max) = ( SELECT (CASE WHEN [ReportLink] IS NOT NULL THEN CONCAT ( [dbo].[fnHtmlOpenTag](''''a'''', dbo.fnHtmlAttribute(''''href'''', [ReportLink])), [Title], [dbo].[fnHtmlCloseTag](''''a'''') ) ELSE [Title] END) FROM @entity WHERE [EntityId] = @entityId );''; INSERT INTO @_entityQueryResults SELECT ( SELECT r.[Value] AS [Key], ( Select [Value] FROM [dbo].[fnSearchJson](arq.[AttributesJson], ''columnId'', null, ''1'') ) AS [ColumnId], e.[Level] AS [Level] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER ) AS [String1], CONCAT( [dbo].[fnHtmlOpenTag](''td'', [dbo].[fnHtmlConcatTagAttributes](arq.[AttributesJson], 0)), [dbo].[ConcatOrdered_Agg]([arq].[SortOrder], [r].[Text], 1), [dbo].[fnHtmlCloseTag](''td'') ) AS [String2] FROM [Report].[AgendaReportQuery] arq INNER JOIN [Report].[AgendaReportQueryMapping] arqm ON arq.[Id] = arqm.[AgendaReportQueryId] CROSS APPLY ( SELECT CONCAT(''['',@_paramsJson,'']'') AS [Params] ) ep CROSS APPLY ( SELECT [EntityId], [SortOrder], [EntityTypeId], [Level] FROM @_entities ) e CROSS APPLY dbo.[fnBulkResolveCustomSqlQuery]( CONCAT(@_prefix, arq.[QueryText]), 0, e.[EntityId], @clientId, null, null, ep.[Params] ) r WHERE arqm.[EntityTypeId] = e.[EntityTypeId] AND r.[Text] IS NOT NULL GROUP BY r.[Value], JSON_VALUE(arq.[AttributesJson], ''$[0].ColumnId''), arq.[AttributesJson], e.[Level]; UPDATE e SET e.[Text] = CONCAT( dbo.[fnHtmlOpenTag](''tr'', dbo.[fnHtmlAttribute](''class'',CONCAT(''level-'',res.[Level]))), res.[Text], dbo.[fnHtmlCloseTag](''tr'') ) FROM @_entities e INNER JOIN ( SELECT JSON_VALUE(d.[String1], ''$.Key'') AS [Id], JSON_VALUE(d.[String1], ''$.Level'') AS [Level], dbo.[ConcatOrdered_Agg](JSON_VALUE(d.[String1], ''$.ColumnId''),d.[String2],1) AS [Text] FROM @_entityQueryResults d GROUP BY JSON_VALUE(d.[String1], ''$.Key''), JSON_VALUE(d.[String1], ''$.Level'') ) AS res ON e.[EntityId] = res.[Id]; SET @_entitySummary = ( SELECT CONCAT( dbo.fnHtmlOpenTag(''table'',dbo.[fnHtmlConcatTagAttributes](''[{"Key":"class","Value":"section"},{"Key":"title","Value":"Package Courses"}]'',0)), dbo.[ConcatOrdered_Agg](e.[SortOrder], e.[Text], 1), dbo.fnHtmlCloseTag(''table'') ) FROM @_entities e WHERE e.[GroupId] = @entityId ) SELECT (CASE WHEN @_entitySummary IS NULL THEN '' '' ELSE @_entitySummary END) AS [Text], @entityId AS [Value];',2,@queryAttributes);
    insert into [Report].[AgendaReportQueryMapping]
    VALUES
    (9,null,3),
    (10,null,3),
    (11,null,3);
END;


insert into [Report].[AgendaReportQueryMapping]
select q.Id as [AgendaReportQueryId], s.Id as [AgendaReportSectionId], null as [EntityTypeId]
from [Report].[AgendaReportQuery] q
cross apply (
    select Id from [Report].[AgendaReportSection]
) s
where q.Id = 2 and s.Id <> 1;


insert into [Report].[AgendaReportConfiguration]
VALUES
(@layoutId,3,'[{"name":"Number","type":"column","enabled":false},{"name":"OrganizationEntity","type":"column","enabled":false},{"name":"OrganizationEntity","type":"filter","enabled":false},{"name":"Package","type":"column","enabled":false},{"name":"Package","type":"filter","enabled":false},{"name":"Subject","type":"column","enabled":false},{"name":"Subject","type":"filter","enabled":true},{"name":"AwardType","type":"column","enabled":false},{"name":"AwardType","type":"filter","enabled":true},{"name":"Position","type":"column","enabled":false},{"name":"Position","type":"filter","enabled":true},{"name":"ProposalType","type":"column","enabled":true},{"name":"ProposalType","type":"filter","enabled":true}]',0,1,@clientId);


insert into [Report].[AgendaReportAttributeType]
VALUES
('css','css');

declare @attType int = SCOPE_IDENTITY();


insert into [Report].[AgendaReportAttribute]
VALUES
('body','font-family:Arial,Helvetica,sans-serif; font-size:10pt; width: 100%;margin-left:auto;margin-right:auto;',@attType),
('table','border-collapse:collapse;border-spacing:5pt;column-gap:0;column-width:0;',@attType),
('.header h1','font-size:18pt;',@attType),
('.header h2','font-size:15pt;margin-bottom:0;',@attType),
('.header div','font-weight:normal;',@attType),
('.marker,.field-label,#level-0','font-weight: bold;',@attType),
('.col1','border-right:1px solid;',@attType),
('#level-0 td, #level-0 > td','font-size:12pt;padding:5pt 0;',@attType),
('#level-1,#level-1 .section, #level-1 > td > span','margin-left: 10pt',@attType),
('#level-2 .section, #level-2 > td > span','margin-left: 20pt',@attType),
('#level-1','text-decoration:underline;',@attType),
('#level-2 td','padding: 5pt 0;',@attType),
('#level-2 .col1','text-align:center;',@attType),
('th','border:1px solid;padding:5pt;',@attType),
('.field-wrapper-first-child','margin-left: 5pt;',@attType),
('.field-wrapper,.reqtype-title','margin-left: 5pt;',@attType),
('.req-text','margin-left: 27pt;',@attType),
('.empty','margin:0;padding:0;line-height:0;',@attType),
('table.section .col1','border:none;',@attType);

exec upGetUpdateClientSetting @setting = 'AllowNewAgendaReport', @newValue = 1, @clientId = 1, @valuedatatype = 'bit', @section = 'Reports'

INSERT INTO ClientReports
(Title, ClientReportsGroupId, ClientReportsConfigurationId, ClientId, SortOrder, StartDate)
VALUES
('Agenda Report', 23, 8, 1, 1, GETDATE())
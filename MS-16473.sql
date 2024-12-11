USE [hancockcollege];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16473';
DECLARE @Comments nvarchar(Max) = 
	'Update Program Mapper tab';
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
Declare @clientId int =1, -- SELECT Id, Title FROM Client 
	@Entitytypeid int =2; -- SELECT * FROM EntityType (1 = course, 2 = program, 6 = module)

declare @templateId integers

INSERT INTO @templateId
SELECT mt.MetaTemplateId
FROM MetaTemplateType mtt
    INNER JOIN MetaTemplate mt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
WHERE mt.Active = 1 
    AND mtt.EntityTypeId = @entityTypeId
    AND mt.IsDraft = 0
    AND mt.EndDate IS NULL
    AND mtt.Active = 1
    AND mtt.IsPresentationView = 0		--comment out if doing reports and forms
    AND mtt.ClientId = @clientId
		--AND mtt.MetaTemplateTypeId in ()		--comment back in if just doing some of the mtt's

declare @FieldCriteria table (
	TabName nvarchar(255) index ixRecalcFieldCriteria_TabName,
	TableName sysname index ixRecalcFieldCriteria_TableName,
	ColumnName sysname index ixRecalcFieldCriteria_ColumnName,
	Action nvarchar(max)
);
/************************* Put fields Here ***********************
*************************Only Edit Values************************/
insert into @FieldCriteria (TabName, TableName, ColumnName,Action)
values
('Program Mapper', 'CourseOption', 'CourseOptionNote','Update')

declare @Fields table (
	FieldId int primary key,
	SectionId int,
	Action nvarchar(max),
	TabId int,
	TemplateId int,
	sortorder int,
	mtt int
);

insert into @Fields (FieldId,SectionId,Action,TabId,TemplateId,sortorder, mtt)
select msf.metaselectedfieldid,msf.MetaSelectedSectionId,rfc.Action,mss.MetaSelectedSectionId,mss.MetaTemplateId ,msf.RowPosition, mt.MetaTemplateTypeId
from MetaTemplate mt
inner join MetaSelectedSection mss
	on mt.MetaTemplateId = mss.MetaTemplateId
inner join MetaSelectedSection mss2
	on mss.MetaSelectedSectionId = mss2.MetaSelectedSection_MetaSelectedSectionId
inner join MetaSelectedField msf
	on mss2.MetaSelectedSectionId = msf.MetaSelectedSectionId
inner join MetaAvailableField maf
	on msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
inner join @FieldCriteria rfc
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName and mss.SectionName = rfc.TabName)		--uncomment tab name if tempalate have different tab name (likely in reports)
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/
Drop Table if Exists #SeedIds
Create Table #SeedIds (row_num int,Id int)
;WITH x AS (SELECT n FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) v(n)),Numbers as(
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL))  as Id
FROM x ones, x tens, x hundreds--, x thousands, x tenthousands, x hundredthousands
)	Merge #SeedIds as t
	Using (
	  select Id from Numbers
	  )
	As s 
	on 1=0
	When not matched and s.Id < 100000 then
	insert (Id)
	Values(s.Id);

	delete from #SeedIds where exists (Select Id from MetaForeignKeyCriteriaClient mfkcc where mfkcc.Id = #SeedIds.Id)

	Merge #SeedIds as t
	using (
			SELECT  ROW_NUMBER() OVER (
			ORDER BY Id
		   ) row_num, Id from #SeedIds
	)as s on s.Id = t.Id
	When  matched then Update
	Set t.row_num = s.row_num;
	Select * from #SeedIds Order by row_num asc

DECLARE @MAX int = (SELECT Id FROM #SeedIds WHERE row_num = 1)
DECLARE @MAX2 int = (SELECT Id FROM #SeedIds WHERE row_num = 2)
DECLARE @MAX3 int = (SELECT Id FROM #SeedIds WHERE row_num = 3)
DECLARE @MAX4 int = (SELECT Id FROM #SeedIds WHERE row_num = 4)
DECLARE @MAX5 int = (SELECT Id FROM #SeedIds WHERE row_num = 5)

SET QUOTED_IDENTIFIER OFF

DECLARE @CSQL NVARCHAR(MAX) = "

declare @results table (Value int, Text varchar(max), FilterValue int);

declare @courseid int = (
    select CourseId
    from ProgramCourse
    where id = @pkIdValue
)

declare @requisiteTable table(	SortOrder int,	Title nvarchar(max));
declare @igetcTable table(	SortOrder int,	Title nvarchar(max));
declare @csugeTable table(	SortOrder int,	Title nvarchar(max));
declare @smcgeTable table(	SortOrder int,	Title nvarchar(max));


insert into @requisiteTable (SortOrder, Title)
select 	row_number() over (order by cr.SortOrder, cr.Id) as SortOrder,	isnull('<li class=""list-group-item-compact""><strong>' + rt.Title + ':</strong> ' + s.SubjectCode + ' ' + rc.CourseNumber + '</li>','<li class=""list-group-item-compact""><strong>' + rt.Title + ':</strong> ' + cr.CourseRequisiteComment + '</li>') + isnull(' ' + con.Title,'') as Title
from 	Course c 	
    inner join CourseRequisite cr 	
        left join Condition con on con.Id = cr.ConditionId
        on cr.CourseId = c.Id 
    left join Course rc on cr.Requisite_CourseId = rc.Id	
    left join Subject s on rc.SubjectId = s.Id	
    inner join RequisiteType rt on cr.RequisiteTypeId = rt.Id 
where 	c.Id = @courseid
order by	cr.SortOrder

insert into @igetcTable (SortOrder, Title)	
select		row_number() over (order by geg.Id, ge.Title, gee.Title) as SortOrder,		'<li class=""list-group-item-compact"">' + gee.Title + '</li>' as Title	
from 		CourseGeneralEducation cge		
    inner join GeneralEducationElement gee on cge.GeneralEducationElementId = gee.Id		
    inner join GeneralEducation ge on gee.GeneralEducationId = ge.Id		
    inner join GeneralEducationGroup geg on ge.GeneralEducationGroupId = geg.Id	
where 		CourseId = @courseid		and geg.Id = 1		and geg.Active = 1		and ge.Active = 1		and gee.Active = 1;

insert into @csugeTable (SortOrder, Title)	
select		row_number() over (order by geg.Id, ge.Title, gee.Title) as SortOrder,		'<li class=""list-group-item-compact"">' + gee.Title + '</li>' as Title	
from 		CourseGeneralEducation cge		
    inner join GeneralEducationElement gee on cge.GeneralEducationElementId = gee.Id		
    inner join GeneralEducation ge on gee.GeneralEducationId = ge.Id		
    inner join GeneralEducationGroup geg on ge.GeneralEducationGroupId = geg.Id	
where 		CourseId = @courseid		and geg.Id = 2		and geg.Active = 1		and ge.Active = 1		and gee.Active = 1;

insert into @smcgeTable (SortOrder, Title)	
select		row_number() over (order by geg.Id, ge.Title, gee.Title) as SortOrder,		'<li class=""list-group-item-compact"">' + gee.Title + '</li>' as Title	
from 		CourseGeneralEducation cge		
    inner join GeneralEducationElement gee on cge.GeneralEducationElementId = gee.Id		
    inner join GeneralEducation ge on gee.GeneralEducationId = ge.Id		
    inner join GeneralEducationGroup geg on ge.GeneralEducationGroupId = geg.Id	
where 		CourseId = @courseid		and geg.Id = 3		and geg.Active = 1		and ge.Active = 1		and gee.Active = 1;

declare @requisites nvarchar(max) = 
    (
        select dbo.fnHtmlOpenTag('ol', dbo.fnHtmlAttribute('class', 'list-group px-2'))+cli.CombinedRequisites+dbo.fnHtmlCloseTag('ol') as Text
        from (    select        dbo.ConcatWithSepOrdered_Agg(null, SortOrder, Title) as CombinedRequisites    from @requisiteTable rt) cli
    );

declare @igetc nvarchar(max) = 
    (
        select dbo.fnHtmlOpenTag('label', dbo.fnHtmlAttribute('class', 'font-weight-bold font-italic py-1'))+'IGETC'+dbo.fnHtmlCloseTag('label')+dbo.fnHtmlOpenTag('ol', dbo.fnHtmlAttribute('class', 'list-group px-2'))+cli.CombinedIGETC+dbo.fnHtmlCloseTag('ol') as Text
        from (    select        dbo.ConcatWithSepOrdered_Agg(null, SortOrder, Title) as CombinedIGETC    from @igetcTable rt) cli
    );
declare @csuge nvarchar(max) = 
    (
        select dbo.fnHtmlOpenTag('label', dbo.fnHtmlAttribute('class', 'font-weight-bold font-italic py-1'))+'CSU GE'+dbo.fnHtmlCloseTag('label')+dbo.fnHtmlOpenTag('ol', dbo.fnHtmlAttribute('class', 'list-group px-2'))+cli.CombinedCSUGE+dbo.fnHtmlCloseTag('ol') as Text
        from (    select        dbo.ConcatWithSepOrdered_Agg(null, SortOrder, Title) as CombinedCSUGE    from @csugeTable rt) cli
    );
declare @smcge nvarchar(max) = 
    (
        select dbo.fnHtmlOpenTag('label', dbo.fnHtmlAttribute('class', 'font-weight-bold font-italic py-1'))+'SMC GE'+dbo.fnHtmlCloseTag('label')+dbo.fnHtmlOpenTag('ol', dbo.fnHtmlAttribute('class', 'list-group px-2'))+cli.CombinedSMCGE+dbo.fnHtmlCloseTag('ol') as Text
        from (    select        dbo.ConcatWithSepOrdered_Agg(null, SortOrder, Title) as CombinedSMCGE    from @smcgeTable rt) cli
    );
    
declare @gc nvarchar(max) = (select '<li class=""list-group-item-compact py-2""><strong><i class=""fa fa-globe pr-1""></i>Satisfies Global Citizenship</strong></li>' from CourseGlobalCitizenship cgc where IsApproved = 1 and CourseId = @courseid);
declare @de nvarchar(max) = (select '<li class=""list-group-item-compact py-2""><strong><i class=""pr-1""></i>Transfers to '+case when ComparableCsuUc = 1 AND ISCSUTransfer = 1 then 'UC/CSU' when ComparableCsuUc = 1 then 'CSU' when ISCSUTransfer = 1 then 'UC' else null end +'</strong></li>' from Course where (ComparableCsuUc = 1 OR ISCSUTransfer = 1) and Id = @courseid);
----------------------------------------------------
insert into @results (Value,Text,FilterValue)
select 0 as Value, concat(	dbo.fnHtmlOpenTag('div', dbo.fnHtmlAttribute('class', 'pl-2 pr-2 pb-2 pt-0')) + @requisites + dbo.fnHtmlCloseTag('div'), dbo.fnHtmlOpenTag('div', dbo.fnHtmlAttribute('class', 'px-2'))+concat(@igetc, @csuge, @smcge)+dbo.fnHtmlCloseTag('div'),dbo.fnHtmlOpenTag('div','')+concat(@gc,@de)+dbo.fnHtmlCloseTag('div')) as Text, @courseid as FilterValue;

delete from @requisiteTable;
delete from @igetcTable;
delete from @csugeTable;
delete from @smcgeTable;

select * from @results;
"

DECLARE @RSQL NVARCHAR(MAX) = "
Select Null
"

DECLARE @CSQL2 NVARCHAR(MAX) = "
select co.Id as Value, left(isnull(CourseOptionNote,p.Title),200) as Text 
from CourseOption co 
join program p on p.Id = co.ProgramId AND p.Active = 1
join ProposalType pt on p.ProposalTypeId = pt.Id
join ClientEntityType cet on cet.Id = pt.ClientEntityTypeId
where p.Id = @EntityId
order by case when p.Id = @EntityId then 0 else 1 end, isnull(CourseOptionNote,p.Title)
"

DECLARE @RSQL2 NVARCHAR(MAX) = "
select co.Id as Value, left(isnull(CourseOptionNote,p.Title),200) as Text 
from CourseOption co 
join program p on p.Id = co.ProgramId
where co.Id = @id
"

DECLARE @CSQL3 NVARCHAR(MAX) = "
SELECT CONCAT(l.ShortText, ' - ', l.LongText) as Text, l.id as Value from lookup10 l
	INNER JOIN Lookup10 l2 on l.Lookup10ParentId = l2.Id and l2.ShortText = 'Term/year lookup'
UNION
SELECT CONCAT(l.ShortText, ' - ', l.LongText) as Text, l.id as Value from lookup10 l
	INNER JOIN ProgramCourse pc on l.id = pc.Lookup10Id 
	INNER JOIN CourseOption co on pc.CourseOptionId = co.id and co.ProgramId = @entityID
"

DECLARE @RSQL3 NVARCHAR(MAX) = "
 SELECT CONCAT(l.ShortText, ' - ', l.LongText) as Text from lookup10 l
 WHERE l.id = @id
"

DECLARE @CSQL4 NVARCHAR(MAX) = "
select c.Id as [Value]
	, c.EntityTitle as [Text]
	, s.SubjectCode
	, c.CourseNumber
from Course c
	inner join ProgramSequence ps on c.Id = ps.CourseId
	inner join [Subject] s on ps.SubjectId = s.Id
where ps.ProgramId = @entityId
order by s.SubjectCode, cast(dbo.RegEx_Replace(c.CourseNumber, '[^0-9]', '') as int);
"

DECLARE @RSQL4 NVARCHAR(MAX) = "
select EntityTitle as [Text]
from Course
where Id = @id;
"

DECLARE @CSQL5 NVARCHAR(MAX) = "

select 0 as Value, '<div style=""float:right;""><strong>Total Units: </strong>' + case
                    when sum(CalcMin) is not null and sum(CalcMax) is not null
                        and sum(CalcMin) <> sum(CalcMax)
                        then format(sum(CalcMin), 'F1')
                        + '-' + format(sum(CalcMax), 'F1')
                    when sum(CalcMin) is not null
                        then format(sum(CalcMin), 'F1')
                    when sum(CalcMax) is not null
                        then format(sum(CalcMax), 'F1')
                    else '0'
                end + '</div>' as Text
from CourseOption
where ProgramId = @entityId
AND (
    (Calculate = 0 AND DoNotCalculate = 0)
    OR
    (Calculate = 1 AND DoNotCalculate = 0)
    OR
    (Calculate = 1 AND DoNotCalculate = 1)
)
group by ProgramId
"

DECLARE @RSQL5 NVARCHAR(MAX) = "

select 0 as Value, '<div style=""float:right;""><strong>Total Units: </strong>' + case
                    when sum(CalcMin) is not null and sum(CalcMax) is not null
                        and sum(CalcMin) <> sum(CalcMax)
                        then format(sum(CalcMin), 'F1')
                        + '-' + format(sum(CalcMax), 'F1')
                    when sum(CalcMin) is not null
                        then format(sum(CalcMin), 'F1')
                    when sum(CalcMax) is not null
                        then format(sum(CalcMax), 'F1')
                    else '0'
                end + '</div>' as Text
from CourseOption
where ProgramId = @entityId
AND (
    (Calculate = 0 AND DoNotCalculate = 0)
    OR
    (Calculate = 1 AND DoNotCalculate = 0)
    OR
    (Calculate = 1 AND DoNotCalculate = 1)
)
group by ProgramId
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'Course', 'Id', 'Title', @CSQL, @RSQL, 'Order By SortOrder', 'Program Pathway look up', 3),
(@MAX2, 'CourseOption', 'Id', 'CourseOptionNote', @CSQL2, @RSQL2, 'Order By SortOrder', 'Program Pathway look up', 3),
(@MAX3, 'lookup10', 'Id', 'Title', @CSQL3, @RSQL3, 'Order By SortOrder', 'Program Pathway look up', 2),
(@MAX4, 'Course', 'Id', 'Title', @CSQL4, @RSQL4, 'Order By SortOrder', 'Program Pathway look up', 2),
(@MAX5, 'YesNo', 'Id', 'Title', @CSQL5, @RSQL5, 'Order By SortOrder', 'Program Pathway look up', 3)

DECLARE @Sections INTEGERS
INSERT INTO @Sections
SELECT SectionId FROM @Fields WHERE Action = 'Update'

while exists(select top 1 1 from @Sections)
begin
    declare @TID int = (select top 1 * from @Sections)
    EXEC spBuilderSectionDelete @clientId, @TID
    delete @Sections
    where id = @TID
end

DECLARE @TOP TABLE (TemplateId int, secId int, nam nvarchar(max))

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
output inserted.MetaTemplateId, inserted. MetaSelectedSectionId, inserted.SectionName INTO @TOP
SELECT
1, -- [ClientId]
TabID, -- [MetaSelectedSection_MetaSelectedSectionId]
NULL, -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
0, -- [RowPosition]
0, -- [SortOrder]
1, -- [SectionDisplayId]
1, -- [MetaSectionTypeId]
TemplateId, -- [MetaTemplateId]
NULL, -- [DisplayFieldId]
NULL, -- [HeaderFieldId]
NULL, -- [FooterFieldId]
0, -- [OriginatorOnly]
NULL, -- [MetaBaseSchemaId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EntityListLibraryTypeId]
NULL, -- [EditMapId]
1, -- [AllowCopy]
0, -- [ReadOnly]
NULL-- [Config]
FROM @Fields
UNION
SELECT
1, -- [ClientId]
TabId, -- [MetaSelectedSection_MetaSelectedSectionId]
'Program Mapper', -- [SectionName]
1, -- [DisplaySectionName]
'Drag and drop a to reorder items.', -- [SectionDescription]
0, -- [DisplaySectionDescription]
0, -- [ColumnPosition]
1, -- [RowPosition]
1, -- [SortOrder]
1, -- [SectionDisplayId]
31, -- [MetaSectionTypeId]
TemplateId, -- [MetaTemplateId]
NULL, -- [DisplayFieldId]
NULL, -- [HeaderFieldId]
NULL, -- [FooterFieldId]
0, -- [OriginatorOnly]
159, -- [MetaBaseSchemaId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EntityListLibraryTypeId]
NULL, -- [EditMapId]
1, -- [AllowCopy]
0, -- [ReadOnly]
NULL-- [Config]
FROM @Fields

DECLARE @SUB TABLE (TempId int, SecId int, nam nvarchar(max))

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
output inserted.MetaTemplateId, inserted.MetaSelectedSectionId, inserted.SectionName INTO @SUB
SELECT
1, -- [ClientId]
secId, -- [MetaSelectedSection_MetaSelectedSectionId]
'Program Courses', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
0, -- [ColumnPosition]
0, -- [RowPosition]
0, -- [SortOrder]
1, -- [SectionDisplayId]
31, -- [MetaSectionTypeId]
TemplateId, -- [MetaTemplateId]
NULL, -- [DisplayFieldId]
NULL, -- [HeaderFieldId]
NULL, -- [FooterFieldId]
0, -- [OriginatorOnly]
164, -- [MetaBaseSchemaId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EntityListLibraryTypeId]
NULL, -- [EditMapId]
1, -- [AllowCopy]
0, -- [ReadOnly]
NULL-- [Config]
FROM @TOP WHERE nam = 'Program Mapper'

DECLARE @SubSub TABLE (TempId int, SecId int, nam nvarchar(max), rowid int)

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
output inserted.MetaTemplateId, inserted.MetaSelectedSectionId, inserted.SectionName, inserted.RowPosition INTO @SubSub
SELECT
1, -- [ClientId]
SecId, -- [MetaSelectedSection_MetaSelectedSectionId]
'', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
0, -- [ColumnPosition]
1, -- [RowPosition]
1, -- [SortOrder]
1, -- [SectionDisplayId]
11, -- [MetaSectionTypeId]
TempId, -- [MetaTemplateId]
NULL, -- [DisplayFieldId]
NULL, -- [HeaderFieldId]
NULL, -- [FooterFieldId]
0, -- [OriginatorOnly]
164, -- [MetaBaseSchemaId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EntityListLibraryTypeId]
NULL, -- [EditMapId]
1, -- [AllowCopy]
0, -- [ReadOnly]
NULL-- [Config]
FROM @SUB
UNION
SELECT
1, -- [ClientId]
SecId, -- [MetaSelectedSection_MetaSelectedSectionId]
'', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
0, -- [ColumnPosition]
2, -- [RowPosition]
2, -- [SortOrder]
1, -- [SectionDisplayId]
11, -- [MetaSectionTypeId]
TempId, -- [MetaTemplateId]
NULL, -- [DisplayFieldId]
NULL, -- [HeaderFieldId]
NULL, -- [FooterFieldId]
0, -- [OriginatorOnly]
164, -- [MetaBaseSchemaId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EntityListLibraryTypeId]
NULL, -- [EditMapId]
1, -- [AllowCopy]
0, -- [ReadOnly]
NULL-- [Config]
FROM @SUB
UNION
SELECT
1, -- [ClientId]
SecId, -- [MetaSelectedSection_MetaSelectedSectionId]
'[Exception Section]', -- [SectionName]
0, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
0, -- [ColumnPosition]
3, -- [RowPosition]
3, -- [SortOrder]
1, -- [SectionDisplayId]
11, -- [MetaSectionTypeId]
TempId, -- [MetaTemplateId]
NULL, -- [DisplayFieldId]
NULL, -- [HeaderFieldId]
NULL, -- [FooterFieldId]
0, -- [OriginatorOnly]
164, -- [MetaBaseSchemaId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EntityListLibraryTypeId]
NULL, -- [EditMapId]
1, -- [AllowCopy]
0, -- [ReadOnly]
NULL-- [Config]
FROM @SUB

DECLARE @Blah TABLE (fieldId int, nam nvarchar(max), typeId int)

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
output inserted.MetaSelectedFieldId, inserted.DisplayName, inserted.MetaPresentationTypeId INTO @Blah
SELECT
'Map Header', -- [DisplayName]
2552, -- [MetaAvailableFieldId]
secId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'CKEditor', -- [DefaultDisplayType]
25, -- [MetaPresentationTypeId]
100, -- [Width]
2, -- [WidthUnit]
200, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
1, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
1, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @TOP WHERE nam IS NULL
UNION
SELECT
'Map Footer', -- [DisplayName]
2553, -- [MetaAvailableFieldId]
SecId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
1, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'CKEditor', -- [DefaultDisplayType]
25, -- [MetaPresentationTypeId]
100, -- [Width]
2, -- [WidthUnit]
200, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
1, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
1, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @TOP WHERE nam IS NULL
UNION
SELECT
'Program Requirement Block Definition', -- [DisplayName]
477, -- [MetaAvailableFieldId]
SecId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Textarea', -- [DefaultDisplayType]
17, -- [MetaPresentationTypeId]
100, -- [Width]
2, -- [WidthUnit]
100, -- [Height]
1, -- [HeightUnit]
0, -- [AllowLabelWrap]
1, -- [LabelHAlign]
1, -- [LabelVAlign]
1, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
1, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @TOP WHERE nam = 'Program Mapper'
UNION
SELECT
'Sequence Order', -- [DisplayName]
917, -- [MetaAvailableFieldId]
secID, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
1, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'TelerikCombo', -- [DefaultDisplayType]
33, -- [MetaPresentationTypeId]
150, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
NULL, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
5, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @TOP WHERE nam = 'Program Mapper'
UNION
SELECT
'Header', -- [DisplayName]
471, -- [MetaAvailableFieldId]
SecId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
3, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'CKEditor', -- [DefaultDisplayType]
25, -- [MetaPresentationTypeId]
100, -- [Width]
2, -- [WidthUnit]
100, -- [Height]
1, -- [HeightUnit]
0, -- [AllowLabelWrap]
1, -- [LabelHAlign]
1, -- [LabelVAlign]
1, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
1, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @TOP WHERE nam = 'Program Mapper'
UNION
SELECT
'Footer', -- [DisplayName]
472, -- [MetaAvailableFieldId]
SecID, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
4, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'CKEditor', -- [DefaultDisplayType]
25, -- [MetaPresentationTypeId]
100, -- [Width]
2, -- [WidthUnit]
100, -- [Height]
1, -- [HeightUnit]
0, -- [AllowLabelWrap]
1, -- [LabelHAlign]
1, -- [LabelVAlign]
1, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
1, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @TOP WHERE nam = 'Program Mapper'
UNION
SELECT
'Course', -- [DisplayName]
1375, -- [MetaAvailableFieldId]
SecId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'DropDown', -- [DefaultDisplayType]
33, -- [MetaPresentationTypeId]
400, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
1, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
5, -- [FieldTypeId]
2, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
@MAX4, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @SUB WHERE nam = 'Program Courses'
UNION
SELECT
'Group Name', -- [DisplayName]
1018, -- [MetaAvailableFieldId]
SecId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
1, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Textbox', -- [DefaultDisplayType]
1, -- [MetaPresentationTypeId]
300, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
NULL, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
1, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @SUB WHERE nam = 'Program Courses'
UNION
SELECT
'Non-Course Requirements', -- [DisplayName]
1175, -- [MetaAvailableFieldId]
SecId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
2, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Textbox', -- [DefaultDisplayType]
1, -- [MetaPresentationTypeId]
300, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
NULL, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
1, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @SUB WHERE nam = 'Program Courses'
UNION
SELECT
'Sequence Order', -- [DisplayName]
916, -- [MetaAvailableFieldId]
SecId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
1, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'TelerikCombo', -- [DefaultDisplayType]
33, -- [MetaPresentationTypeId]
150, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
NULL, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
5, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @SubSub WHERE rowid = 1
UNION
SELECT
'Program Requirement Block Reference', -- [DisplayName]
7586, -- [MetaAvailableFieldId]
SecId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
2, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'TelerikCombo', -- [DefaultDisplayType]
33, -- [MetaPresentationTypeId]
150, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
NULL, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
5, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
@MAX2, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @SubSub WHERE rowid = 1
UNION
SELECT
'Type of Course', -- [DisplayName]
6677, -- [MetaAvailableFieldId]
SecId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
3, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'TelerikCombo', -- [DefaultDisplayType]
33, -- [MetaPresentationTypeId]
150, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
NULL, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
5, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @SubSub WHERE rowid = 1
UNION
SELECT
'Year/Term', -- [DisplayName]
4785, -- [MetaAvailableFieldId]
SecId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
8, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'TelerikCombo', -- [DefaultDisplayType]
33, -- [MetaPresentationTypeId]
150, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
NULL, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
5, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
@MAX3, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @SubSub WHERE rowid = 1
UNION
SELECT
'Footer', -- [DisplayName]
1019, -- [MetaAvailableFieldId]
SecId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
9, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Textbox', -- [DefaultDisplayType]
1, -- [MetaPresentationTypeId]
300, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
NULL, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
1, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @SubSub WHERE rowid = 1
UNION
SELECT
'Course Detail', -- [DisplayName]
4788, -- [MetaAvailableFieldId]
SecId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'QueryText', -- [DefaultDisplayType]
1, -- [MetaPresentationTypeId]
300, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
0, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
NULL, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
5, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
1, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
@MAX, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @SubSub WHERE rowid = 2
UNION
SELECT
'Exception Identifier', -- [DisplayName]
1135, -- [MetaAvailableFieldId]
SecId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Textbox', -- [DefaultDisplayType]
1, -- [MetaPresentationTypeId]
150, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
1, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
1, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @SubSub WHERE rowid = 3
UNION
SELECT
'Exception', -- [DisplayName]
1163, -- [MetaAvailableFieldId]
SecId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
1, -- [RowPosition]
0, -- [ColPosition]
2, -- [ColSpan]
'Textarea', -- [DefaultDisplayType]
17, -- [MetaPresentationTypeId]
100, -- [Width]
2, -- [WidthUnit]
100, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
1, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
1, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @SubSub WHERE rowid = 3

INSERT INTO ListSequenceNumber
(IntSequence, SortOrder, ClientId, StartDate)
VALUES
(1, 1, 1, GETDATE()),
(2, 2, 1, GETDATE()),
(3, 3, 1, GETDATE()),
(4, 4, 1, GETDATE()),
(5, 5, 1, GETDATE()),
(6, 6, 1, GETDATE()),
(7, 7, 1, GETDATE()),
(8, 8, 1, GETDATE()),
(9, 9, 1, GETDATE()),
(10, 10, 1, GETDATE()),
(11, 11, 1, GETDATE()),
(12, 12, 1, GETDATE()),
(13, 13, 1, GETDATE()),
(14, 14, 1, GETDATE()),
(15, 15, 1, GETDATE()),
(16, 16, 1, GETDATE()),
(17, 17, 1, GETDATE()),
(18, 18, 1, GETDATE()),
(19, 19, 1, GETDATE()),
(20, 20, 1, GETDATE()),
(21, 21, 1, GETDATE()),
(22, 22, 1, GETDATE()),
(23, 23, 1, GETDATE()),
(24, 24, 1, GETDATE()),
(25, 25, 1, GETDATE()),
(26, 26, 1, GETDATE()),
(27, 27, 1, GETDATE()),
(28, 28, 1, GETDATE()),
(29, 29, 1, GETDATE()),
(30, 30, 1, GETDATE()),
(31, 31, 1, GETDATE()),
(32, 32, 1, GETDATE()),
(33, 33, 1, GETDATE()),
(34, 34, 1, GETDATE()),
(35, 35, 1, GETDATE()),
(36, 36, 1, GETDATE()),
(37, 37, 1, GETDATE()),
(38, 38, 1, GETDATE()),
(39, 39, 1, GETDATE()),
(40, 40, 1, GETDATE()),
(41, 41, 1, GETDATE()),
(42, 42, 1, GETDATE()),
(43, 43, 1, GETDATE()),
(44, 44, 1, GETDATE()),
(45, 45, 1, GETDATE()),
(46, 46, 1, GETDATE()),
(47, 47, 1, GETDATE()),
(48, 48, 1, GETDATE()),
(49, 49, 1, GETDATE()),
(50, 50, 1, GETDATE()),
(51, 51, 1, GETDATE()),
(52, 52, 1, GETDATE()),
(53, 53, 1, GETDATE()),
(54, 54, 1, GETDATE()),
(55, 55, 1, GETDATE()),
(56, 56, 1, GETDATE()),
(57, 57, 1, GETDATE()),
(58, 58, 1, GETDATE()),
(59, 59, 1, GETDATE()),
(60, 60, 1, GETDATE()),
(61, 61, 1, GETDATE()),
(62, 62, 1, GETDATE()),
(63, 63, 1, GETDATE()),
(64, 64, 1, GETDATE()),
(65, 65, 1, GETDATE()),
(66, 66, 1, GETDATE()),
(67, 67, 1, GETDATE()),
(68, 68, 1, GETDATE()),
(69, 69, 1, GETDATE()),
(70, 70, 1, GETDATE()),
(71, 71, 1, GETDATE()),
(72, 72, 1, GETDATE()),
(73, 73, 1, GETDATE()),
(74, 74, 1, GETDATE()),
(75, 75, 1, GETDATE()),
(76, 76, 1, GETDATE()),
(77, 77, 1, GETDATE()),
(78, 78, 1, GETDATE()),
(79, 79, 1, GETDATE()),
(80, 80, 1, GETDATE()),
(81, 81, 1, GETDATE()),
(82, 82, 1, GETDATE()),
(83, 83, 1, GETDATE()),
(84, 84, 1, GETDATE()),
(85, 85, 1, GETDATE()),
(86, 86, 1, GETDATE()),
(87, 87, 1, GETDATE()),
(88, 88, 1, GETDATE()),
(89, 89, 1, GETDATE()),
(90, 90, 1, GETDATE()),
(91, 91, 1, GETDATE()),
(92, 92, 1, GETDATE()),
(93, 93, 1, GETDATE()),
(94, 94, 1, GETDATE()),
(95, 95, 1, GETDATE()),
(96, 96, 1, GETDATE()),
(97, 97, 1, GETDATE()),
(98, 98, 1, GETDATE()),
(99, 99, 1, GETDATE()),
(100, 100, 1, GETDATE()),
(101, 101, 1, GETDATE()),
(102, 102, 1, GETDATE()),
(103, 103, 1, GETDATE()),
(104, 104, 1, GETDATE()),
(105, 105, 1, GETDATE()),
(106, 106, 1, GETDATE()),
(107, 107, 1, GETDATE()),
(108, 108, 1, GETDATE()),
(109, 109, 1, GETDATE()),
(110, 110, 1, GETDATE()),
(111, 111, 1, GETDATE()),
(112, 112, 1, GETDATE()),
(113, 113, 1, GETDATE()),
(114, 114, 1, GETDATE()),
(115, 115, 1, GETDATE()),
(116, 116, 1, GETDATE()),
(117, 117, 1, GETDATE()),
(118, 118, 1, GETDATE()),
(119, 119, 1, GETDATE()),
(120, 120, 1, GETDATE()),
(121, 121, 1, GETDATE()),
(122, 122, 1, GETDATE()),
(123, 123, 1, GETDATE()),
(124, 124, 1, GETDATE()),
(125, 125, 1, GETDATE()),
(126, 126, 1, GETDATE()),
(127, 127, 1, GETDATE()),
(128, 128, 1, GETDATE()),
(129, 129, 1, GETDATE()),
(130, 130, 1, GETDATE()),
(131, 131, 1, GETDATE()),
(132, 132, 1, GETDATE()),
(133, 133, 1, GETDATE()),
(134, 134, 1, GETDATE()),
(135, 135, 1, GETDATE()),
(136, 136, 1, GETDATE()),
(137, 137, 1, GETDATE()),
(138, 138, 1, GETDATE()),
(139, 139, 1, GETDATE()),
(140, 140, 1, GETDATE()),
(141, 141, 1, GETDATE()),
(142, 142, 1, GETDATE()),
(143, 143, 1, GETDATE()),
(144, 144, 1, GETDATE()),
(145, 145, 1, GETDATE()),
(146, 146, 1, GETDATE()),
(147, 147, 1, GETDATE()),
(148, 148, 1, GETDATE()),
(149, 149, 1, GETDATE()),
(150, 150, 1, GETDATE()),
(151, 151, 1, GETDATE()),
(152, 152, 1, GETDATE()),
(153, 153, 1, GETDATE()),
(154, 154, 1, GETDATE()),
(155, 155, 1, GETDATE()),
(156, 156, 1, GETDATE()),
(157, 157, 1, GETDATE()),
(158, 158, 1, GETDATE()),
(159, 159, 1, GETDATE()),
(160, 160, 1, GETDATE()),
(161, 161, 1, GETDATE()),
(162, 162, 1, GETDATE()),
(163, 163, 1, GETDATE()),
(164, 164, 1, GETDATE()),
(165, 165, 1, GETDATE()),
(166, 166, 1, GETDATE()),
(167, 167, 1, GETDATE()),
(168, 168, 1, GETDATE()),
(169, 169, 1, GETDATE()),
(170, 170, 1, GETDATE()),
(171, 171, 1, GETDATE()),
(172, 172, 1, GETDATE()),
(173, 173, 1, GETDATE()),
(174, 174, 1, GETDATE()),
(175, 175, 1, GETDATE()),
(176, 176, 1, GETDATE()),
(177, 177, 1, GETDATE()),
(178, 178, 1, GETDATE()),
(179, 179, 1, GETDATE()),
(180, 180, 1, GETDATE()),
(181, 181, 1, GETDATE()),
(182, 182, 1, GETDATE()),
(183, 183, 1, GETDATE()),
(184, 184, 1, GETDATE()),
(185, 185, 1, GETDATE()),
(186, 186, 1, GETDATE()),
(187, 187, 1, GETDATE()),
(188, 188, 1, GETDATE()),
(189, 189, 1, GETDATE()),
(190, 190, 1, GETDATE()),
(191, 191, 1, GETDATE()),
(192, 192, 1, GETDATE()),
(193, 193, 1, GETDATE()),
(194, 194, 1, GETDATE()),
(195, 195, 1, GETDATE()),
(196, 196, 1, GETDATE()),
(197, 197, 1, GETDATE()),
(198, 198, 1, GETDATE()),
(199, 199, 1, GETDATE()),
(200, 200, 1, GETDATE());

INSERT INTO Lookup10
(Lookup10ParentId, ClientId, ShortText, LongText, SortOrder, StartDate)
VALUES
(NULL, 1, 'Term/year lookup', NULL, 1, GETDATE())

DECLARE @VALUE int = SCOPE_IDENTITY()

INSERT INTO Lookup10
(Lookup10ParentId, ClientId, ShortText, LongText, SortOrder, StartDate)
VALUES
(@VALUE, 1, 'Year 1', 'Fall', 1, GETDATE()),
(@VALUE, 1, 'Year 1', 'Spring', 2, GETDATE()),
(@VALUE, 1, 'Year 1', 'Summer', 3, GETDATE()),
(@VALUE, 1, 'Year 2', 'Fall', 4, GETDATE()),
(@VALUE, 1, 'Year 2', 'Spring', 5, GETDATE()),
(@VALUE, 1, 'Year 2', 'Summer', 6, GETDATE())

INSERT INTO CourseTypeProgram
(ClientId, Title, SortOrder, StartDate)
VALUES
(1, 'Prerequisite', 1, GETDATE()),
(1, 'Prerequisite/General Education', 2, GETDATE()),
(1, 'Requirement', 3, GETDATE()),
(1, 'Requirement/General Education', 4, GETDATE()),
(1, 'General Education', 5, GETDATE()),
(1, 'Elective', 6, GETDATE())

INSERT INTO MetaSelectedFieldAttribute
(Name, Value, MetaSelectedFieldId)
SELECT 'listitemtype', '1', FieldId FROM @Blah WHERE nam = 'Course'
UNION
SELECT 'listitemtype', '3', FieldId FROM @Blah WHERE nam = 'Non-Course Requirements' and typeId = 1
UNION
SELECT 'listitemtype', '2', FieldId FROM @Blah WHERE nam = 'Group Name'
UNION
SELECT 'UpdateSubscriptionTable1', 'ProgramCourse', FieldId fROM @Blah WHERE nam = 'Course Detail'
UNION
SELECT 'UpdateSubscriptionColumn1', 'CourseId', FieldId fROM @Blah WHERE nam = 'Course Detail'

INSERT INTO MetaSelectedSectionAttribute
(Name, Value, MetaSelectedSectionId)
SELECT 'AllowCalcOverride', 'TRUE', SecId FROM @TOP WHERE nam = 'Program Mapper'
UNION
SELECT 'AllowConditions', 'TRUE', SecId FROM @TOP WHERE nam = 'Program Mapper'
UNION
SELECT 'AllowCalcExclude', 'TRUE', SecId FROM @TOP WHERE nam = 'Program Mapper'
UNION
SELECT 'AllowCalcOverride', 'TRUE', SecId FROM @SUB WHERE nam = 'Program Courses'
UNION
SELECT 'AllowConditions', 'TRUE', SecId FROM @SUB WHERE nam = 'Program Courses'
UNION
SELECT 'AllowCalcExclude', 'TRUE', SecId FROM @SUB WHERE nam = 'Program Courses'

UPDATE ProgramCourse
SET Header = MaxText01
WHERE Id = Id

UPDATE ProgramCourse
SET MaxText01 = NULL

UPDATE ListItemType 
SET ListItemTitleColumn = 'Header'
WHERE Id = 23

UPDATE CourseOption
SET CourseOptionNote = dbo.Format_RemoveAccents(dbo.stripHtml(CourseOptionNote))

UPDATE MetaSelectedField
SET DisplayName = '<div style="font-weight:normal;"><p>The pathway below represents an efficient and effective course taking sequence for this program.  Individual circumstances might require some changes to this pathway.  It is <em><strong>always</strong></em> recommended that you <strong>meet with an academic counselor</strong> to develop a personalized educational plan.</p><p>The courses have been intentionally placed and should be prioritized in the order in which they appear.  If you are unable to take all the courses in a semester, you should prioritize enrolling in the courses in the order below.  Some courses have been noted as “Appropriate for Intersession” <span style="display:inline-block;width:1em;height:1em;border-radius:50%;text-align:center;background:#084968!important;border:1px solid black;"><span style="color:white!important;top:-6px;font-size:8px;">IN</span></span>. Should you need (or want) to take classes in the summer and/or winter intersessions, the program recommends these courses as appropriate for the condensed schedule of the intersessions.</p><p>Some pathways combine a “Certificate of Achievement” and an “Associate Degree”.  If you are pursuing only the Certificate of Achievement, you are only required to take the courses marked “Program Requirement” <span style="display:inline-block;width:1em;height:1em;border-radius:50%;text-align:center;background:mediumvioletred!important;color:white;border:1px solid black;"><span style="position:relative;color:white!important;top:-5px;font-size:12px;">★</span></span>.</p><p>All pathways include at least one “Gateway Course”<span style="display:inline-block;width:1em;height:1em;border-radius:50%;text-align:center;background:green!important;color:white;border:1px solid black;"><span style="position:relative;color:white!important;top:-5px;font-size:12px;">!</span></span>which introduces you to the program and/or field of study and helps you decide if you want to continue with this Academic and Career Path. </p><p>Most Associate degrees (though not Associate Degrees for Transfer) require satisfying the SMC Global Citizenship requirement.  If the Program Requirements do not include a “Global Citizenship course”, be sure to select a General Education course that also satisfies Global Citizenship.</p></div>'
WHERE MetaSelectedFieldId in (
	SELECT msf.MetaSelectedFieldId fROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
	WHERE mtt.MetaTemplateTypeId = 37
	and msf.RowPosition = 1
)

UPDATE MetaSelectedField
SET DisplayName = '<div style="font-weight:normal;"> <p><span style="display:inline-block;width:1em;height:1em;border-radius:50%;text-align:center;background:green!important;color:white;border:1px solid black;"><span style="position:relative;color:white!important;top:-5px;font-size:12px;">!</span></span> Gateway<span style="display:inline-block;width:1em;height:1em;border-radius:50%;text-align:center;background:mediumvioletred!important;color:white;border:1px solid black;"><span style="color:white!important;top:-5px;font-size:12px;">★</span></span> Program Requirement<span style="display:inline-block;width:1em;height:1em;border-radius:50%;text-align:center;background:rebeccapurple!important;color:white;border:1px solid black;"><span style="color:white!important;top:-6px;font-size:8px;">GE</span></span> General Education<span style="display:inline-block;width:1em;height:1em;border-radius:50%;text-align:center;background:#0075df!important;color:white;border:1px solid black;"><span style="color:white!important;top:-6px;font-size:8px;">O</span></span> Available Online</p></div>'
WHERE MetaSelectedFieldId in (
	SELECT msf.MetaSelectedFieldId fROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
	WHERE mtt.MetaTemplateTypeId = 37
	and msf.RowPosition = 2
)

DECLARE @SQL NVARCHAR(MAX) = '
declare @inlineTag nvarchar(10) = ''span'';
declare @blockTag nvarchar(10) = ''div'';
declare @footnoteIdentifierTag nvarchar(10) = ''sup'';
declare @classAttrib nvarchar(10) = ''class'';
declare @empty nvarchar(1) = '''';
declare @space nvarchar(5) = '' '';

drop table if exists #renderedInjections;

create table #renderedInjections (
	TableName sysname,
	Id int,
	InjectionType nvarchar(255),
	RenderedText nvarchar(max),
	primary key (TableName, Id, InjectionType)
);

--#region ProgramCourse rendered injections - course entries
insert into #renderedInjections (TableName, Id, InjectionType, RenderedText)
select
	''ProgramCourse'' as TableName, pc.Id, ''CourseEntryRightColumn'',
	concat(
				/*case when len(ed.ExtraDetailsIcons) > 0 then concat(
					@space,
					dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(@classAttrib, ''course-entry-icons'')),
						ed.ExtraDetailsIcons,
					dbo.fnHtmlCloseTag(@inlineTag)
				) else @empty end,*/
            case when pc.Parent_Id is not null 
            then
			    dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, ''col-xs-1 col-sm-1 col-md-1'') + dbo.fnHtmlAttribute(''style'',''padding:0px;padding-right:4px;padding-top:5px;width:40%;''))
            else 
                dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, ''col-xs-1 col-sm-1 col-md-1'') + dbo.fnHtmlAttribute(''style'',''padding:0px;padding-top:5px;width:40%;''))
            end,
                ExtraDetailsIcons,
			dbo.fnHtmlCloseTag(@blockTag),			
            dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, ''col-xs-1 col-sm-1 col-md-1 text-right'') + dbo.fnHtmlAttribute(''style'',''float:right;padding:0px;width:60%;'')),
				dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(@classAttrib, ''units-display block-entry-units-display'')),
                    case 
                    when 
                        (pc.Calculate = 0 AND pc.DoNotCalculate = 0)
                        OR
                        (pc.Calculate = 1 AND pc.DoNotCalculate = 0)
                        OR
                        (pc.Calculate = 1 AND pc.DoNotCalculate = 1)
                    then
                        case
                            when pc.CalcMin is not null and pc.CalcMax is not null
                                and pc.CalcMin <> pc.CalcMax
                                then format(pc.CalcMin, ''F1'')
                                + ''-'' + format(pc.CalcMax, ''F1'')
                            when pc.CalcMin is not null
                                then format(pc.CalcMin, ''F1'')
                            when pc.CalcMax is not null
                                then format(pc.CalcMax, ''F1'')
                            else ''''
                        end
                    else 
                        ''''
                    end,
				dbo.fnHtmlCloseTag(@inlineTag),
			dbo.fnHtmlCloseTag(@blockTag)        
	) as RenderedText
from ProgramCourse pc
inner join CourseOption co on pc.CourseOptionId = co.Id
inner join Course c on pc.CourseId = c.Id
cross apply (
	select
		concat(
			case
				when pc.Bit01 = 1 then concat(
					dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(''style'', ''display:inline-block;width:1em;height:1em;border-radius:50%;text-align:center;background:green!important;font-weight:bold;border:1px solid black;'')),
                        dbo.fnHtmlOpenTag(@inlineTag,dbo.fnHtmlAttribute(''style'', ''position:relative;color:white!important;top:-5px;font-size:12px;'')),
                            ''!'',
					    dbo.fnHtmlCloseTag(@inlineTag),
					dbo.fnHtmlCloseTag(@inlineTag)
				)
				else @empty
			end,
			case
				when pc.CourseTypeProgramId IN (1,2,3,4) then concat(
					dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(''style'', ''display:inline-block;width:1em;height:1em;border-radius:50%;text-align:center;background:mediumvioletred!important;font-weight:bold;border:1px solid black;'')),
                        dbo.fnHtmlOpenTag(@inlineTag,dbo.fnHtmlAttribute(''style'', ''position:relative;color:white!important;top:-5px;font-size:12px;'')),
                            ''&#9733;'',
					    dbo.fnHtmlCloseTag(@inlineTag),
					dbo.fnHtmlCloseTag(@inlineTag)
				)
				else @empty
			end,
			case
				when CourseTypeProgramId IN (5,4,2) then concat(
					dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(''style'', ''display:inline-block;width:1em;height:1em;border-radius:50%;text-align:center;background:rebeccapurple!important;font-weight:bold;border:1px solid black;'')),
                        dbo.fnHtmlOpenTag(@inlineTag,dbo.fnHtmlAttribute(''style'', ''position:relative;color:white!important;top:-6px;font-size:8px;'')),
                            ''GE'',
					    dbo.fnHtmlCloseTag(@inlineTag),
					dbo.fnHtmlCloseTag(@inlineTag)
				)
				else @empty
			end,
			case
				when c.IsDistanceEd = 1 then concat(
					dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(''style'', ''display:inline-block;width:1em;height:1em;border-radius:50%;text-align:center;background:#0075df!important;font-weight:bold;border:1px solid black;'')),
                        dbo.fnHtmlOpenTag(@inlineTag,dbo.fnHtmlAttribute(''style'', ''color:white!important;position:relative;top:-6px;font-size:8px;'')),
                            ''O'',
					    dbo.fnHtmlCloseTag(@inlineTag),
					dbo.fnHtmlCloseTag(@inlineTag)
				)
				else @empty
			end
		) as ExtraDetailsIcons
) ed
where (
	co.ProgramId = @entityId
	or exists (
		select top 1 1
		from ProgramCourse pc2
		inner join CourseOption co2 on pc2.CourseOptionId = co2.Id
		where co2.ProgramId = @entityId
		and pc.Id = pc2.ReferenceId
	)
);
--#endregion ProgramCourse rendered injections - course entries

--#region ProgramCourse rendered injections - non-course entries
insert into #renderedInjections (TableName, Id, InjectionType, RenderedText)
select
	''ProgramCourse'' as TableName, pc.Id, ''NonCourseEntryRightColumn'',
	concat(
				/*case when len(ed.ExtraDetailsIcons) > 0 then concat(
					@space,
					dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(@classAttrib, ''course-entry-icons'')),
						ed.ExtraDetailsIcons,
					dbo.fnHtmlCloseTag(@inlineTag)
				) else @empty end,*/
            case when pc.Parent_Id is not null 
            then
			    dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, ''col-xs-1 col-sm-1 col-md-1'') + dbo.fnHtmlAttribute(''style'',''padding:0px;padding-right:4px;padding-top:5px;width:40%;''))
            else 
                dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, ''col-xs-1 col-sm-1 col-md-1'') + dbo.fnHtmlAttribute(''style'',''padding:0px;padding-top:5px;width:40%;''))
            end,
                ExtraDetailsIcons,
			dbo.fnHtmlCloseTag(@blockTag),			
            dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, ''col-xs-1 col-sm-1 col-md-1 text-right'') + dbo.fnHtmlAttribute(''style'',''float:right;padding:0px;width:60%;'')),
				dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(@classAttrib, ''units-display block-entry-units-display'')),
                    case 
                    when 
                        (pc.Calculate = 0 AND pc.DoNotCalculate = 0)
                        OR
                        (pc.Calculate = 1 AND pc.DoNotCalculate = 0)
                        OR
                        (pc.Calculate = 1 AND pc.DoNotCalculate = 1)
                    then
                        case
                            when pc.CalcMin is not null and pc.CalcMax is not null
                                and pc.CalcMin <> pc.CalcMax
                                then format(pc.CalcMin, ''F1'')
                                + ''-'' + format(pc.CalcMax, ''F1'')
                            when pc.CalcMin is not null
                                then format(pc.CalcMin, ''F1'')
                            when pc.CalcMax is not null
                                then format(pc.CalcMax, ''F1'')
                            else ''''
                        end
                    else 
                        ''''
                    end,
				dbo.fnHtmlCloseTag(@inlineTag),
			dbo.fnHtmlCloseTag(@blockTag)        
	) as RenderedText
from ProgramCourse pc
inner join CourseOption co on pc.CourseOptionId = co.Id
cross apply (
	select
		concat(
			case
				when pc.Bit01 = 1 then concat(
					dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(''style'', ''display:inline-block;width:1em;height:1em;border-radius:50%;text-align:center;background:green!important;font-weight:bold;border:1px solid black;'')),
                        dbo.fnHtmlOpenTag(@inlineTag,dbo.fnHtmlAttribute(''style'', ''position:relative;color:white!important;top:-5px;font-size:12px;'')),
                            ''!'',
					    dbo.fnHtmlCloseTag(@inlineTag),
					dbo.fnHtmlCloseTag(@inlineTag)
				)
				else @empty
			end,
			case
				when pc.CourseTypeProgramId IN (1,2,3,4) then concat(
					dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(''style'', ''display:inline-block;width:1em;height:1em;border-radius:50%;text-align:center;background:mediumvioletred!important;font-weight:bold;border:1px solid black;'')),
                        dbo.fnHtmlOpenTag(@inlineTag,dbo.fnHtmlAttribute(''style'', ''position:relative;color:white!important;top:-5px;font-size:12px;'')),
                            ''&#9733;'',
					    dbo.fnHtmlCloseTag(@inlineTag),
					dbo.fnHtmlCloseTag(@inlineTag)
				)
				else @empty
			end,
			case
				when CourseTypeProgramId IN (5,4,2) then concat(
					dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(''style'', ''display:inline-block;width:1em;height:1em;border-radius:50%;text-align:center;background:rebeccapurple!important;font-weight:bold;border:1px solid black;'')),
                        dbo.fnHtmlOpenTag(@inlineTag,dbo.fnHtmlAttribute(''style'', ''position:relative;color:white!important;top:-6px;font-size:8px;'')),
                            ''GE'',
					    dbo.fnHtmlCloseTag(@inlineTag),
					dbo.fnHtmlCloseTag(@inlineTag)
				)
				else @empty
			end
		) as ExtraDetailsIcons
) ed
where (
	co.ProgramId = @entityId
	or exists (
		select top 1 1
		from ProgramCourse pc2
		inner join CourseOption co2 on pc2.CourseOptionId = co2.Id
		where co2.ProgramId = @entityId
		and pc.Id = pc2.ReferenceId
	)
);
--#endregion ProgramCourse rendered injections - non-course entries

--#region ProgramCourse rendered injections - non-course entries
insert into #renderedInjections (TableName, Id, InjectionType, RenderedText)
select
	''ProgramCourse'' as TableName, pc.Id, ''NonCourseEntryLeftColumn'',
	concat(
		dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, ''row'')),
			dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, ''col-xs-9 col-sm-9 col-md-9'')),
				dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(@classAttrib, ''non-course-entry-title'')),
					t.ListItemTitle,
				dbo.fnHtmlCloseTag(@inlineTag),
			dbo.fnHtmlCloseTag(@blockTag),
			dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, ''col-xs-1 col-sm-1 col-md-1 text-right'')),
			dbo.fnHtmlCloseTag(@blockTag),
			dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, ''col-xs-1 col-sm-1 col-md-1'')),
				dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(@classAttrib, ''non-course-spacer'')),
					''&nbsp;'',
				dbo.fnHtmlCloseTag(@inlineTag),
			dbo.fnHtmlCloseTag(@blockTag),
		dbo.fnHtmlCloseTag(@blockTag)
	) as RenderedText
from ProgramCourse pc
inner join CourseOption co on (pc.CourseOptionId = co.Id and pc.CourseId is null)
left outer join ListItemType lit on pc.ListItemTypeId = lit.Id
cross apply (
	--Quick HACK
	--I am NOT calling fnResolveOrderedListEntryTitles from this query for exactly the reasons given
	--in the comment at the top of that function (tl;dr too fragile!)
	--Do not have time to engineer a better general solution given I was given this task today and told to have it done by tomorrow
	--So that is why I''m hard-coding the backing stores this way
	--Going off of the ordinal instead of the ListItemTypeId directly as the Non-Course requirement list item type
	--only exists on Sandbox, and I''m not sure how stable that Id (Currently 6) is, while the ordinals are much more
	--fixed in place so are more reliable for this logic
	select
		--pc.Header as ListItemTitle
		case lit.ListItemTypeOrdinal
			when 2 then pc.Header --2 = Group
			when 3 then pc.ProgramCourseRule --3 Non-Course Requirement
		end as ListItemTitle
) t
where (
	co.ProgramId = @entityId
	or exists (
		select top 1 1
		from ProgramCourse pc2
		inner join CourseOption co2 on pc2.CourseOptionId = co2.Id
		where co2.ProgramId = @entityId
		and pc.Id = pc2.ReferenceId
	)
);
--#endregion ProgramCourse rendered injections - non-course entries

--#region extra details queries
declare @programCourseExtraDetails nvarchar(max) =
''select
	Id as [Value], RenderedText as [Text]
from #renderedInjections ri
where ri.TableName = ''''ProgramCourse'''' and ri.Id = @id and ri.InjectionType = ''''CourseEntryRightColumn'''';'';

declare @programCourseNonCourseExtraDetails nvarchar(max) =
''select
	Id as [Value], RenderedText as [Text]
from #renderedInjections ri
where ri.TableName = ''''ProgramCourse'''' and ri.Id = @id and ri.InjectionType = ''''NonCourseEntryLeftColumn'''';'';

declare @programCourseNonCourseExtraDetailsRight nvarchar(max) =
''select
	Id as [Value], RenderedText as [Text]
from #renderedInjections ri
where ri.TableName = ''''ProgramCourse'''' and ri.Id = @id and ri.InjectionType = ''''NonCourseEntryRightColumn'''';'';

--#endregion extra details queries

declare @extraDetailsDisplay StringPair;

insert into @extraDetailsDisplay (String1, String2)
values
(''CourseEntryRightColumnReplacement'', @programCourseExtraDetails),
(''NonCourseEntryLeftColumnReplacement'', @programCourseNonCourseExtraDetails),
(''NonCourseEntryRightColumnReplacement'',@programCourseNonCourseExtraDetailsRight);


exec upGenerateGroupConditionsCourseBlockDisplay @entityId = @entityId, @extraDetailsDisplay = @extraDetailsDisplay, @creditHoursLabel = ''Semester Units:'', @outputTotal = 0;

drop table if exists #renderedInjections;
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE ID = 92

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
SELECT
NULL, -- [DisplayName]
3375, -- [MetaAvailableFieldId]
mss.MetaSelectedSectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
4, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'QueryText', -- [DefaultDisplayType]
103, -- [MetaPresentationTypeId]
150, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
NULL, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
5, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
@MAX5, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM MetaSelectedSection AS mss
INNER JOIN MetaSelectedSection AS mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
INNER JOIN MetaTemplate AS mt on mss2.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE mtt.MetaTemplateTypeId = 37
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields
UNION
SELECT MetaTemplateId FROM MetaTemplate WHERE MetaTemplateTypeId = 37)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback
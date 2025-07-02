USE [clovis];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18560';
DECLARE @Comments nvarchar(Max) = 
	'Update Assist Preview Tab';
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
Declare @clientId int =1, -- SELECT Id, Title FROM Client 
	@Entitytypeid int =1; -- SELECT * FROM EntityType (1 = course, 2 = program, 6 = module)

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
    AND mtt.IsPresentationView = 0	--comment out if doing reports and forms
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
('ASSIST Preview', 'CourseQueryText', 'QueryTextId_06','lecContent'),
('ASSIST Preview', 'CourseAssist', 'TextbookPreviewId','Textbook'),
('Cover', 'Course', 'Description', 'Honors'),
('ASSIST Preview', 'CourseAssist', 'ObjectivesId', 'Obj')

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
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName and rfc.TabName = mss.SectionName)		--uncomment tab name if tempalate have different tab name (likely in reports)
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/
insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
SELECT
'Is Honors', -- [DisplayName]
3433, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
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
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @Fields WHERE Action = 'Honors'

DECLARE @NewIds TABLE (Sort INT, MissingValue INT);
INSERT INTO @NewIds  
EXEC spGetMissingOrMaxIdentityValues 'MetaForeignKeyCriteriaClient', 'Id', 3;		--This 10 here is the amount of Id's it grabs

DECLARE @MAX int = (SELECT MissingValue FROM @NewIds WHERE Sort = 1)		--Create more Variables here using Sort if needed
DECLARE @MAX2 int = (SELECT MissingValue FROM @NewIds WHERE Sort = 2)
DECLARE @MAX3 int = (SELECT MissingValue FROM @NewIds WHERE Sort = 3)

SET QUOTED_IDENTIFIER OFF

DECLARE @SQL NVARCHAR(MAX) = "
DECLARE @CCN bit = (SELECT CASE WHEN YesNo07Id = 1 THEN 1 ELSE 0 END FROM CourseYesNo WHERE CourseId = @EntityId)

SELECT 0 AS Value,
CASE WHEN @CCN = 1
	THEN CONCAT('Part 1: <br>', TextMax18, '<br> Part 2:', TextMax01)
	ELSE TextMax01
END AS Text
FROM Course AS c
LEFT JOIN GenericMaxText AS gmt on gmt.CourseId = c.Id
WHERE c.Id = @EntityId
"

DECLARE @SQL2 NVARCHAR(MAX) = "
declare @Table TABLE (Id INT IDENTITY(1,1) PRIMARY KEY, Text NVARCHAR(MAX))
declare @sqlParts table (TableName nvarchar(max), SelectStatment nvarchar(max));
declare @sql nvarchar(max);
declare @results table (TextbookName varchar(max), TextbookAuthor varchar(max),TextbookPublicationYear varchar(max));
declare @attributes table (Attribute varchar(max), SortOrder int);
declare @partstemp table (TableName varchar(max), ColumnName varchar(max),Attribute varchar(max), SortOrder int);
insert into @attributes (Attribute,SortOrder)
values ('TextbookPublicationYear',3),('TextbookName',1),('TextbookAuthor',2);
insert into @partstemp
select distinct TableName,isnull(ColumnName,'null') as ColumnName,Attribute,a.SortOrder
from @attributes a
left join MetadataAttribute ma
        join MetaSelectedField msf on msf.MetadataAttributeMapId = ma.MetadataAttributeMapId
        join MetaAvailableField maf on maf.MetaAvailableFieldId = msf.MetaAvailableFieldId
        join MetaSelectedSection mss on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId
        join Course c on c.MetaTemplateId = mss.MetaTemplateId AND c.Id = @entityId
    on ma.ValueText = a.Attribute and MetadataAttributeTypeId = 13
order by a.SortOrder
insert into @sqlParts(TableName,SelectStatment)
select distinct TableName, dbo.concatwithsepordered_agg(',',SortOrder,concat(ColumnName,' as ', Attribute)) as SelectStatment
from (select isnull(TableName,(select top 1 TableName from @partstemp where TableName is not null)) as TableName, ColumnName, Attribute,SortOrder from @partstemp) s
group by TableName;
if (select count(*) from @sqlParts) = 1
begin
set @sql =(select concat('select ', SelectStatment, ' from ', TableName,' where CourseId = @entityId') from @sqlParts);
insert into @results exec sp_executesql @sql, N'@entityId int', @entityId = @entityId
end 
else 
begin
    select '<span style=""color:red;"">There is an error in the configuration for textbooks.  This may prevent this course from uploading to ASSIST. Please contact CurrIQunet support</span>' as Text
end 

INSERT INTO @Table
select '<div style=""display:table-row;border-bottom:1px solid;""><span style=""display:table-cell;width:200px;"">Textbook Name</span><span style=""display:table-cell;width:200px;padding-left:2px;"">Textbook Author</span><span style=""display:table-cell;width:200px;padding-left:2px;"">Textbook Publication Year</span></div>' as Text
union all
select concat('<div style=""display:table-row;border-bottom:1px solid;""><span style=""display:table-cell;width:200px;"">',TextbookName,'</span><span style=""display:table-cell;width:200px;padding-left:2px;"">',TextbookAuthor,'</span><span style=""display:table-cell;width:200px;padding-left:2px;"">',TextbookPublicationYear,'</span></div>') as Text
from @results
union all
select '</div>' as Text

SELECT 0 AS Value,
dbo.ConcatWithSepOrdered_Agg('', Id, Text) AS Text FROM @Table
"

DECLARE @SQL3 NVARCHAR(MAX) = "
DECLARE @IsCCN bit = (SELECT CASE WHEN cyn.YesNo07Id = 1 THEN 1 ELSE 0 END FROM CourseYesNo cyn WHERE CourseId = @Entityid)

declare @objectives NVARCHAR(max)
select @objectives = CASE WHEN CourseId IS NULL THEN NULL ELSE
CONCAT('<li>',dbo.ConcatWithSepOrdered_Agg('<li>', SortOrder, Text)) END
from CourseObjective
where courseid = @EntityId
group by CourseId

SELECT 0 AS Value,
CASE WHEN @IsCCN = 1 THEN CONCAT('Part 1:', ISNULL(gmt.TextMax20, ' No Data Entered<br>'), 'Part 2:<br><ul>', @objectives, '</ul>')
ELSE CONCAT('<ul>', @objectives, '</ul>')
END AS Text
FROM Course AS c
LEFT JOIN GenericMaxText AS gmt on gmt.CourseId = c.Id
WHERE c.Id = @Entityid
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'CourseQueryText', 'Id', 'Title', @SQL, @SQL, 'Order By SortOrder', 'Lecture Content', 2),
(@MAX2, 'CourseAssist', 'Id', 'Title', @SQL2, @SQL2, 'Order By SortOrder', 'Textbooks', 2),
(@MAX3, 'CourseAssist', 'Id', 'Title', @SQL3, @SQL3, 'Order By SortOrder', 'Objectives', 2)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'lecContent'
)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX2
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Textbook'
)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX3
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Obj'
)
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback
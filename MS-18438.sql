USE [hkapa];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18438';
DECLARE @Comments nvarchar(Max) = 
	'Add Table of Contents feauture to reports';
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
('General Programme Information', 'Program', 'OverlapAnalysis','Ping')

declare @Fields table (
	FieldId int primary key,
	SectionId int,
	Action nvarchar(max),
	TabId int,
	TemplateId int,
	sortorder int,
	mtt int,
	sort int
);

insert into @Fields (FieldId,SectionId,Action,TabId,TemplateId,sortorder, mtt, sort)
select msf.metaselectedfieldid,msf.MetaSelectedSectionId,rfc.Action,mss.MetaSelectedSectionId,mss.MetaTemplateId ,msf.RowPosition, mt.MetaTemplateTypeId, mss2.RowPosition
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
DECLARE @Sections INTEGERS

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
output inserted.MetaSelectedSectionId INTO @Sections
SELECT
1, -- [ClientId]
TabId, -- [MetaSelectedSection_MetaSelectedSectionId]
'Programme Specifications Document Information', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
sort + 1, -- [RowPosition]
sort + 1, -- [SortOrder]
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

insert into MetaSelectedField 
(DisplayName,LabelVisible,LabelStyleId,MetaAvailableFieldId,MetaSelectedSectionId,RowPosition,ColSpan,DefaultDisplayType,MetaPresentationTypeId,Width,WidthUnit,Height,HeightUnit,IsRequired,ColPosition,FieldTypeId)
SELECT 'PSD Title Page Additional Information',1,1,2560,Id,3,2,'CKEditor',25,100,2,200,1,0,0,1 FROM @Sections
UNION
SELECT 'PSD Title Page Version Information',1,1,2561,Id,4,2,'CKEditor',25,100,2,200,1,0,0,1 FROM @Sections

insert into MetaSelectedSectionAttribute (Name, Value, MetaSelectedSectionId)
select 'TableOfContentsBookmark', mss.SectionName, mss.MetaSelectedSectionId 
from MetaSelectedSection AS mss
INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN @templateId AS t on mt.MetaTemplateId = t.Id
where mss.MetaSelectedSection_MetaSelectedSectionId is null
and len(mss.SectionName) > 0

update MetaReport
set ReportAttributes = JSON_MODIFY(ReportAttributes,'$.headerSQL','select concat(''<div class="text-center">'',''<div><img class="college-logo" src="'',i.ImagePath,''" title="The Hong Kong Academy for Performing Arts"/></div>'',
''<div class="h1 mt-5">'',coalesce(p.EntityTitle,p.Title,''''),''</div>'',
''<div class="mt-5">'',coalesce(gtm.TextMax09,''''),''</div>'',
''<div class="position-absolute top-50 w-100">'',
''<div class="h2 mt-5 text-center">'',r.Title,''</div>'',
''<div class="h2 mt-5 text-center">Prepared by ''+oe.Title+''</div>'',
''<div class="h2 mt-5 text-center">'',format(pp.ImplementDate,''d'', ''zh-hk''),''</div>'',
''<div class="h2 mt-5 text-center">''+s.Title+''</div>'',
''<div class="mt-5">'',coalesce(gtm.TextMax10,''''),''</div>'',
''</div>'',
''</div>'') AS Text
from Program p
join ProgramProposal pp on pp.ProgramId = p.Id
join GenericMaxText gtm on gtm.ProgramId = p.Id
left join OrganizationEntity oe on oe.Id = p.Tier1_OrganizationEntityId
left join Semester s on s.Id = pp.SemesterId
outer apply (select top 1 ImagePath from config.ClientSettingImage where ClientSettingId = 1 and ClientImageTypeId = 2 and Active = 1) i
outer apply (select top 1 Title from MetaReport where Id = @reportId) r
where p.Id = @entityId')
where Id = 462


update MetaReport
set ReportAttributes = JSON_MODIFY(ReportAttributes,'$.cssOverride','@media print {
    h3, .h3 {font-size: 1.25rem; margin-top: 0; margin-bottom: 0;} 
    .tg {width: 800 !important;  min-width: 0;} 
    th {font-size: 12px !important;} 
    td {font-size: 12px !important;}} 
    .h4, h4{font-size: 1.05rem} 
    .h5, h5{font-size: 0.95rem} 
    .h1, h1{font-size: 2rem} label, 
    .h1, .h2, .h3, .h4, .h5, .h6, h1, h2, h3, h4, h5, h6 {font-weight: 600;} 
    .col-md-12{break-inside: avoid;} b{font-weight:600} th{font-weight:500} 
    ol,ul{padding-left: 0.2rem; margin-left: 0.1rem;}
    ol ol, ol ul, ul ol, ul ul {padding-left: 0.5rem; margin-left: 0.5rem;}
    .toc {page-break-before:always;page-break-after:always;}')
where Id = 462

insert into MetaSelectedSectionAttribute (Name, Value, MetaSelectedSectionId)
select 'TableOfContentsBookmark',SectionName,MetaSelectedSectionId from MetaSelectedSection where MetaTEmplateId = 25 and MetaSelectedSection_MetaSelectedSectionId is null and len(SectionName) > 0
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (
select templateId FROM @Fields
UNION
SELECT 25
)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback
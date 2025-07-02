USE [madera];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19055';
DECLARE @Comments nvarchar(Max) = 
	'Update Course Outline Report';
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
    AND mtt.IsPresentationView = 1	--comment out if doing reports and forms
    AND mtt.ClientId = @clientId
		AND mtt.MetaTemplateTypeId in (7)		--comment back in if just doing some of the mtt's

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
('Online / Hybrid', 'GenericMaxText', 'TextMax05','1'),
('Online / Hybrid', 'GenericMaxText', 'TextMax10','2')

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
insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
SELECT
1, -- [ClientId]
TabId, -- [MetaSelectedSection_MetaSelectedSectionId]
'<p style= "font-size: calc(1.275rem + 0.15vw); margin-bottom:0;">What other pertinent information should be shared with the committee?</p>', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
11, -- [RowPosition]
11, -- [SortOrder]
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
FROM @Fields WHERE Action = '1'

DECLARE @Sec int = SCOPE_IDENTITY()

UPDATE MetaSelectedField
SET MetaSelectedSectionId = @Sec
, DisplayName = 'To help ensure that Title 5 Standards of Regular and Substantive Interaction is being met, faculty must have completed Distance Education training to the teach course in DE modality.<br>
Any Additional Notes'
, RowPosition = 0
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = '1'
)

UPDATE MetaSelectedFieldAttribute
SET Value = 'Only faculty who are approved to teach online as outlined in the DE Strategic plan with training on the latest DE legislation will be assigned to the online class.'
WHERE Id = 130

UPDATE MetaSelectedField
SET DisplayName = 'What other pertinent information should be shared with the committee?<br><br><p style="font-weight: 400;">Only faculty who are approved to teach online as outlined in the DE Strategic plan with training on the latest DE legislation will be assigned to the online class.</p>'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = '2'
)

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = 'DECLARE @Textbook TABLE (CourseId int, txt NVARCHAR(MAX))
INSERT INTO @Textbook
SELECT CourseId, dbo.ConcatWithSepOrdered_Agg(''<br>'', SortOrder, Title)
FROM CourseTextbook AS ct
WHERE ct.CourseId = @EntityId
group by CourseId

DECLARE @Textbook2 TABLE (CourseId int, txt NVARCHAR(MAX))
INSERT INTO @Textbook2
SELECT CourseId, dbo.ConcatWithSepOrdered_Agg(''<br>'', Id, MaxText02)
FROM GenericCourseMapping01 AS ct
WHERE ct.CourseId = @EntityId
group by CourseId

SELECT 0 AS Value,
CONCAT(''Textbooks Part - 1 <br>'', t.txt, ''<br>'',
''Textbooks Part - 2 <br>'', t2.txt) AS Text
FROM Course AS c
LEFT JOIN @Textbook AS t on t.CourseId = c.Id
LEFT JOIN @Textbook2 AS t2 on t2.CourseId = c.Id
WHERE c.Id = @EntityId'
, ResolutionSql = 'DECLARE @Textbook TABLE (CourseId int, txt NVARCHAR(MAX))
INSERT INTO @Textbook
SELECT CourseId, dbo.ConcatWithSepOrdered_Agg(''<br>'', SortOrder, Title)
FROM CourseTextbook AS ct
WHERE ct.CourseId = @EntityId
group by CourseId

DECLARE @Textbook2 TABLE (CourseId int, txt NVARCHAR(MAX))
INSERT INTO @Textbook2
SELECT CourseId, dbo.ConcatWithSepOrdered_Agg(''<br>'', Id, MaxText02)
FROM GenericCourseMapping01 AS ct
WHERE ct.CourseId = @EntityId
group by CourseId

SELECT 0 AS Value,
CONCAT(''Textbooks Part - 1 <br>'', t.txt, ''<br>'',
''Textbooks Part - 2 <br>'', t2.txt) AS Text
FROM Course AS c
LEFT JOIN @Textbook AS t on t.CourseId = c.Id
LEFT JOIN @Textbook2 AS t2 on t2.CourseId = c.Id
WHERE c.Id = @EntityId'
WHERE Id = 132
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (
select templateId FROM @Fields
UNION
SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId = 132
)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback
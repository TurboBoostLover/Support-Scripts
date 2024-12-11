USE [butte];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13271';
DECLARE @Comments nvarchar(Max) = 
	'Add Help text to Student Learning Outcomes/Objectives on the course form';
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
DEclare @clientId int =1, -- SELECT Id, Title FROM Client 
	@Entitytypeid int =1; -- SELECT * FROM EntityType (1 = course, 2 = program, 6 = module)

declare @templateId integers

insert into @templateId
select mt.MetaTemplateId
from MetaTemplateType mtt
inner join MetaTemplate mt
	on mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
where mtt.EntityTypeId = @Entitytypeid
and mt.Active = 1
and mt.IsDraft = 0
and mt.EndDate is NULL
and mtt.active = 1
and mtt.IsPresentationView = 0
and mtt.ClientId = @clientId

declare @FieldCriteria table (
	TabName nvarchar(255) index ixRecalcFieldCriteria_TabName,
	TableName sysname index ixRecalcFieldCriteria_TableName,
	ColumnName sysname index ixRecalcFieldCriteria_ColumnName,
	Action nvarchar(max)
);
/************************* Put fields Here ***********************
*************************Only Edit Values*************************
*/
insert into @FieldCriteria (TabName, TableName, ColumnName,Action)
values
('Student Learning Outcomes/Objectives', 'CourseOutcome', 'OutcomeText','FIND')

declare @Fields table (
	FieldId int primary key,
	SectionId int,
	Action nvarchar(max),
	TabId int,
	TemplateId int,
	sortorder int
);

insert into @Fields (FieldId,SectionId,Action,TabId,TemplateId,sortorder)
select msf.metaselectedfieldid,msf.MetaSelectedSectionId,rfc.Action,mss.MetaSelectedSectionId,mss.MetaTemplateId ,msf.RowPosition
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
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName and mss.SectionName = rfc.TabName)
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/
DECLARE @RealId TABLE (MS int)
INSERT INTO @RealId

SELECT MSS.MetaSelectedSectionId FROM MetaSelectedSection AS MSS
INNER JOIN MetaSelectedSection AS MSS2 ON MSS.MetaSelectedSection_MetaSelectedSectionId = MSS2.MetaSelectedSection_MetaSelectedSectionId
WHERE MSS.SortOrder = 0
AND MSS2.MetaSelectedSectionId IN (SELECT SectionId FROM @Fields WHERE Action = 'FIND')

Update MetaSelectedField
SET RowPosition = (RowPosition + 2)
WHERE MetaSelectedSectionId IN (SELECT * FROM @RealId)

insert into [MetaSelectedField]  
([DisplayName], 
[MetaAvailableFieldId], 
[MetaSelectedSectionId], 
[IsRequired], 
[MinCharacters], 
[MaxCharacters], 
[RowPosition], 
[ColPosition], 
[ColSpan], 
[DefaultDisplayType], 
[MetaPresentationTypeId], 
[Width], 
[WidthUnit], 
[Height], 
[HeightUnit], 
[AllowLabelWrap], 
[LabelHAlign], 
[LabelVAlign], 
[LabelStyleId], 
[LabelVisible], 
[FieldStyle], 
[EditDisplayOnly], 
[GroupName], 
[GroupNameDisplay], 
[FieldTypeId], 
[ValidationRuleId], 
[LiteralValue], 
[ReadOnly], 
[AllowCopy], 
[Precision], 
[MetaForeignKeyLookupSourceId], 
[MetadataAttributeMapId], 
[EditMapId], 
[NumericDataLength], 
[Config])
SELECT    
'Please select the appropriate ILO''s that pertain to each SLO. You May have to click on each SLO to make the ILOs appear.', -- [DisplayName]  
NULL,-- [MetaAvailableFieldId]  
MS, -- [MetaSelectedSectionId]  
0, -- [IsRequired]  
NULL, -- [MinCharacters]  
NULL, -- [MaxCharacters]  
0, -- [RowPosition]  
0, -- [ColPosition]  
1, -- [ColSpan]  
'StaticText', -- [DefaultDisplayType]  
35, -- [MetaPresentationTypeId]  
NULL, -- [Width]  
0, -- [WidthUnit]  
NULL, -- [Height]  
0, -- [HeightUnit]  
1, -- [AllowLabelWrap]  
0, -- [LabelHAlign]  
1, -- [LabelVAlign]  
NULL, -- [LabelStyleId]  
NULL, -- [LabelVisible]  
0, -- [FieldStyle]  
NULL, -- [EditDisplayOnly]  
NULL, -- [GroupName]  
NULL, -- [GroupNameDisplay]  
2, -- [FieldTypeId]  
NULL, -- [ValidationRuleId]  
NULL, -- [LiteralValue]  
0, -- [ReadOnly]  
1, -- [AllowCopy]  
NULL, -- [Precision]  
NULL, -- [MetaForeignKeyLookupSourceId]  
NULL, -- [MetadataAttributeMapId]  
NULL, -- [EditMapId]  
NULL, -- [NumericDataLength]  
NULL-- [Config]  )
FROM @RealId

/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2


--commit
--rollback
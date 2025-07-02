USE [socccd];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18339';
DECLARE @Comments nvarchar(Max) = 
	'Update COR Report';
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
Declare @clientId int =2, -- SELECT Id, Title FROM Client 
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
		AND mtt.MetaTemplateTypeId in (24)		--comment back in if just doing some of the mtt's

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
('Course Content - Methods of Evaluation', 'GenericMaxText', 'TextMax03','1')

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
DECLARE @Label INTEGERS

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
output inserted.MetaSelectedFieldId INTO @Label
SELECT
'Part 2', -- [DisplayName]
NULL, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
1, -- [RowPosition]
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
NULL-- [Config]
FROM @Fields WHERE Action = 1

DECLARE @second int = (
	SELECT msf.MEtaSelectedFieldId FROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	INNER JOIN MetaSelectedSection AS mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	WHERE mt.MetaTemplateId = 24
	and mss2.SectionName = 'Course Content - Other Requirements'
	and msf.MetaAvailableFieldId IS NULL
)

INSERT INTO MetaSelectedFieldAttribute
(Name, Value, MetaSelectedFieldId)
SELECT 'ShouldDisplayCheckQuery', '
select case when YesNo50Id = 1 and CourseId IN (SELECT CourseId FROM CourseEvaluationMethod WHERE CourseId = @EntityId) then 1 else 0 end as ''ShouldDisplay'',null as JsonAttributes
from 	CourseYesNo
where courseID = @entityId
', Id FROM @Label
UNION
SELECT 'ShouldDisplayCheckQuery', '
select case when YesNo50Id = 1 and CourseId IN (SELECT CourseId FROM CourseTextBook WHERE CourseId = @EntityId) then 1 else 0 end as ''ShouldDisplay'',null as JsonAttributes
from 	CourseYesNo
where courseID = @entityId
', @second

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = 'DECLARE @Yes bit = (SELECT TOP 1 CASE WHEN CourseId = @EntityId THEN 1 ELSE 0 End FROM CourseObjective WHERE CourseId = @EntityId)

select 0 as Value,
concat(''<div class="ordered-list container-list container">'',Char(13)
	,''<div><label class="field-label style" style="margin-left: -25px;">Part 1:</label></div>''
	, (select dbo.ConcatWithSepOrdered_Agg('''',Sort,
		concat(''  <div class="bottom-margin-small row">'',Char(13),
			''    <div class="col-md-12 meta-renderable meta-field bottom-margin-extra-small" data-available-field-id="379" data-field-id="2647" data-field-type="Textarea">'',Char(13),
			''	  <label class="field-label">'',text,''</label>'',Char(13),
			''	</div>'',Char(13),
			''  </div>'',Char(13)
		)	
	)
	from (select text as text,Courseid,ROW_NUMBER() over (order by sortorder) as Sort from CourseObjective where CourseId = @entityid and YesNo01Id = 1) A)
	,''<div><label class="field-label" style="margin-left: -25px;">'', CASE WHEN @yes = 1 THEN '''' ELSE ''Part 2:'' END,''</label></div>''
	,(select dbo.ConcatWithSepOrdered_Agg('''',Sort,
		concat(''  <div class="bottom-margin-small row">'',Char(13),
			''    <div class="col-md-12 meta-renderable meta-field bottom-margin-extra-small" data-available-field-id="379" data-field-id="2647" data-field-type="Textarea">'',Char(13),
			''	  <label class="field-label">'',text,''</label>'',Char(13),
			''	</div>'',Char(13),
			''  </div>'',Char(13)
		)	
	) 
	from (select text as text,Courseid,ROW_NUMBER() over (order by sortorder) as Sort from CourseObjective where CourseId = @entityid and (YesNo01Id <> 1 or YesNo01Id is null)) B)
,Char(13),''</div>'') as Text'
, ResolutionSql = 'DECLARE @Yes bit = (SELECT TOP 1 CASE WHEN CourseId = @EntityId THEN 1 ELSE 0 End FROM CourseObjective WHERE CourseId = @EntityId)

select 0 as Value,
concat(''<div class="ordered-list container-list container">'',Char(13)
	,''<div><label class="field-label style" style="margin-left: -25px;">Part 1:</label></div>''
	, (select dbo.ConcatWithSepOrdered_Agg('''',Sort,
		concat(''  <div class="bottom-margin-small row">'',Char(13),
			''    <div class="col-md-12 meta-renderable meta-field bottom-margin-extra-small" data-available-field-id="379" data-field-id="2647" data-field-type="Textarea">'',Char(13),
			''	  <label class="field-label">'',text,''</label>'',Char(13),
			''	</div>'',Char(13),
			''  </div>'',Char(13)
		)	
	)
	from (select text as text,Courseid,ROW_NUMBER() over (order by sortorder) as Sort from CourseObjective where CourseId = @entityid and YesNo01Id = 1) A)
	,''<div><label class="field-label" style="margin-left: -25px;">'', CASE WHEN @yes = 1 THEN '''' ELSE ''Part 2:'' END,''</label></div>''
	,(select dbo.ConcatWithSepOrdered_Agg('''',Sort,
		concat(''  <div class="bottom-margin-small row">'',Char(13),
			''    <div class="col-md-12 meta-renderable meta-field bottom-margin-extra-small" data-available-field-id="379" data-field-id="2647" data-field-type="Textarea">'',Char(13),
			''	  <label class="field-label">'',text,''</label>'',Char(13),
			''	</div>'',Char(13),
			''  </div>'',Char(13)
		)	
	) 
	from (select text as text,Courseid,ROW_NUMBER() over (order by sortorder) as Sort from CourseObjective where CourseId = @entityid and (YesNo01Id <> 1 or YesNo01Id is null)) B)
,Char(13),''</div>'') as Text'
WHERE Id = 136

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = 'select 0 as Value,
case
	when CYN.YesNo50Id = 1 
		then concat(
			''<label class="field-label">Part 1:</label>'',Char(13),''<div>'',C.COURSE_DESC,''</div>'',Char(13),
			CASE WHEN C.Description IS NOT NULL THEN 
			CONCAT(''<label class="field-label">Part 2:</label>'',Char(13),''<div>'',C.Description,''</div>'',Char(13))
			ELSE ''''
			END
		)
	else C.Description
end as Text
from Course C
	inner join CourseYesNo CYN on C.id = CYN.CourseId
where C.id = @entityid'
, ResolutionSql = 'select 0 as Value,
case
	when CYN.YesNo50Id = 1 
		then concat(
			''<label class="field-label">Part 1:</label>'',Char(13),''<div>'',C.COURSE_DESC,''</div>'',Char(13),
			CASE WHEN C.Description IS NOT NULL THEN 
			CONCAT(''<label class="field-label">Part 2:</label>'',Char(13),''<div>'',C.Description,''</div>'',Char(13))
			ELSE ''''
			END
		)
	else C.Description
end as Text
from Course C
	inner join CourseYesNo CYN on C.id = CYN.CourseId
where C.id = @entityid'
WHERE Id = 88

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = 'select 0 as Value,
case
	when CYN.YesNo50Id = 1 
		then concat(
			''<label class="field-label">Part 1:</label>'',Char(13),''<div>'',GMT.TextMax01,''</div>'',Char(13),
			CASE WHEN C.LectureOutline IS NOT NULL THEN 
			CONCAT(''<label class="field-label">Part 2:</label>'',Char(13),''<div>'',C.LectureOutline,''</div>'',Char(13))
			ELSE ''''
			END
		)
	else C.LectureOutline
end as Text
from Course C
	inner join CourseYesNo CYN on C.id = CYN.CourseId
	inner join GenericMaxText GMT on C.id = GMT.CourseId
where C.id = @entityid'
, ResolutionSql = 'select 0 as Value,
case
	when CYN.YesNo50Id = 1 
		then concat(
			''<label class="field-label">Part 1:</label>'',Char(13),''<div>'',GMT.TextMax01,''</div>'',Char(13),
			CASE WHEN C.LectureOutline IS NOT NULL THEN 
			CONCAT(''<label class="field-label">Part 2:</label>'',Char(13),''<div>'',C.LectureOutline,''</div>'',Char(13))
			ELSE ''''
			END
		)
	else C.LectureOutline
end as Text
from Course C
	inner join CourseYesNo CYN on C.id = CYN.CourseId
	inner join GenericMaxText GMT on C.id = GMT.CourseId
where C.id = @entityid'
WHERE Id = 109

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = 'select 0 as Value,
case
	when CYN.YesNo50Id = 1 
		then concat(
			''<label class="field-label">Part 1:</label>'',Char(13),''<div>'',GMT.TextMax02,''</div>'',Char(13),
			CASE WHEN C.LabOutline IS NOT NULL THEN
			CONCAT(''<label class="field-label">Part 2:</label>'',Char(13),''<div>'',C.LabOutline,''</div>'',Char(13))
			ELSE ''''
			END
		)
	else C.LabOutline
end as Text
from Course C
	inner join CourseYesNo CYN on C.id = CYN.CourseId
	inner join GenericMaxText GMT on C.id = GMT.CourseId
where C.id = @entityid'
, ResolutionSql = 'select 0 as Value,
case
	when CYN.YesNo50Id = 1 
		then concat(
			''<label class="field-label">Part 1:</label>'',Char(13),''<div>'',GMT.TextMax02,''</div>'',Char(13),
			CASE WHEN C.LabOutline IS NOT NULL THEN
			CONCAT(''<label class="field-label">Part 2:</label>'',Char(13),''<div>'',C.LabOutline,''</div>'',Char(13))
			ELSE ''''
			END
		)
	else C.LabOutline
end as Text
from Course C
	inner join CourseYesNo CYN on C.id = CYN.CourseId
	inner join GenericMaxText GMT on C.id = GMT.CourseId
where C.id = @entityid'
WHERE Id = 115
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback
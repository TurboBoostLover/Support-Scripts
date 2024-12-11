USE [sbccd];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15551';
DECLARE @Comments nvarchar(Max) = 
	'Update Course Forms for non-credit courses to add two fields';
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
('Units and Hours', 'CourseDescription', 'TeachingUnitsLecture','Update'),
('Units and Hours', 'CourseDescription', 'TeachingUnitsWork', 'Update2')

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
insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
SELECT 
'Min regularly scheduled hours of lab/field instruction', -- [DisplayName]
3259, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
1, -- [IsRequired]
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
FROM @Fields WHERE Action = 'Update'
UNION
SELECT
'Max regularly scheduled hours of lab/field instruction', -- [DisplayName]
3260, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
1, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
3, -- [RowPosition]
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
FROM @Fields WHERE Action = 'Update'

UPDATE MetaSelectedField
SET DisplayName = 'Min regularly scheduled hours of lecture instruction'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update'
)

UPDATE MetaSelectedField
SET DisplayName = 'Max regularly scheduled hours of lecture instruction'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update2'
)

DECLARE @SQL NVARCHAR(MAX) = '
declare @cb04 int = (
    select CB04Id
    from CourseCBCode
    where CourseId = @entityId
)

if (@cb04 = 3) --if noncredit
BEGIN
    select 
        0 as Value
        ,concat(
            ''Min regularly scheduled hours of lecture instruction: '',FORMAT(TeachingUnitsLecture, ''###.###''),
            ''<br>Max regularly scheduled hours of lecture instruction: '',FORMAT(TeachingUnitsWork, ''###.###''),
						''<br>Min regularly scheduled hours of lab/field instruction: '',MinSeats,
						''<br>Max regularly scheduled hours of lab/field instruction: '',MaxSeats
        ) as Text
    from CourseDescription
    where CourseId = @entityId
end
else --credit
begin
SELECT 0 As Value,
	CONCAT(
		''<b>Semester Units:</b> '',
			CASE 
				WHEN cyn.YesNo07Id =2 
					THEN cast(cd.MinCreditHour as nvarchar(10))
				ELSE CONCAT(cd.MinCreditHour, '' - '', cd.MaxCreditHour)
			END,
		''<style type="text/css">
		.tg  {border-collapse:collapse;border-spacing:0;}
		.tg td{border-color:black;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;
		  overflow:hidden;padding:10px 5px;word-break:normal;}
		.tg th{border-color:black;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;
		  font-weight:normal;overflow:hidden;padding:10px 5px;word-break:normal;}
		.tg .tg-9fd4{background-color:#9b9b9b;font-weight:bold;text-align:left;vertical-align:top}
		.tg .tg-b3sw{background-color:#efefef;font-weight:bold;text-align:left;vertical-align:top}
		.tg .tg-0lax{text-align:left;vertical-align:top}
		</style>
		<br><b>Semester Hours:</b>
		<table class="tg">
		<thead>
		  <tr>
		    <th class="tg-9fd4">Instructional Categories</th>
		    <th class="tg-9fd4">Units</th>
		    <th class="tg-9fd4">Contact Hours</th>
		    <th class="tg-9fd4">Out of Class Hours</th>
		  </tr>
		</thead>
		<tbody>
		  <tr>
		    <td class="tg-b3sw">Lecture</td>'',
            ''<td class="tg-0lax">'',
            case
               WHEN gd.Decimal11 is not null and gd.Decimal11 != 0 and gd.Decimal14 is not null and gd.Decimal14 != 0 and gd.Decimal11 != gd.Decimal14 
						THEN CONCAT((dbo.FormatDecimal( gd.Decimal11,2,1)) ,'' - '',(dbo.FormatDecimal( gd.Decimal14,2,1)))
					WHEN gd.Decimal11 is not null and gd.Decimal11 != 0 and (gd.Decimal11 = gd.Decimal14 or gd.Decimal14 is null or gd.Decimal14 = 0)
						THEN (dbo.FormatDecimal( gd.Decimal11,2,1))
					WHEN (gd.Decimal11 is null or gd.Decimal11 = 0) and gd.Decimal14 is not null and gd.Decimal14 != 0
						THEN (dbo.FormatDecimal( gd.Decimal14,2,1))
					ELSE ''0''
            end,
            ''</td>'',
		    ''<td class="tg-0lax">'',
				CASE
					WHEN cd.MinLectureHour is not null and cd.MinLectureHour != 0 and cd.MaxLectureHour is not null and cd.MaxLectureHour != 0 and cd.MinLectureHour != cd.MaxLectureHour 
						THEN CONCAT((dbo.FormatDecimal( cd.MinLectureHour,2,1)) ,'' - '',(dbo.FormatDecimal( cd.MaxLectureHour,2,1)))
					WHEN cd.MinLectureHour is not null and cd.MinLectureHour != 0 and (cd.MinLectureHour = cd.MaxLectureHour or cd.MaxLectureHour is null or cd.MaxLectureHour = 0)
						THEN (dbo.FormatDecimal( cd.MinLectureHour,2,1))
					WHEN (cd.MinLectureHour is null or cd.MinLectureHour = 0) and cd.MaxLectureHour is not null and cd.MaxLectureHour != 0
						THEN (dbo.FormatDecimal( cd.MaxLectureHour,2,1))
					ELSE ''0''
				End,
			''</td>
		    <td class="tg-0lax">'',
				CASE
					WHEN gd.Decimal18 is not null and gd.Decimal18 != 0 and gd.Decimal17 is not null and gd.Decimal17 != 0 and gd.Decimal18 != gd.Decimal17 
						THEN CONCAT((dbo.FormatDecimal( gd.Decimal18,2,1)),'' - '',(dbo.FormatDecimal( gd.Decimal17,2,1)))
					WHEN gd.Decimal18 is not null and gd.Decimal18 != 0 and (gd.Decimal18 = gd.Decimal17 or gd.Decimal17 is null or gd.Decimal17 = 0)
						THEN (dbo.FormatDecimal( gd.Decimal18,2,1))
					WHEN (gd.Decimal18 is null or gd.Decimal18 = 0) and gd.Decimal17 is not null and gd.Decimal17 != 0
						THEN (dbo.FormatDecimal( gd.Decimal17,2,1))
					ELSE ''0''
				End,
			''</td>
		  </tr>
		  <tr>
		    <td class="tg-b3sw">Independent Study</td>'',
            ''<td class="tg-0lax">'',
            CASE
                WHEN gd.Decimal12 is not null and gd.Decimal12 != 0 and gd.Decimal15 is not null and gd.Decimal15 != 0 and gd.Decimal12 != gd.Decimal15 
                    THEN CONCAT((dbo.FormatDecimal( gd.Decimal12,2,1)),'' - '',(dbo.FormatDecimal( gd.Decimal15,2,1)))
                WHEN gd.Decimal12 is not null and gd.Decimal12 != 0 and (gd.Decimal12 = gd.Decimal15 or gd.Decimal15 is null or gd.Decimal15 = 0)
                    THEN (dbo.FormatDecimal( gd.Decimal12,2,1))
                WHEN (gd.Decimal12 is null or gd.Decimal12 = 0) and gd.Decimal15 is not null and gd.Decimal15 != 0
                    THEN (dbo.FormatDecimal( gd.Decimal15,2,1))
                ELSE ''0''
            End,
            ''</td>'',
		    ''<td class="tg-0lax">0</td>
		    <td class="tg-0lax">'',
				CASE
					WHEN cd.MinContHour is not null and cd.MinContHour != 0 and cd.MaxContHour is not null and cd.MaxContHour != 0 and cd.MinContHour != cd.MaxContHour 
						THEN CONCAT((dbo.FormatDecimal( cd.MinContHour,2,1)),'' - '',(dbo.FormatDecimal( cd.MaxContHour,2,1)))
					WHEN cd.MinContHour is not null and cd.MinContHour != 0 and (cd.MinContHour = cd.MaxContHour or cd.MaxContHour is null or cd.MaxContHour = 0)
						THEN (dbo.FormatDecimal( cd.MinContHour,2,1))
					WHEN (cd.MinContHour is null or cd.MinContHour = 0) and cd.MaxContHour is not null and cd.MaxContHour != 0
						THEN (dbo.FormatDecimal( cd.MaxContHour,2,1))
					ELSE ''0''
				End,
			''</td>
		  </tr>
		  <tr>
		    <td class="tg-b3sw">Lab/Field</td>'',
            ''<td class="tg-0lax">'',
            CASE
                WHEN gd.Decimal13 is not null and gd.Decimal13 != 0 and gd.Decimal16 is not null and gd.Decimal16 != 0 and gd.Decimal13 != gd.Decimal16 
                    THEN CONCAT((dbo.FormatDecimal( gd.Decimal13,2,1)),'' - '',(dbo.FormatDecimal( gd.Decimal16,2,1)))
                WHEN gd.Decimal13 is not null and gd.Decimal13 != 0 and (gd.Decimal13 = gd.Decimal16 or gd.Decimal16 is null or gd.Decimal16 = 0)
                    THEN (dbo.FormatDecimal( gd.Decimal13,2,1))
                WHEN (gd.Decimal13 is null or gd.Decimal13 = 0) and gd.Decimal16 is not null and gd.Decimal16 != 0
                    THEN (dbo.FormatDecimal( gd.Decimal16,2,1))
                ELSE ''0''
            End,
            ''</td>'',
		    ''<td class="tg-0lax">'',
				CASE
					WHEN cd.MinLabHour is not null and cd.MaxLabHour is not null and cd.MaxLabHour != 0 and cd.MinLabHour != cd.MaxLabHour 
						THEN CONCAT((dbo.FormatDecimal( cd.MinLabHour,2,1)),'' - '',(dbo.FormatDecimal( cd.MaxLabHour,2,1)))
					WHEN cd.MinLabHour is not null and cd.MinLabHour != 0 and (cd.MinLabHour = cd.MaxLabHour or cd.MaxLabHour is null or cd.MaxLabHour = 0)
						THEN (dbo.FormatDecimal( cd.MinLabHour,2,1))
					WHEN (cd.MinLabHour is null or cd.MinLabHour = 0) and cd.MaxLabHour is not null and cd.MaxLabHour != 0
						THEN (dbo.FormatDecimal( cd.MaxLabHour,2,1))
					ELSE ''0''
				End,
			''</td>
		    <td class="tg-0lax">0</td>
		  </tr>
		  <tr>
		    <td class="tg-b3sw">Activity</td>'',
            ''<td class="tg-0lax">'',
            CASE
                WHEN cd.ShortTermLabHour is not null and cd.ShortTermLabHour != 0 and cd.ShortTermLectureHour is not null and cd.ShortTermLectureHour != 0 and cd.ShortTermLabHour != cd.ShortTermLectureHour 
                    THEN CONCAT((dbo.FormatDecimal( cd.ShortTermLabHour,2,1)),'' - '',(dbo.FormatDecimal( cd.ShortTermLectureHour,2,1)))
                WHEN cd.ShortTermLabHour is not null and cd.ShortTermLabHour != 0 and (cd.ShortTermLabHour = cd.ShortTermLectureHour or cd.ShortTermLectureHour is null or cd.ShortTermLectureHour = 0)
                    THEN (dbo.FormatDecimal( cd.ShortTermLabHour,2,1))
                WHEN (cd.ShortTermLabHour is null or cd.ShortTermLabHour = 0) and cd.ShortTermLectureHour is not null and cd.ShortTermLectureHour != 0
                    THEN (dbo.FormatDecimal( cd.ShortTermLectureHour,2,1))
                ELSE ''0''
            End,
            ''</td>'',
		    ''<td class="tg-0lax">'',
				CASE
					WHEN cd.MinClinicalHour is not null and cd.MinClinicalHour != 0 and cd.MaxClinicalHour is not null and cd.MaxClinicalHour != 0 and cd.MinClinicalHour != cd.MaxClinicalHour 
						THEN CONCAT((dbo.FormatDecimal( cd.MinClinicalHour,2,1)),'' - '',(dbo.FormatDecimal( cd.MaxClinicalHour,2,1)))
					WHEN cd.MinClinicalHour is not null and cd.MinClinicalHour != 0 and (cd.MinClinicalHour = cd.MaxClinicalHour or cd.MaxClinicalHour is null or cd.MaxClinicalHour = 0)
						THEN (dbo.FormatDecimal( cd.MinClinicalHour,2,1))
					WHEN (cd.MinClinicalHour is null or cd.MinClinicalHour = 0) and cd.MaxClinicalHour is not null and cd.MaxClinicalHour != 0
						THEN (dbo.FormatDecimal( cd.MaxClinicalHour,2,1))
					ELSE ''0''
				End,
			''</td>
		    <td class="tg-0lax">'',
				CASE
					WHEN cd.MinFieldHour is not null and cd.MinFieldHour != 0 and cd.MaxWorkHour is not null and cd.MaxWorkHour != 0 and cd.MinFieldHour != cd.MaxWorkHour 
						THEN CONCAT((dbo.FormatDecimal( cd.MinFieldHour,2,1)),'' - '',(dbo.FormatDecimal( cd.MaxWorkHour,2,1)))
					WHEN cd.MinFieldHour is not null and cd.MinFieldHour != 0 and (cd.MinFieldHour = cd.MaxWorkHour or cd.MaxWorkHour is null or cd.MaxWorkHour = 0)
						THEN (dbo.FormatDecimal( cd.MinFieldHour,2,1))
					WHEN (cd.MinFieldHour is null or cd.MinFieldHour = 0) and cd.MaxWorkHour is not null and cd.MaxWorkHour != 0
						THEN (dbo.FormatDecimal( cd.MaxWorkHour,2,1))
					ELSE ''0''
				End,
			''</td>
		  </tr>
		  <tr>
		    <td class="tg-b3sw">Total</td>'',
            ''<td class="tg-0lax">'',
            CASE
                WHEN cd.MinCreditHour is not null and cd.MinCreditHour != 0 and cd.MaxCreditHour is not null and cd.MaxCreditHour != 0 and cd.MinCreditHour != cd.MaxCreditHour 
                    THEN CONCAT((dbo.FormatDecimal( cd.MinCreditHour,2,1)),'' - '',(dbo.FormatDecimal( cd.MaxCreditHour,2,1)))
                WHEN cd.MinCreditHour is not null and cd.MinCreditHour != 0 and (cd.MinCreditHour = cd.MaxCreditHour or cd.MaxCreditHour is null or cd.MaxCreditHour = 0)
                    THEN (dbo.FormatDecimal( cd.MinCreditHour,2,1))
                WHEN (cd.MinCreditHour is null or cd.MinCreditHour = 0) and cd.MaxCreditHour is not null and cd.MaxCreditHour != 0
                    THEN (dbo.FormatDecimal( cd.MaxCreditHour,2,1))
                ELSE ''0''
            End,
            ''</td>'',
		    ''<td class="tg-0lax">'',
				CASE
					WHEN cd.MinContactHoursOther is not null and cd.MinContactHoursOther != 0 and cd.MaxContactHoursOther is not null and cd.MaxContactHoursOther != 0 and cd.MinContactHoursOther != cd.MaxContactHoursOther 
						THEN CONCAT((dbo.FormatDecimal( cd.MinContactHoursOther,2,1)),'' - '',(dbo.FormatDecimal( cd.MaxContactHoursOther,2,1)))
					WHEN cd.MinContactHoursOther is not null and cd.MinContactHoursOther != 0 and (cd.MinContactHoursOther = cd.MaxContactHoursOther or cd.MaxContactHoursOther is null or cd.MaxContactHoursOther = 0)
						THEN (dbo.FormatDecimal( cd.MinContactHoursOther,2,1))
					WHEN (cd.MinContactHoursOther is null or cd.MinContactHoursOther = 0) and cd.MaxContactHoursOther is not null and cd.MaxContactHoursOther != 0
						THEN (dbo.FormatDecimal( cd.MaxContactHoursOther,2,1))
					ELSE ''0''
				End,
			''</td>
		    <td class="tg-0lax">'',
				CASE
					WHEN cd.InClassHour is not null and cd.InClassHour != 0 and cd.OutClassHour is not null and cd.OutClassHour != 0 and  cd.InClassHour !=  cd.OutClassHour 
						THEN CONCAT((dbo.FormatDecimal( cd.InClassHour,2,1)),'' - '',(dbo.FormatDecimal( cd.OutClassHour,2,1)))
					WHEN cd.InClassHour is not null and cd.InClassHour != 0 and (cd.InClassHour =  cd.OutClassHour or cd.OutClassHour is null or cd.OutClassHour = 0)
						THEN (dbo.FormatDecimal( cd.InClassHour,2,1))
					WHEN (cd.InClassHour is null or cd.InClassHour = 0) and cd.OutClassHour is not null and cd.OutClassHour != 0
						THEN (dbo.FormatDecimal( cd.OutClassHour,2,1))
					ELSE ''0''
				End,
			''</td>
		  </tr>
			<tr>
		    <td class="tg-b3sw">Total Student Learning Hours</td>'',
            ''<td class="tg-0lax" colspan="3">'',
							CASE
								WHEN cd.MaxUnitHour IS NULL OR cd.MaxUnitHour < cd.MinUnitHour
								THEN (dbo.FormatDecimal(cd.MinUnitHour, 2,1))
								ELSE CONCAT((dbo.FormatDecimal(cd.MinUnitHour, 2,1)), '' - '', (dbo.FormatDecimal(cd.MaxUnitHour, 2,1)))
							END,
            ''</td>'',
		''</tbody>
		</table>''
	) AS Text
    FROM Course c
        INNER JOIN CourseDescription cd on c.id = cd.CourseId
        INNEr JOIN GenericDecimal gd on c.id = gd.CourseId
        INNER JOIN CourseYesNo cyn on c.id = cyn.CourseId
    WHERE C.id = @entityId
end
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 260
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (
select  templateId FROM @Fields
UNION
SELECT mt.MetaTemplateId FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId = 260
)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback
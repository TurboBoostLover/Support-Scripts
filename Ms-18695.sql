USE [hkapa];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18695';
DECLARE @Comments nvarchar(Max) = 
	'Update Program Award type to be a checklist';
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
('General Programme Information', 'Program', 'AwardTypeAliasId','1')

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
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName)		--uncomment tab name if tempalate have different tab name (likely in reports)
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/
DELETE FROM MetaSelectedFieldAttribute
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = '1'
)

DELETE FROM MetaSelectedField
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = '1'
)

DELETE FROM MetaSelectedSectionAttribute
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = '1'
)
and Name in (
'Tier2FilterColumn', 'Tier2ForeignKeyField', 'Tier2IdColumn', 'Tier2Table'
)

UPDATE MetaSelectedSection
SET SortOrder = mss.SortOrder + 1
, RowPosition = mss.RowPosition + 1
FROM MetaSelectedSection AS mss
INNER JOIN @Fields AS f on mss.MetaSelectedSection_MetaSelectedSectionId = f.TabId
WHERE f.Action = '1'
and mss.RowPosition > f.sort

DECLARE @CheckList TABLE (SecId int, TempId int)

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
output inserted.MetaSelectedSectionId, inserted.MetaTemplateId INTO @CheckList
SELECT 
1, -- [ClientId]
TabId, -- [MetaSelectedSection_MetaSelectedSectionId]
'Award Title', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
sort + 1, -- [RowPosition]
sort + 1, -- [SortOrder]
1, -- [SectionDisplayId]
3, -- [MetaSectionTypeId]
TemplateId, -- [MetaTemplateId]
NULL, -- [DisplayFieldId]
NULL, -- [HeaderFieldId]
NULL, -- [FooterFieldId]
0, -- [OriginatorOnly]
7675, -- [MetaBaseSchemaId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EntityListLibraryTypeId]
NULL, -- [EditMapId]
1, -- [AllowCopy]
0, -- [ReadOnly]
NULL-- [Config]
FROM @Fields WHERE Action = '1'

INSERT INTO MetaSelectedSectionAttribute
(Name, Value, MetaSelectedSectionId)
SELECT 'ParentTable', 'Program', SecId FROM @CheckList
UNION
SELECT 'ForeignKeyToParent', 'ProgramId', SecId FROM @CheckList
UNION
SELECT 'LookupTable', 'AwardTypeAlias', SecId FROM @CheckList
UNION
SELECT 'ForeignKeyToLookup', 'AwardTypeAliasId', SecId FROM @CheckList
UNION
SELECT 'FilterSourceTable', 'Program', SecId FROM @CheckList
UNION
SELECT 'FilterSourceColumn', 'AwardTypeId', SecId FROM @CheckList
UNION
SELECT 'FilterFieldTable', 'ProgramAwardType', SecId FROM @CheckList
UNION
SELECT 'FilterFieldColumn', 'AwardTypeAliasId', SecId FROM @CheckList
UNION
SELECT 'FilterColumnName', 'NotUsed', SecId FROM @CheckList
UNION
SELECT 'FilterSubscriptionTable', 'Program', SecId FROM @CheckList
UNION
SELECT 'FilterSubscriptionColumn', 'AwardTypeId', SecId FROM @CheckList

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

SET QUOTED_IDENTIFIER OFF

DECLARE @CSQL NVARCHAR(MAX) = "
DECLARE @Award int = (SELECT AwardTypeId FROM Program WHERE Id = @EntityId)

select
    Id as Value
    ,Title as Text
		, AwardTypeId AS FilterValue
		, AwardTypeId AS filterValue
from AwardTypeAlias
where AwardTypeId = @Award
"

DECLARE @RSQL NVARCHAR(MAX) = "
select Title as Text from awardtypealias where id = @id
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'AwardTypeAlias', 'Id', 'Title', @CSQL, @RSQL, 'Order By SortOrder', 'Award Type Checklist', 3)

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
SELECT
'AwardTypeAlias', -- [DisplayName]
11822, -- [MetaAvailableFieldId]
SecId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
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
@MAX, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @CheckList

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = 'declare @title NVARCHAR(max)
declare @title2 NVARCHAR(MAX)
declare @awardGrantingBody NVARCHAR(max)
declare @primaryAreaStudy NVARCHAR(max)
declare @subAreaStudy NVARCHAR(max)
declare @otherAreaStudy NVARCHAR(max)
declare @programmeLength NVARCHAR(max)
declare @academyCredit NVARCHAR(max)
declare @QFCredit NVARCHAR(max)
declare @QFLevel NVARCHAR(max)
declare @launchYear NVARCHAR(max)
declare @launchMonth NVARCHAR(max)
declare @targetStudents NVARCHAR(max)
declare @studentIntakesPerYear NVARCHAR(max)
declare @studentsPerIntake NVARCHAR(max)
declare @QualificationTitle NVARCHAR(MAX)

select @title = Title from Program
where Id = @entityId

select @title2 = TitleAlias from Program
where Id = @entityId

SELECT @QualificationTitle = dbo.ConcatWithSepOrdered_Agg(''<br>'', awt.SortOrder, awt.Title) FROM AwardTypeAlias AS awt
INNER JOIN ProgramAwardType AS pa on awt.Id = pa.AwardTypeAliasId WHERE pa.ProgramId = @EntityId

select @awardGrantingBody = lr.Text	
	from ProgramDetail pd 
		inner join LettersOfRecommendationRequirement lr on pd.LettersOfRecommendationRequirementId = lr.Id
	where pd.ProgramId = @entityId

select @primaryAreaStudy = ar.Title 
from Program p
	inner join AdmissionRequirement ar on p.First_AdmissionRequirementId = ar.Id
where p.Id = @entityId

select @subAreaStudy = ar.Title 
from Program p
	inner join AdmissionRequirement ar on p.Second_AdmissionRequirementId = ar.Id
where p.Id = @entityId

select @otherAreaStudy = CareerOption 
from Program
where Id = @entityId

select @programmeLength = cc.Title
from Program p
	inner join CategoryCode cc on p.CategoryCodeId = cc.Id
where p.Id = @entityId

select @academyCredit = Int05 
from GenericInt
where ProgramId = @entityId

select @QFCredit = ICCBCreditHours 
from Program
where Id = @entityId

select @QFLevel = qfl.Title
from Program p
	inner join QFLevel qfl on p.QFLevelId = qfl.Id
where p.Id = @entityId

select @launchYear = StartYear 
from ProgramProposal
where ProgramId = @entityId

select  @launchMonth = m.MonthName
from Program p
	inner join Months m on m.Id = p.StartMonth
where p.Id = @entityId

select @targetStudents = EntranceRequirementsText 
from program
where Id = @entityId

select @studentIntakesPerYear = ClassStaffCount
from Program
where Id = @entityId

select @studentsPerIntake = CertificationStaffCount
from Program
where Id = @entityId

declare @modesOfDeliveryFT nvarchar(max) = (
	select 
		case
			when ft.RenderedText is not null
				then 
				concat (
					''<b>Full Time</b><br />''
					, ft.RenderedText
					, ''<br />''
				)
			else ''''
		end
	from (
		select dbo.ConcatWithSepOrdered_Agg('''', dm.Id, concat(''<li style ="list-style-type: none;">'', dm.Title, ''</li>'')) as RenderedText
		from ProgramDeliveryMethod pdm
			inner join DeliveryMethod dm on dm.Id = pdm.DeliveryMethodId
		where ProgramId = @entityId
		and dm.ParentId = 1--Full Time
	) ft
)

declare @modesOfDeliverPT nvarchar(max) = (
	select
		case
			when pt.RenderedText is not null
				then
				concat(
					''<b>Part-Time</b>''
					, pt.RenderedText
					, ''<br />''
				)
			else ''''
		end
	from (
		select dbo.ConcatWithSepOrdered_Agg('''', dm.Id, concat(''<li style ="list-style-type: none;">'', dm.Title, ''</li>'')) as RenderedText
		from ProgramDeliveryMethod pdm
			inner join DeliveryMethod dm on dm.Id = pdm.DeliveryMethodId
		where ProgramId = @entityId
		and dm.ParentId = 4--Part-Time
	) pt
)

declare @modesOfDeliverFTPT nvarchar(max) = (
	select
		case
			when ftpt.RenderedText is not null
				then
				concat(
					''<b>Full-Time and Part-time</b>''
					, ftpt.RenderedText
					, ''<br />''
				)
			else ''''
		end
	from (
		select dbo.ConcatWithSepOrdered_Agg('''', dm.Id, concat(''<li style ="list-style-type: none;">'', dm.Title, ''</li>'')) as RenderedText
		from ProgramDeliveryMethod pdm
			inner join DeliveryMethod dm on dm.Id = pdm.DeliveryMethodId
		where ProgramId = @entityId
		and dm.ParentId = 5--Full-Time and Part-time
	) ftpt
)

declare @modesOfDelivery nvarchar(max) = (
	select 
	concat(
		@modesOfDeliveryFT
		, @modesOfDeliverPT
		, @modesOfDeliverFTPT
	)
)

DECLARE @tbody NVARCHAR(MAX) = (CONCAT(
''<table style="border-collapse: collapse; width: 100%; font-family: Arial, sans-serif; font-size: 14px;">'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left; width: 30%;">Programme Title (English)</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@title, ''&nbsp;''), ''</td>'',
    ''</tr>'',
		''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left; width: 30%;">Programme Title (Chinese)</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@title2, ''&nbsp;''), ''</td>'',
    ''</tr>'',
		''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left; width: 30%;">Qualification Title</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@QualificationTitle, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Award Granting Body</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@awardGrantingBody, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Mode of Delivery</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@modesOfDelivery, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Primary Area of Study / Training</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@primaryAreaStudy, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Sub Area of Study / Training</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@subAreaStudy, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Other Area of Study / Training (if any)</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@otherAreaStudy, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Programme Length</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@programmeLength, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Academy Credit</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@academyCredit, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    --''<tr>'',
    --    ''<th style="border: 1px solid black; padding: 8px; text-align: left;">QF Credits</th>'',
    --    ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@QFCredit, ''&nbsp;''), ''</td>'',
    --''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">QF Level</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@QFLevel, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Planned Programme Launch Date</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@launchMonth, ''&nbsp;''), '', '', ISNULL(@launchYear, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Target Students</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@targetStudents, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Number of Student Intakes Per Year</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@studentIntakesPerYear, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Number of Students Per Intake</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@studentsPerIntake, ''&nbsp;''), ''</td>'',
    ''</tr>'',
''</table>''
))

SELECT 0 AS [Value], CONCAT(@tbody, ''<br>'') AS [Text]'
, ResolutionSql = 'declare @title NVARCHAR(max)
declare @title2 NVARCHAR(MAX)
declare @awardGrantingBody NVARCHAR(max)
declare @primaryAreaStudy NVARCHAR(max)
declare @subAreaStudy NVARCHAR(max)
declare @otherAreaStudy NVARCHAR(max)
declare @programmeLength NVARCHAR(max)
declare @academyCredit NVARCHAR(max)
declare @QFCredit NVARCHAR(max)
declare @QFLevel NVARCHAR(max)
declare @launchYear NVARCHAR(max)
declare @launchMonth NVARCHAR(max)
declare @targetStudents NVARCHAR(max)
declare @studentIntakesPerYear NVARCHAR(max)
declare @studentsPerIntake NVARCHAR(max)
declare @QualificationTitle NVARCHAR(MAX)

select @title = Title from Program
where Id = @entityId

select @title2 = TitleAlias from Program
where Id = @entityId

SELECT @QualificationTitle = dbo.ConcatWithSepOrdered_Agg(''<br>'', awt.SortOrder, awt.Title) FROM AwardTypeAlias AS awt
INNER JOIN ProgramAwardType AS pa on awt.Id = pa.AwardTypeAliasId WHERE pa.ProgramId = @EntityId

select @awardGrantingBody = lr.Text	
	from ProgramDetail pd 
		inner join LettersOfRecommendationRequirement lr on pd.LettersOfRecommendationRequirementId = lr.Id
	where pd.ProgramId = @entityId

select @primaryAreaStudy = ar.Title 
from Program p
	inner join AdmissionRequirement ar on p.First_AdmissionRequirementId = ar.Id
where p.Id = @entityId

select @subAreaStudy = ar.Title 
from Program p
	inner join AdmissionRequirement ar on p.Second_AdmissionRequirementId = ar.Id
where p.Id = @entityId

select @otherAreaStudy = CareerOption 
from Program
where Id = @entityId

select @programmeLength = cc.Title
from Program p
	inner join CategoryCode cc on p.CategoryCodeId = cc.Id
where p.Id = @entityId

select @academyCredit = Int05 
from GenericInt
where ProgramId = @entityId

select @QFCredit = ICCBCreditHours 
from Program
where Id = @entityId

select @QFLevel = qfl.Title
from Program p
	inner join QFLevel qfl on p.QFLevelId = qfl.Id
where p.Id = @entityId

select @launchYear = StartYear 
from ProgramProposal
where ProgramId = @entityId

select  @launchMonth = m.MonthName
from Program p
	inner join Months m on m.Id = p.StartMonth
where p.Id = @entityId

select @targetStudents = EntranceRequirementsText 
from program
where Id = @entityId

select @studentIntakesPerYear = ClassStaffCount
from Program
where Id = @entityId

select @studentsPerIntake = CertificationStaffCount
from Program
where Id = @entityId

declare @modesOfDeliveryFT nvarchar(max) = (
	select 
		case
			when ft.RenderedText is not null
				then 
				concat (
					''<b>Full Time</b><br />''
					, ft.RenderedText
					, ''<br />''
				)
			else ''''
		end
	from (
		select dbo.ConcatWithSepOrdered_Agg('''', dm.Id, concat(''<li style ="list-style-type: none;">'', dm.Title, ''</li>'')) as RenderedText
		from ProgramDeliveryMethod pdm
			inner join DeliveryMethod dm on dm.Id = pdm.DeliveryMethodId
		where ProgramId = @entityId
		and dm.ParentId = 1--Full Time
	) ft
)

declare @modesOfDeliverPT nvarchar(max) = (
	select
		case
			when pt.RenderedText is not null
				then
				concat(
					''<b>Part-Time</b>''
					, pt.RenderedText
					, ''<br />''
				)
			else ''''
		end
	from (
		select dbo.ConcatWithSepOrdered_Agg('''', dm.Id, concat(''<li style ="list-style-type: none;">'', dm.Title, ''</li>'')) as RenderedText
		from ProgramDeliveryMethod pdm
			inner join DeliveryMethod dm on dm.Id = pdm.DeliveryMethodId
		where ProgramId = @entityId
		and dm.ParentId = 4--Part-Time
	) pt
)

declare @modesOfDeliverFTPT nvarchar(max) = (
	select
		case
			when ftpt.RenderedText is not null
				then
				concat(
					''<b>Full-Time and Part-time</b>''
					, ftpt.RenderedText
					, ''<br />''
				)
			else ''''
		end
	from (
		select dbo.ConcatWithSepOrdered_Agg('''', dm.Id, concat(''<li style ="list-style-type: none;">'', dm.Title, ''</li>'')) as RenderedText
		from ProgramDeliveryMethod pdm
			inner join DeliveryMethod dm on dm.Id = pdm.DeliveryMethodId
		where ProgramId = @entityId
		and dm.ParentId = 5--Full-Time and Part-time
	) ftpt
)

declare @modesOfDelivery nvarchar(max) = (
	select 
	concat(
		@modesOfDeliveryFT
		, @modesOfDeliverPT
		, @modesOfDeliverFTPT
	)
)

DECLARE @tbody NVARCHAR(MAX) = (CONCAT(
''<table style="border-collapse: collapse; width: 100%; font-family: Arial, sans-serif; font-size: 14px;">'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left; width: 30%;">Programme Title (English)</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@title, ''&nbsp;''), ''</td>'',
    ''</tr>'',
		''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left; width: 30%;">Programme Title (Chinese)</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@title2, ''&nbsp;''), ''</td>'',
    ''</tr>'',
		''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left; width: 30%;">Qualification Title</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@QualificationTitle, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Award Granting Body</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@awardGrantingBody, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Mode of Delivery</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@modesOfDelivery, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Primary Area of Study / Training</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@primaryAreaStudy, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Sub Area of Study / Training</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@subAreaStudy, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Other Area of Study / Training (if any)</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@otherAreaStudy, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Programme Length</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@programmeLength, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Academy Credit</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@academyCredit, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    --''<tr>'',
    --    ''<th style="border: 1px solid black; padding: 8px; text-align: left;">QF Credits</th>'',
    --    ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@QFCredit, ''&nbsp;''), ''</td>'',
    --''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">QF Level</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@QFLevel, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Planned Programme Launch Date</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@launchMonth, ''&nbsp;''), '', '', ISNULL(@launchYear, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Target Students</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@targetStudents, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Number of Student Intakes Per Year</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@studentIntakesPerYear, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Number of Students Per Intake</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@studentsPerIntake, ''&nbsp;''), ''</td>'',
    ''</tr>'',
''</table>''
))

SELECT 0 AS [Value], CONCAT(@tbody, ''<br>'') AS [Text]'
WHERE Id = 224

update mq 
set SortOrder = sorted.rownum 
output inserted.*
from AwardTypeAlias mq
inner join ( 
select id, ROW_NUMBER() over (order by Title) rownum 
from AwardTypeAlias 
) sorted on mq.Id = sorted.Id
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback
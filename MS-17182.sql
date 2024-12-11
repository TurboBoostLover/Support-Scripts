USE [sdccd];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17182';
DECLARE @Comments nvarchar(Max) = 
	'Fix for bad Queries and Assist Preview';
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
('Assignments', 'Course', 'CourseScope','Ping'),
('Assignments', 'Course', 'History','Ping'),
('Assignments', 'Course', 'TranslatedDescription','Ping'),
('Assignments', 'GenericMaxText', 'TextMax04','Ping'),
('ASSIST Preview', 'CourseAssist', 'AssignmentsId', 'Update'),
('Requisites', 'CourseRequisite', 'RequisiteTypeId', 'Ping2')

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
DECLARE @SQL NVARCHAR(MAX) = '
		--declare @entityId int = (18677);

		declare 
			@courseNumberNumeric int,
			@overide int,
			@variable int,
			@minLecUnits decimal(16, 3),
			@MaxLecUnits decimal(16, 3),
			@minLecHrOveride decimal(16, 3),
			@MaxLecHrOveride decimal(16, 3),
			@minLabUnits decimal(16, 3),
			@MaxLabUnits decimal(16, 3),
			@minLabHrOveride decimal(16, 3),
			@MaxLabHrOveride decimal(16, 3),
			@minOtherUnits decimal(16, 3),
			@MaxOtherUnits decimal(16,3),
			@minOtherHrOverride decimal(16,3),
			@maxOtherHrOverride decimal(16,3)
		;
		-- get saved Values
		select 
			@courseNumberNumeric = dbo.fnCourseNumberToNumeric(CourseNumber),
			@overide = cyn.YesNo05Id,
			@variable = cyn.YesNo14Id,
			@minLecUnits = cd.ShortTermLabHour,
			@MaxLecUnits = cd.SemesterHour,
			@minLecHrOveride = cd.MinContactHoursClinical,
			@MaxLecHrOveride = cd.MaxContactHoursClinical,
			@minLabUnits = cd.MinLabHour,
			@MaxLabUnits = cd.MaxLabHour,
			@minLabHrOveride = cd.MinContactHoursLecture,
			@MaxLabHrOveride = cd.MaxContactHoursLecture,
			@minOtherUnits = cd.MinOtherHour,
			@MaxOtherUnits = cd.MaxOtherHour,
			@minOtherHrOverride = cd.MinUnitHour,
			@maxOtherHrOverride = cd.MaxUnitHour
		from Course c
			inner join CourseYesNo cyn on c.Id = cyn.CourseId
			inner join CourseDescription cd on c.Id = cd.courseId
		where c.Id = @entityId;

		--Calculations
		declare 
			@MinLecHr decimal(16, 3) = 
				case
					when @overide = 1
						then format(@minLecHrOveride, ''0.###'')
					else format((isNull(@minLecUnits, 0) * 16), ''0.###'')
				end,
			@MaxLecHr decimal(16, 3) = 
				case
					when @overide = 1
						then format(@maxLecHrOveride, ''0.###'')
					when @variable = 1
						then format((isNull(@maxLecUnits, 0) * 18), ''0.###'')
					else format((isNull(@minLecUnits, 0) * 18), ''0.###'')
				end,
			@MinLabHr decimal(16, 3)= 
				case
					when @overide = 1
						then format(@minLabHrOveride, ''0.###'')
					else format((isNull(@MinLabUnits, 0) * 48), ''0.###'')
				end,
			@MaxLabHr decimal(16, 3)= 
				case
					when @overide = 1
						then format(@maxLabHrOveride, ''0.###'')
					when @variable = 1
						then format((isNull(@maxlabUnits, 0) * 54), ''0.###'')
					else format((isNull(@minLabUnits, 0) * 48), ''0.###'')--54), ''0.###'')
				end,
			@MinOtherHr decimal(16,3) = 
				case
					when @overide = 1
						then format(@minOtherHrOverride, ''0.###'')
					else format((isNull(@minOtherUnits, 0) * 48), ''0.###'')
				end,
			@MaxOtherHr decimal(16,3) = 
				case
					when @overide = 1
						then format(@maxOtherHrOverride, ''0.###'')
					else format((isNull(@maxOtherUnits, 0) * 54), ''0.###'')
				end,
			@hoursDecimalFormat nvarchar(10) = concat(''F'', 3)
		;

		declare
			@MinContactHr decimal(16, 3) = format((isNull(@MinLecHr, 0) + isNull(@MinLabHr, 0) + isNull(@minOtherHr, 0)), ''0.###''), 
			@MaxContactHr decimal(16, 3) = format((isNull(@MaxLecHr, 0) + isNull(@MaxLabHr, 0) + isNull(@maxOtherHr, 0)), ''0.###''), 
			@MinOutHr decimal(16, 3) = format((isNull(@MinLecHr, 0) * 2), ''0.###''),
			@MaxOutHr decimal(16, 3) = format((isNull(@MaxLecHr, 0) * 2), ''0.###'') 
		;

		declare
    @minTotalHr decimal(16, 3) = isNull(@MinContactHr, 0) + isNull(@MinOutHr, 0),
    @maxTotalHr decimal(16, 3) = isNull(@MaxContactHr, 0) + isNull(@MaxOutHr, 0),
    @totalFTEFMin decimal(16,3) = 
        case
            when @courseNumberNumeric >= 400
                then (((@MinContactHr - isNull(@minOtherHr, 0)) / 16) / 12)
            when @courseNumberNumeric > 0
                then (((@MinContactHr - isNull(@minOtherHr, 0))  / 16) / 15)
            else 0
        end,
    @totalFTEFMax decimal(16,3) = 
        case
            when @courseNumberNumeric >= 400
                then (((@MaxContactHr - isNull(@maxOtherHr, 0)) / 16) / 12)
            when @courseNumberNumeric > 0
                then (((@MaxContactHr  -isNull(@maxOtherHr, 0))  / 16) / 15)
            else 0
        end
;

		--formating
		select 0 as [Value],
			concat(
				''<div class="container">'',
					''<div class="h4 row">Total Hours</div>'',
					''<div class="row">'',
						''<div class="col-6">'',
							''<b>Min Contact Hours: </b> '', 
							format(@MinContactHr, ''0.###''),	
						''</div>'',
						''<div class="col-6">'',
							''<b>Max Contact Hours: </b> '',
							format(@MaxContactHr, ''0.###''),
						''</div>'',
					''</div>'',
					''<div class="row">'',
						''<div class="col-6">'',
							''<b>Min Outside-of-Class Hours: </b> '', 
							format(@MinOutHr, ''0.###''),
						''</div>'',
						''<div class="col-6">'',
							''<b>Max Outside-of-Class Hours: </b> '',
							format(@MaxOutHr, ''0.###''),
						''</div>'',
					''</div>'',
					''<div class="row">'',
						''<div class="col-6">'',
							''<b>Min Total Student Learning Hours: </b> '', 
							format(@minTotalHr, ''0.###''),
						''</div>'',
						''<div class="col-6">'',
							''<b>Max Total Student Learning  Hours: </b> '',
							format(@maxTotalHr, ''0.###''),
						''</div>'',
					''</div>'',
					''<div class="h4 row">FTEF</div>'',
					''<div class="row">'',
						''<div class="col-6">'',
							''<b>Total FTEF Min: </b> '', 
							format(@totalFTEFMin, ''0.###''),
						''</div>'',
					''</div>'',
				''</div>''
			) as [Text]
		;
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 185

DECLARE @SQL2 NVARCHAR(MAX) = '
select 1 as Value
,''<ul>'' 
	+ coalesce(''<li><strong>Writing</strong><br>Writing assignments are required may include, but are not limited to, the following:<p>'' + c.History + ''</p></li>'', '''')
	+ coalesce(''<li><strong>Critical Thinking</strong><br>Critical Thinking assignments are required and may include, but are not limited to, the following:<p>'' + gm.TextMax04 + ''</p></li>'', '''')
	+ ''</ul>'' as Text
from Course c 
LEFT JOIN GenericMaxText AS gm on gm.CourseId = c.Id
WHERE c.Id = @entityId
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL2
, ResolutionSql = @SQL2
WHERE Id = 2882

INSERT INTO MetaSelectedFieldAttribute
(Name, Value, MetaSelectedFieldId)
SELECT 'triggersectionrefresh', f.TabId, f2.FieldId FROM @Fields AS f
INNER JOIN @Fields AS f2 on f.TemplateId = f2.TemplateId
WHERE f.Action = 'Update'
and f2.Action = 'Ping'

INSERT INTO MetaSelectedSectionAttribute
(Name, Value, MetaSelectedSectionId)
SELECT 'triggersectionrefresh', f.TabId, f2.SectionId FROM @Fields AS f
INNER JOIN @Fields AS f2 on f.TemplateId = f2.TemplateId
WHERE f.Action = 'Update'
and f2.Action = 'Ping2'
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields
UNION
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId in (185, 2882)
)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback
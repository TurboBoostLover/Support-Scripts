USE [socccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15938';
DECLARE @Comments nvarchar(Max) = 
	'Update Query text on units/hours tab';
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
DECLARE @SQL NVARCHAR(MAX) = '
DECLARE @createdDate DateTime = (
	SELECT CreatedOn FROM Course
	WHERE Id = @EntityId
)

DECLARE @Update DATETIME = ''2024-03-20 07:59:29.500''


declare @courseType int = (
	select CB04Id
	from CourseCBCode
	where CourseId = @entityId
);
declare @labNewNum decimal(16,3) = 0.00;
declare @learnNewNum decimal(16,3) = 0.00;
declare @minOutside decimal(16,3) = (
	select MinContactHoursOther
	from CourseDescription
	where CourseId = @entityId
);
declare @subjectId int = (
	select c.SubjectId
	from Course c
		inner join [Subject] s on c.SubjectId = s.Id
	where c.Id = @entityId
);
declare @cb10Id int = (
	select ccbc.CB10Id
	from CourseCBCode ccbc
		inner join CB10 cb10 on ccbc.CB10Id = cb10.Id
	where ccbc.CourseId = @entityId
);

/*
	1 = C - Credit - Not Degree Applicable
	2 = D - Credit - Degree Applicable
	3 = N - Non Credit
*/
if (@courseType in (1, 2))
begin
	set @labnewNum = (
		select floor((coalesce(MinLabHour, 0) / 3) * 2) / 2
		from CourseDescription
		where CourseId = @entityId
	);

	set @learnNewNum = (
		select floor((coalesce(MinContHour, 0) / 3) * 2) / 2
		from CourseDescription
		where CourseId = @entityId
	);
end;

with RawHoursList as (
	select ''Weekly Faculty Contact Hours'' as label
	   , coalesce(MinLectureHour, 0) as LectureValue
	   , (coalesce(MinLabHour, 0) + coalesce(MinContactHoursLab, 0)) as LabValue
	   , coalesce(MinContHour, 0) as LearnValue
	   ,MinCreditHour as TotalValue
	from CourseDescription
	where CourseId = @entityId
)
, RawHoursListTotal as (
	select label
	   , LectureValue
	   , LabValue
	   , LearnValue
	   , (LectureValue + LabValue + LearnValue) as TotalValue
	from RawHoursList
)
/*
	1 = C - Is part of a cooperative work experience education program.
	206 = CWE
*/
, TFCH as (
	select case
			when @subjectId in (206)
				and @cb10Id in (1) and @createdDate < @Update then ''Total Contact Hours (Unpaid)''
			else ''Total Contact Hours''
		end as label
	   , ((round(LectureValue * 16.6, 2) * 100) / 100) as TFCHLectureValue
	   , ((round(LabValue * 16.6, 2) * 100) / 100) as TFCHLabValue
	   , ((round(LearnValue * 16.6, 2) * 100) / 100) as TFCHLearnValue
	   , 0 as TFCHTotal
	from RawHoursList
)
, TFCHTotal as (
	select label
	   , TFCHLectureValue
	   , TFCHLabValue
	   , TFCHLearnValue
	   , ((((TFCHLectureValue * 1) + (TFCHLabValue * 1) + (TFCHLearnValue * 1)) * 100) / 100) as TFCHTotalValue
	from TFCH
)
, LHE as (
	select ''Lecture Hour Equivalent'' as label
	   , ((round(LectureValue * 1, 2) * 100) / 100) as LHELectureValue
	   , ((round(LabValue * .833, 2) * 100) / 100) as LHELabValue
	   , ((round(LearnValue * .5, 2) * 100) / 100) as LHELearnValue
	   ,0 as LHETotal
	from RawHoursList
)
, LHETotal as (
	select label
	   , LHELectureValue
	   , LHELabValue
	   , LHELearnValue
	   , ((((LHELectureValue * 1) + (LHELabValue * 1) + (LHELearnValue * 1)) * 100) / 100) as LHETotalValue
	from LHE
)
, FTEF as (
	select ''Full Time Equivalent Faculty'' as label
	   , ((round((LectureValue / 15) * 100, 2) * 100) / 100) as FTEFLectureValue
	   , cast(round(((((round(LabValue * .833 * 100, 0) / 100) / 15) * 100) * 100), 2) / 100 as decimal(16, 2)) as FTEFLabValue
	   , ((round(LearnValue * .5, 2) * 100) / 15) as FTEFLearnValue
	   , 0 as FTEFTotal
	from RawHoursList
)
, FTEFTotal as (
	select label
	   , FTEFLectureValue
	   , FTEFLabValue
	   , FTEFLearnValue
	   , (((FTEFLectureValue + FTEFLabValue + FTEFLearnValue) * 100) / 100) as FTEFTotalValue
	from FTEF
)
, Units as (
	select ''Units'' as label
	   , LectureValue as UnitsLectureValue
	   , @labNewNum as UnitsLabValue
	   , @learnNewNum as UnitsLearnValue
	   , TotalValue as UnitsTotalValue
	from RawHoursList
)
, UnitsTotal as (
	select label
	   , UnitsLectureValue
	   , UnitsLabValue
	   , UnitsLearnValue
	   , UnitsTotalValue
	from Units
)
, Outside as (
	select case
			when @courseType in (1,2) then ''Outside of Class Hours''
			else ''Outside Study Hours''
		end as label
	   , case
			when @courseType in (1, 2) then (LectureValue * 33.2)
			else isnull(@minOutside, 0.00)
		end as OutsideValue
	   , 0 as OutsideLabValue
	   , 0 as OutsideLearnValue
	   , 0 as OutsideTotalValue
	from RawHoursList
)
, TotalStudentLearningHours as (
	select ''Total Student Learning Hours'' as label
	   , 0 as StudentHours
	   , 0 as Studentlab
	   , 0 as StudentLearn
	   ,(
			(round(LectureValue * 16.6, 2) * 100) / 100
		) + 
		(
			(round(LabValue * 16.6, 2) * 100) / 100
		) + 
		(
			(round(LearnValue * 16.6, 2) * 100) / 100
		) +
		case
			when @courseType in (1, 2) then (LectureValue * 33.2)
			else ISNULL(@minOutside, 0.00)
		end as TotalStudentLearningHours
	from RawHoursList
)
, FinalQuery as (
	select ''
		<div>
			<div style="display: table-row;">
				<span style="width: 230px; display: table-cell;">
					<strong></strong>
				</span>
				<span style="width: 80px; text-align: left; display: table-cell;">
					<strong>Lecture</strong>
				</span>
				<span style="width: 80px; text-align: left; display: table-cell;">
					<strong>Lab</strong>
				</span>
				<span style="width: 80px; text-align: left; display: table-cell;">
					<strong>Learn Ctr</strong>
				</span>
				<span style="width: 80px; text-align: left; display: table-cell;">
					<strong>Total</strong>
				</span>
			</div>
		'' as [Text]
		, null as Label
		, null as Lecture
		, null as Lab
		, null as LearnCtr
		, null as Total
		union all
		select ''
			<div style="display: table-row;">
				<span style="width: 230px; display: table-cell;">'' + 
					label + 
				''</span>'' + 
				''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
					cast(cast(LectureValue as decimal(6, 2)) as nvarchar(max)) + 
				''</span>'' + 
				''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
					cast(cast(LabValue as decimal(6, 2)) as nvarchar(max)) + 
				''</span>'' + 
				''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
					cast(cast(LearnValue as decimal(6, 2)) as nvarchar(max)) + 
				''</span>'' + 
				''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
					cast(cast(TotalValue as decimal(6, 2)) as nvarchar(max)) + 
				''</span>'' + 
			''</div>'' as [Text]
		, Label
		, cast(cast(LectureValue as decimal(6, 2)) as nvarchar(max)) as Lecture
		, cast(cast(LabValue as decimal(6, 2)) as nvarchar(max)) as Lab
		, cast(cast(LearnValue as decimal(6, 2)) as nvarchar(max)) as LearnCtr
		, cast(cast(TotalValue as decimal(6, 2)) as nvarchar(max)) as Total
	from RawHoursListTotal
	union all
	select ''
		<div style="display: table-row;">
			<span style="width: 230px; display: table-cell;">'' + 
				label + 
			''</span>'' + 
			''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
				cast(cast(TFCHLectureValue as decimal(6, 2)) as nvarchar(max)) + 
			''</span>'' + 
			''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
				cast(cast(TFCHLabValue as decimal(6, 2)) as nvarchar(max)) + 
			''</span>'' + 
			''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
				cast(cast(TFCHLearnValue as decimal(6, 2)) as nvarchar(max)) + 
			''</span>'' + 
			''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
				cast(cast(TFCHTotalValue as decimal(6, 2)) as nvarchar(max)) + 
			''</span>'' + 
		''</div>'' as [Text]
		, Label
		, cast(cast(TFCHLectureValue as decimal(6, 2)) as nvarchar(max)) as Lecture
		, cast(cast(TFCHLabValue as decimal(6, 2)) as nvarchar(max)) as Lab
		, cast(cast(TFCHLearnValue as decimal(6, 2)) as nvarchar(max)) as LearnCtr
		, cast(cast(TFCHTotalValue as decimal(6, 2)) as nvarchar(max)) as Total
	from TFCHTotal
	union all
	select ''
		<div style="display: table-row;">
			<span style="width: 230px; display: table-cell;">'' + 
				label + 
			''</span>'' + 
			''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
				cast(cast(LHELectureValue as decimal(6, 2)) as nvarchar(max)) + 
			''</span>'' + 
			''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
				cast(cast(LHELabValue as decimal(6, 2)) as nvarchar(max)) + 
			''</span>'' + 
			''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
				cast(cast(LHELearnValue as decimal(6, 2)) as nvarchar(max)) + 
			''</span>'' + 
			''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
				cast(cast(LHETotalValue as decimal(6, 2)) as nvarchar(max)) + 
			''</span>'' + 
		''</div>'' as [Text]
		, Label
		, cast(cast(LHELectureValue as decimal(6, 2)) as nvarchar(max)) as Lecture
		, cast(cast(LHELabValue as decimal(6, 2)) as nvarchar(max)) as Lab
		, cast(cast(LHELearnValue as decimal(6, 2)) as nvarchar(max)) as LearnCtr
		, cast(cast(LHETotalValue as decimal(6, 2)) as nvarchar(max)) as Total
	from LHETotal
	union all
	select ''
		<div style="display: table-row;">
			<span style="width: 230px; display: table-cell;">'' + 
				label + 
			''</span>'' + 
			''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
				cast(cast(FTEFLectureValue as decimal(6, 2)) as nvarchar(max)) + 
			''</span>'' + 
			''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
				cast(FTEFLabValue as nvarchar(max)) + 
			''</span>'' + 
			''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
				cast(cast(FTEFLearnValue as decimal(6, 2)) as nvarchar(max)) + 
			''</span>'' + 
			''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
				cast(cast(FTEFTotalValue as decimal(6, 2)) as nvarchar(max)) + 
			''</span>'' + 
		''</div>'' as [Text]
		, Label
		, cast(cast(FTEFLectureValue as decimal(6, 2)) as nvarchar(max)) as Lecture
		, cast(FTEFLabValue as nvarchar(max)) as Lab
		, cast(cast(FTEFLearnValue as decimal(6, 2)) as nvarchar(max)) as LearnCtr
		, cast(cast(FTEFTotalValue as decimal(6, 2)) as nvarchar(max)) as Total
	from FTEFTotal
	union all
	select ''
		<div style="display: table-row;">
			<span style="width: 230px; display: table-cell;">'' + 
				case
					when @courseType in (1, 2) then label
					else ''''
				end + 
			''</span>'' + 
			''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
				case
					when @courseType in (1, 2) then cast(cast(UnitsLectureValue as decimal(6, 2)) as nvarchar(max))
					else ''''
				end + 
			''</span>'' + 
			''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
				case
					when @courseType in (1, 2) then cast(cast(UnitsLabValue as decimal(6, 2)) as nvarchar(max))
					else ''''
				end + 
			''</span>'' + 
			''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
				case
					when @courseType in (1, 2) then cast(cast(UnitsLearnValue as decimal(6, 2)) as nvarchar(max))
					else ''''
				end + 
			''</span>'' + 
			''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
				case
					when @courseType in (1, 2) then cast(cast(UnitsTotalValue as decimal(6, 2)) as nvarchar(max))
					else ''''
				end + 
			''</span>'' + 
		''</div>'' as [Text]
		, Label
		, case
			when @courseType in (1, 2) then cast(cast(UnitsLectureValue as decimal(6, 2)) as nvarchar(max))
			else null
		end as Lecture
		, case
			when @courseType in (1, 2) then cast(cast(UnitsLabValue as decimal(6, 2)) as nvarchar(max))
			else null
		end as Lab
		, case
			when @courseType in (1, 2) then cast(cast(UnitsLearnValue as decimal(6, 2)) as nvarchar(max))
			else null
		end as LearnCtr
		, case
			when @courseType in (1, 2) then cast(cast(UnitsTotalValue as decimal(6, 2)) as nvarchar(max))
			else null
		end as Total
	from UnitsTotal
	union all
	select ''
		<div style="display: table-row;">
			<span style="width: 230px; display: table-cell;">'' + 
				label + 
			''</span>'' + 
			''<span style="width: 80px; text-align: left; display: table-cell;"></span>'' + 
			''<span style="width: 80px; text-align: left; display: table-cell;"></span>'' + 
			''<span style="width: 80px; text-align: left; display: table-cell;"></span>'' + 
			''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
				cast(cast(OutsideValue as decimal(6, 2)) as nvarchar(max)) + 
			''</span>'' + 
		''</div></div>'' as [Text]
	   , Label
	   , null as Lecture
	   , null as Lab
	   , null as LearnCtr
	   , cast(cast(OutsideValue as decimal(6, 2)) as nvarchar(max)) as Total
	from Outside
	union all
	select ''
		<div style="display: table-row;">
			<span style="width: 230px; display: table-cell;">Total Student Learning Hours</span>'' + 
			''<span style="width: 80px; text-align: left; display: table-cell;"></span>'' + 
			''<span style="width: 80px; text-align: left; display: table-cell;"></span>'' + 
			''<span style="width: 80px; text-align: left; display: table-cell;"></span>'' + 
			''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
				cast(cast(TotalStudentLearningHours as decimal(6, 2)) as nvarchar(max)) + 
			''</span>'' + 
		''</div></div>'' as [Text]
	   , Label
	   , null as Lecture
	   , null as Lab
	   , null as LearnCtr
	   , cast(cast(TotalStudentLearningHours as decimal(6, 2)) as nvarchar(max)) as Total
	from TotalStudentLearningHours
)
select *
from FinalQuery;
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 271

DECLARE @SQL2 NVARCHAR(MAX) = '
DECLARE @createdDate DateTime = (
	SELECT CreatedOn FROM Course
	WHERE Id = @EntityId
)

DECLARE @Update DATETIME = ''2024-03-20 07:59:29.500''
DECLARE @MAXUNIT decimal (16,3) = (
	SELECT MaxFieldHour FROM CourseDescription WHERE CourseId = @EntityId
)

declare @courseType int = (
	select CB04Id
	from CourseCBCode
	where CourseId = @entityId
);
declare @labNewNum decimal(16, 3) = 0.00;
declare @learnDeci decimal(16, 3);
declare @learnNewNum decimal(16, 3) = 0.00;
declare @maxOtherHours decimal(16, 3) = (
	select MaxContactHoursOther
	from CourseDescription
	where CourseId = @entityId
);
declare @subjectId int = (
	select c.SubjectId
	from Course c
		inner join [Subject] s on c.SubjectId = s.Id
	where c.Id = @entityId
);
declare @cb10Id int = (
	select ccbc.CB10Id
	from CourseCBCode ccbc
		inner join CB10 cb10 on ccbc.CB10Id = cb10.Id
	where ccbc.CourseId = @entityId
);

/*
	1 = C - Credit - Not Degree Applicable
	2 = D - Credit - Degree Applicable
	3 = N - Non Credit
*/
if (@courseType in (1, 2))
begin
	set @labNewNum = (
		select floor((coalesce(maxLabHour, 0) / 3) * 2) / 2
		from CourseDescription
		where CourseId = @entityId
	);

	set @learnNewNum = (
		select floor((coalesce(maxContHour, 0) / 3) * 2) / 2
		from CourseDescription
		where CourseId = @entityId
	);
end;

with RawHoursList as (
	select ''Weekly Faculty Contact Hours'' as label
	   , coalesce(maxLectureHour, 0) as LectureValue
	   , (coalesce(maxLabHour, 0) + coalesce(maxContactHoursLab, 0)) as LabValue
	   , coalesce(maxContHour, 0) as LearnValue
	   , maxCreditHour as TotalValue
	from CourseDescription
	where CourseId = @entityId
)
, RawHoursListTotal as (
	select label
	   , LectureValue
	   , LabValue
	   , LearnValue
	   , (LectureValue + LabValue + LearnValue) as TotalValue
	from RawHoursList
)
/*
	1 = C - Is part of a cooperative work experience education program.
	206 = CWE
*/
, TFCH as (
	select case
			when @subjectId in (206)
				and @cb10Id in (1) and @createdDate < @Update then ''Total Contact Hours (Paid)''
			else ''Total Contact Hours''
		end as label
	   , ((round(LectureValue * 16.6, 2) * 100) / 100) as TFCHLectureValue
	   , ((round(LabValue * 16.6, 2) * 100) / 100) as TFCHLabValue
	   , ((round(LearnValue * 16.6, 2) * 100) / 100) as TFCHLearnValue
	   , 0 as TFCHTotal
	from RawHoursList
)
, TFCHTotal as (
	select label
	   , TFCHLectureValue
	   , TFCHLabValue
	   , TFCHLearnValue
	   , ((((TFCHLectureValue * 1) + (TFCHLabValue * 1) + (TFCHLearnValue * 1)) * 100) / 100) as TFCHTotalValue
	from TFCH
)
, LHE as (
	select ''Lecture Hour Equivalent'' as label
	   , ((round(LectureValue * 1, 2) * 100) / 100) as LHELectureValue
	   , ((round(LabValue * .833, 2) * 100) / 100) as LHELabValue
	   , ((round(LearnValue * .5, 2) * 100) / 100) as LHELearnValue
	   , 0 as LHETotal
	from RawHoursList
)
, LHETotal as (
	select label
	   , LHELectureValue
	   , LHELabValue
	   , LHELearnValue
	   , ((((LHELectureValue * 1) + (LHELabValue * 1) + (LHELearnValue * 1)) * 100) / 100) as LHETotalValue
	from LHE
)
, FTEF as (
	select ''Full Time Equivalent Faculty'' as label
	   , ((round((LectureValue / 15) * 100, 2) * 100) / 100) as FTEFLectureValue
	   , cast(round(((((round(LabValue * .833 * 100, 0) / 100) / 15) * 100) * 100), 2) / 100 as decimal(16, 2)) as FTEFLabValue
	   , ((round(LearnValue * .5, 2) * 100) / 15) as FTEFLearnValue
	   , 0 as FTEFTotal
	from RawHoursList
)
, FTEFTotal as (
	select label
	   , FTEFLectureValue
	   , FTEFLabValue
	   , FTEFLearnValue
	   , (((FTEFLectureValue + FTEFLabValue + FTEFLearnValue) * 100) / 100) as FTEFTotalValue
	from FTEF
)
, Units as (
	select ''Units'' as label
	   , LectureValue as UnitsLectureValue
	   , @labNewNum as UnitsLabValue
			,CASE WHEN @MAXUNIT IS NOT NULL
			THEN @MAXUNIT
			ELSE
	    @learnNewNum
			END as UnitsLearnValue
	   , TotalValue as UnitsTotalValue
	from RawHoursList
)
, UnitsTotal as (
	select label
	   , UnitsLectureValue
	   , UnitsLabValue
	   , UnitsLearnValue
	   , UnitsTotalValue
	from Units
)
, Outside as (
	select case
			when @courseType in (1,2) then ''Outside of Class Hours''
			else ''Outside Study Hours'' 
		end as label
	   , case
			when @courseType in (1, 2) then (LectureValue * 33.2)
			else isnull(@maxOtherHours, 0.00)
		end as OutsideValue
	   , 0 as OutsideLabValue
	   , 0 as OutsideLearnValue
	   , 0 as OutsideTotalValue
	from RawHoursList
)
, TotalStudentLearningHours as (
	select ''Total Student Learning Hours'' as label
	   , 0 as StudentValue
	   , 0 as StudentLab
	   , 0 as StudentLearn
	   , (
			(round(LectureValue * 16.6, 2) * 100) / 100
		) + 
		(
			(round(LabValue * 16.6, 2) * 100) / 100
		) + 
		(
			(round(LearnValue * 16.6, 2) * 100) / 100
		) + 
		case
			when @courseType in (1, 2) then LectureValue * 33.2
			else isnull(@maxOtherHours, 0.00)
		end as StudentTotal
	from RawHoursList
)

select 0 as [Value]
	, ''<div style="display: table-row;">
		<span style="width: 230px; display: table-cell;">
			<strong></strong>
		</span>
		<span style="width: 80px; text-align: left; display: table-cell;">
			<strong>Lecture</strong>
		</span>
		<span style="width: 80px; text-align: left; display: table-cell;">
			<strong>Lab</strong>
		</span>
		<span style="width: 80px; text-align: left; display: table-cell;">
			<strong>Learn Ctr</strong>
		</span>
		<span style="width: 80px; text-align: left; display: table-cell;">
			<strong>Total</strong>
		</span>
	</div>'' as [Text]
	, null as Label
	, null as Lecture
	, null as Lab
	, null as LearnCtr
	, null as Total
	union all
	select 0 as [Value]
		, ''<div style="display: table-row;">
			<span style="width: 230px; display: table-cell;">'' + 
				label + 
			''</span>'' + 
			''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
				cast(cast(LectureValue as decimal(6, 2)) as nvarchar(max)) + 
			''</span>'' + 
			''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
				cast(cast(LabValue as decimal(6, 2)) as nvarchar(max)) + 
			''</span>'' + 
			''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
				cast(cast(LearnValue as decimal(6, 2)) as nvarchar(max)) + 
			''</span>'' + 
			''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
				cast(cast(TotalValue as decimal(6, 2)) as nvarchar(max)) + 
			''</span>'' + 
		''</div>'' as [Text]
	, Label
	, cast(cast(LectureValue as decimal(6, 2)) as nvarchar(max)) as Lecture
	, cast(cast(LabValue as decimal(6, 2)) as nvarchar(max)) as Lab
	, cast(cast(LearnValue as decimal(6, 2)) as nvarchar(max)) as LearnCtr
	, cast(cast(TotalValue as decimal(6, 2)) as nvarchar(max)) as Total
from RawHoursListTotal
union all
select 0 as [Value]
	, ''<div style="display: table-row;">
		<span style="width: 230px; display: table-cell;">'' + 
			label + 
		''</span>'' + 
		''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
			cast(cast(TFCHLectureValue as decimal(6, 2)) as nvarchar(max)) + 
		''</span>'' + 
		''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
			cast(cast(TFCHLabValue as decimal(6, 2)) as nvarchar(max)) + 
		''</span>'' + 
		''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
			cast(cast(TFCHLearnValue as decimal(6, 2)) as nvarchar(max)) + 
		''</span>'' + 
		''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
			cast(cast(TFCHTotalValue as decimal(6, 2)) as nvarchar(max)) + 
		''</span>'' + 
	''</div>'' as [Text]
	, Label
	, cast(cast(TFCHLectureValue as decimal(6, 2)) as nvarchar(max)) as Lecture
	, cast(cast(TFCHLabValue as decimal(6, 2)) as nvarchar(max)) as Lab
	, cast(cast(TFCHLearnValue as decimal(6, 2)) as nvarchar(max)) as LearnCtr
	, cast(cast(TFCHTotalValue as decimal(6, 2)) as nvarchar(max)) as Total
from TFCHTotal
union all
select 0 as [Value]
	, ''<div style="display: table-row;">
		<span style="width: 230px; display: table-cell;">'' + 
			label + 
		''</span>'' + 
		''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
			cast(cast(LHELectureValue as decimal(6, 2)) as nvarchar(max)) + 
		''</span>'' + 
		''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
			cast(cast(LHELabValue as decimal(6, 2)) as nvarchar(max)) + 
		''</span>'' + 
		''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
			cast(cast(LHELearnValue as decimal(6, 2)) as nvarchar(max)) + 
		''</span>'' + 
		''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
			cast(cast(LHETotalValue as decimal(6, 2)) as nvarchar(max)) + 
		''</span>'' + 
	''</div>'' as [Text]
	, Label
	, cast(cast(LHELectureValue as decimal(6, 2)) as nvarchar(max)) as Lecture
	, cast(cast(LHELabValue as decimal(6, 2)) as nvarchar(max)) as Lab
	, cast(cast(LHELearnValue as decimal(6, 2)) as nvarchar(max)) as LearnCtr
	, cast(cast(LHETotalValue as decimal(6, 2)) as nvarchar(max)) as Total
from LHETotal
union all
select 0 as [Value]
	, ''<div style="display: table-row;">
		<span style="width: 230px; display: table-cell;">'' + 
			label + 
		''</span>'' + 
		''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
			cast(cast(FTEFLectureValue as decimal(6, 2)) as nvarchar(max)) + 
		''</span>'' + 
		''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
			cast(FTEFLabValue as nvarchar(max)) + 
		''</span>'' + 
		''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
			cast(cast(FTEFLearnValue as decimal(6, 2)) as nvarchar(max)) + 
		''</span>'' + 
		''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
			cast(cast(FTEFTotalValue as decimal(6, 2)) as nvarchar(max)) + 
		''</span>'' + 
	''</div>'' as [Text]
	, Label
	, cast(cast(FTEFLectureValue as decimal(6, 2)) as nvarchar(max)) as Lecture
	, cast(FTEFLabValue as nvarchar(max)) as Lab
	, cast(cast(FTEFLearnValue as decimal(6, 2)) as nvarchar(max)) as LearnCtr
	, cast(cast(FTEFTotalValue as decimal(6, 2)) as nvarchar(max)) as Total
from FTEFTotal
union all
select 0 as [Value]
	, ''<div style="display: table-row;">
		<span style="width: 230px; display: table-cell;">'' + 
			case
				when @courseType in (1, 2) then label
				else ''''
			end + 
		''</span>'' + 
		''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
			case
				when @courseType in (1, 2) then cast(cast(UnitsLectureValue as decimal(6, 2)) as nvarchar(max))
				else ''''
			end + 
		''</span>'' + 
		''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
			case
				when @courseType in (1, 2) then cast(cast(UnitsLabValue as decimal(6, 2)) as nvarchar(max))
				else ''''
			end + 
		''</span>'' + 
		''<span style="width: 80px; text-align: left;display: table-cell;">'' + 
			case
				when @courseType in (1, 2) then cast(cast(UnitsLearnValue as decimal(6, 2)) as nvarchar(max))
				else ''''
			end + 
		''</span>'' + 
		''<span style="width: 80px; text-align: left;display: table-cell;">'' + 
			case
				when @courseType in (1, 2) then cast(cast(UnitsTotalValue as decimal(6, 2)) as nvarchar(max))
				else ''''
			end + 
		''</span>'' + 
	''</div>'' as [Text]
	, Label
	, case
		when @courseType in (1, 2) then cast(cast(UnitsLectureValue as decimal(6, 2)) as nvarchar(max))
		else null
	end as Lecture
	, case
		when @courseType in (1, 2) then cast(cast(UnitsLabValue as decimal(6, 2)) as nvarchar(max))
		else null
	end as Lab
	, case
		WHEN @MAXUNIT IS NOT NULL
		THEN cast(cast(@MAXUNIT as decimal(6, 2)) as nvarchar(max))
		when @courseType in (1, 2) then cast(cast(UnitsLearnValue as decimal(6, 2)) as nvarchar(max))
		else null
	end as LearnCtr
	, case
		when @courseType in (1, 2) then cast(cast(UnitsTotalValue as decimal(6, 2)) as nvarchar(max))
		else null
	end as Total
from UnitsTotal
union all
select 0 as [Value]
	, ''<div style="display: table-row;">
		<span style="width: 230px; display: table-cell;">'' + 
			label + 	
		''</span>'' + 
		''<span style="width: 80px; text-align: left; display: table-cell;"></span>'' + 
		''<span style="width: 80px; text-align: left; display: table-cell;"></span>'' + 
		''<span style="width: 80px; text-align: left; display: table-cell;"></span>'' + 
		''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
			cast(cast(OutsideValue as decimal(6, 2)) as nvarchar(max)) + 
		''</span>'' + 
	''</div>'' as [Text]
	, Label
	, null as Lecture
	, null as Lab
	, null as LearnCtr
	, cast(cast(OutsideValue as decimal(6, 2)) as nvarchar(max)) as Total
from Outside
union all
select 0 as [Value]
	, ''<div style="display: table-row;">
		<span style="width: 230px; display: table-cell;">'' + 
			label + 
		''</span>'' + 
		''<span style="width: 80px; text-align: left; display: table-cell;"></span>'' + 
		''<span style="width: 80px; text-align: left; display: table-cell;"></span>'' + 
		''<span style="width: 80px; text-align: left; display: table-cell;"></span>'' + 
		''<span style="width: 80px; text-align: left; display: table-cell;">'' + 
			cast(cast(StudentTotal as decimal(6, 2)) as nvarchar(max)) + 
		''</span>'' + 
	''</div>'' as [Text]
	, Label
	, null as Lecture
	, null as Lab
	, null as LearnCtr
	, cast(cast(StudentTotal as decimal(6, 2)) as nvarchar(max)) as Total
from TotalStudentLearningHours;
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL2
, ResolutionSql = @SQL2
WHERE Id = 272

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId in (
		271, 272
	)
)
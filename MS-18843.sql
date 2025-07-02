USE [victorvalley];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18843';
DECLARE @Comments nvarchar(Max) = 
	'Update Hours tab for non-credit courses';
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
('Units and Hours', 'CourseDescription', 'MinOtherHour','1'),
('Units and Hours', 'CourseDescription', 'MaxOtherHour','2'),
('Units and Hours', 'CourseYesNo', 'YesNo12Id', '3'),
('Units and Hours', 'CourseDescription', 'MinContactHoursOther', '4')

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
UPDATE MetaSelectedField
SET DisplayName = 'Other min hours'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = '1'
)

UPDATE MetaSelectedField
SET DisplayName = 'Other max hours'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = '2'
)

INSERT INTO MetaSelectedFieldAttribute
(Name, Value, MetaSelectedFieldId)
SELECT 'UpdateSubscriptionTable11', 'CourseDescription', FieldId FROM @Fields WHERE Action = '3'
UNION
SELECT 'UpdateSubscriptionColumn11', 'MinOtherHour', FieldId FROM @Fields WHERE Action = '3'
UNION
SELECT 'UpdateSubscriptionTable12', 'CourseDescription', FieldId FROM @Fields WHERE Action = '3'
UNION
SELECT 'UpdateSubscriptionColumn12', 'MaxOtherHour', FieldId FROM @Fields WHERE Action = '3'

DELETE FROM MetaSelectedField
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = '4'
)

DECLARE @SQL NVARCHAR(MAX) = '
declare @text table(Id INT IDENTITY PRIMARY KEY, text nvarchar(max))
declare @IsVariable bit = (select case YesNo06Id when 1 then 1 else 0 end from CourseYesNo CYN inner join CourseCBCode CB on CYN.Courseid = CB.CourseId and CB.CB04Id <> 3 where CYN.CourseId = @entityId);
with RawHoursList as (
    		select ''Lecture Hours'' as label,
						MinLectureHour as Units,         
						(MinLectureHour * 1) as WeeklyHours,        
						(MinLectureHour * 16) as SixteenWeek,        
						(MinLectureHour * 18) as EightteenWeek,        
						(MinLectureHour * 32.0) as OutClassHours,         
						(MinLectureHour * 32.0) as TotalHours,       
						1 as IsMin   
			from CourseDescription CD
				inner join CourseCBCode CB on CD.Courseid = CB.CourseId 
					and CB.CB04Id <> 3--N - Non Credit
			where CD.CourseId = @entityId     
			union all    
			select ''Max Lecture Hours'' as label,
						MaxLectureHour as Units,         
						(MaxLectureHour * 1) as WeeklyHours,        
						(MaxLectureHour * 16) as SixteenWeek,        
						(MaxLectureHour * 18) as EightteenWeek,        
						(MaxLectureHour * 32) as OutClassHours,        
						(MaxLectureHour * 32) as TotalHours,        
						0 as IsMin    
			from CourseDescription CD
				inner join CourseCBCode CB on CD.Courseid = CB.CourseId 
					and CB.CB04Id <> 3--N - Non Credit
			where CD.CourseId = @entityId         
			union all	    
			select ''Lab Hours'' as label,
						MinLabHour as Units,         
						(MinLabHour * 3) as WeeklyHours,        
						(MinLabHour * 48) as SixteenWeek,        
						(MinLabHour * 54) as EightteenWeek,        
						(MinLabHour * 0.0) as OutClassHours,         
						(MinLabHour * 48) as TotalHours,       
						1 as IsMin    
			from CourseDescription CD
				inner join CourseCBCode CB on CD.Courseid = CB.CourseId 
					and CB.CB04Id <> 3--N - Non Credit
			where CD.CourseId = @entityId    
			union all	    
			select ''Max Lab Hours'' as label,
						MaxLabHour as Units,         
						(MaxLabHour * 3) as WeeklyHours,        
						(MaxLabHour * 48) as SixteenWeek,        
						(MaxLabHour * 54) as EightteenWeek,        
						(MaxLabHour * 0.0) as OutClassHours,        
						(MaxLabHour * 48) as TotalHours,        
						0 as IsMin    
			from CourseDescription CD
				inner join CourseCBCode CB on CD.Courseid = CB.CourseId 
					and CB.CB04Id <> 3--N - Non Credit
			where CD.CourseId = @entityId
			union all
			select ''Other Hours'' as [Label],     
				MinOtherHour as Units,         
				(0) as WeeklyHours,        
				(0) as SixteenWeek,        
				(0) as EightteenWeek,        
				(54 * MinOtherHour) as OutClassHours,  
				(54 * MinOtherHour) as TotalHours, 
				1 as IsMin    
			from CourseDescription CD
				inner join CourseCBCode CB on CD.Courseid = CB.CourseId
					and CB.CB04Id <> 3--N - Non Credit
			where CD.CourseId = @entityId
			union all	    
			select ''Max Other Hours'' as [Label],     
				MaxOtherHour as Units,         
				(0) as WeeklyHours,        
				(0) as SixteenWeek,        
				(0) as EightteenWeek,        
				(54 * MaxOtherHour) as OutClassHours, 
				(54 * MaxOtherHour) as TotalHours, 
				0 as IsMin    
			from CourseDescription CD
				inner join CourseCBCode CB on CD.Courseid = CB.CourseId 
					and CB.CB04Id <> 3--N - Non Credit
			where CD.CourseId = @entityId
			union all
			select ''Lecture Hours'' as [Label],
						0 as Units,         
						(MinContactHoursLecture / 16.0) as WeeklyHours,        
						MinContactHoursLecture as SixteenWeek,
						MaxContactHoursLecture as EightteenWeek,
						0 as OutClassHours,
						0 as TotalHours,        
						1 as IsMin   
			from CourseDescription CD
				inner join CourseCBCode CB on CD.Courseid = CB.CourseId 
					and CB.CB04Id = 3--N - Non Credit
			where CD.CourseId = @entityId            
			union all	    
			select ''Lab Hours'' as [Label],
						0 as Units,         
						(MinContactHoursLab  / 16.0) as WeeklyHours,        
						MinContactHoursLab as SixteenWeek,
						MaxContactHoursLab as EightteenWeek,
						(MinContactHoursLab * 0) as OutClassHours,           
						(MinContactHoursLab * 0) as TotalHours,            
						1 as IsMin    
			from CourseDescription CD
				inner join CourseCBCode CB on CD.Courseid = CB.CourseId 
					and CB.CB04Id = 3--N - Non Credit
			where CD.CourseId = @entityId    
			union all	
			select ''Other Hours'' as [Label],     
				MinOtherHour as Units,         
				(0) as WeeklyHours,        
				(0) as SixteenWeek,        
				(0) as EightteenWeek,        
				MinOtherHour as OutClassHours,  
				MinOtherHour as TotalHours, 
				1 as IsMin    
			from CourseDescription CD
				inner join CourseCBCode CB on CD.Courseid = CB.CourseId
					and CB.CB04Id = 3
			where CD.CourseId = @entityId
			union all	    
			select ''Max Other Hours'' as [Label],     
				MaxOtherHour as Units,         
				(0) as WeeklyHours,        
				(0) as SixteenWeek,        
				(0) as EightteenWeek,        
				MaxOtherHour as OutClassHours, 
				MaxOtherHour as TotalHours, 
				0 as IsMin    
			from CourseDescription CD
				inner join CourseCBCode CB on CD.Courseid = CB.CourseId 
					and CB.CB04Id = 3--N - Non Credit
			where CD.CourseId = @entityId
			),
	RawHoursListTotal as (	    
			select [Label],
						Units,        
						WeeklyHours,        
						SixteenWeek,         
						EightteenWeek,         
						OutClassHours,
						TotalHours,
						IsMin     
			from RawHoursList     
			union ALL	    
			select ''Total Hours'' as [Label],    
					SUM(Units) as Units,         
					SUM(WeeklyHours) as WeeklyHours,        
					SUM(SixteenWeek) as SixteenWeek,        
					SUM(EightteenWeek) as EightteenWeek,        
					SUM(OutClassHours) as OutClassHours,       
					SUM(TotalHours) as TotalHours,             
					1 as IsMin     
			from RawHoursList    
			where IsMin = 1    
			union ALL	    
			select ''Total Max Hours'' as [Label],     
				SUM(Units) as Units,         
				SUM(WeeklyHours) as WeeklyHours,        
				SUM(SixteenWeek) as SixteenWeek,        
				SUM(EightteenWeek) as EightteenWeek,        
				SUM(OutClassHours) as OutClassHours,         
				SUM(TotalHours) as TotalHours,          
				0 as IsMin     
			from RawHoursList RHL 		
			where IsMin = 0),
		HoursList as (	   
			select Label,       
					coalesce(Units, 0) as Units,             
					coalesce(WeeklyHours, 0) as WeeklyHours,            
					coalesce(SixteenWeek, 0) as SixteenWeek,             
					coalesce(EightteenWeek, 0) as EightteenWeek,             
					coalesce(OutClassHours, 0) as OutClassHours,             
					coalesce(TotalHours, 0) as TotalHours,            
					IsMin	        
			from RawHoursListTotal)


INSERT INTO @text ([Text])            
select 
	concat(
		''<div style="display: table; border-collapse: collapse; border: 1px solid; width: auto;">'',
		''<div style="display: table-row; border-bottom: 1px solid;">'',
			''<span style="width: 150px; display: table-cell; border: 1px solid;"><strong>Hour Type</strong></span>'',
			''<span style="width: 80px; text-align: center; display: table-cell; border: 1px solid;"><strong>'',
			case
				when CB04Id <> 3
					then ''Units''
				else ''Hours''
			end
			,''</strong></span>'',
			''<span style="width: 100px; text-align: center; display: table-cell; border: 1px solid;"><strong>Contact Hours <br /> (Total Semester Hours - Min)</strong></span>'',
			''<span style="width: 100px; text-align: center; display: table-cell; border: 1px solid;"><strong>Contact Hours <br /> (Total Semester Hours - Max)</strong></span>'',
			CasE WHEN CB04Id <> 3 THEN 
				''<span style="width: 150px; text-align: center; display: table-cell; border: 1px solid;"><strong>Outside-Of-Class <br /> Hours</strong></span>''
			else '''' end,
			case
				when CB04Id <> 3--N - Non Credit
					then ''<span style="width: 100px; text-align: center; display: table-cell; border: 1px solid;"><strong>Total Hours</strong></span>''
				else ''''
			end,
		''</div>''
	) as [Text]
from CourseCBCode
where Courseid = @entityId

UNION ALL

select 
	concat(
		''<div style="display: table-row;">'',
			''<span style="width: 150px; display: table-cell; border: 1px solid;">'' + Label + ''</span>'',
			''<span style="width: 80px; text-align: center; display: table-cell; border: 1px solid;">'' + FORMAT(Units, ''0.00'')  + ''</span>'',
			''<span style="width: 100px; text-align: center; display: table-cell; border: 1px solid;">'' + FORMAT(SixteenWeek, ''0.00'') + ''</span>'',
			''<span style="width: 100px; text-align: center; display: table-cell; border: 1px solid;">'' + FORMAT(EightteenWeek, ''0.00'')  + ''</span>'',
			CasE WHEN CB04Id <> 3 THEN 
				''<span style="width: 150px; text-align: center; display: table-cell; border: 1px solid;">'' + FORMAT(OutClassHours, ''0.00'')+ ''</span>''
			else '''' end,
			case
				when CB04Id <> 3--N - Non Credit
					then ''<span style="width: 100px; text-align: center; display: table-cell; border: 1px solid;">'' + FORMAT(TotalHours, ''0.00'') + ''</span>''
				else ''''
			end,
		''</div>'',
		''</div>''
	) as [Text]
from HoursList HL
INNER JOIN CourseCBCode CB ON CB.Courseid = @entityId
where @IsVariable = 1 OR IsMin = 1 OR CB.CB04Id = 3;

select dbo.concatWithSep_Agg('''', [Text]) as [Text], 0 as [Value] from @text
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 131

SET @SQL = '
declare @isVariable bit = (
			select case YesNo06Id when 1 then 1 else 0 end from CourseYesNo CYN inner join CourseCBCode CB on CYN.Courseid = CB.CourseId and CB.CB04Id <> 3 where CYN.CourseId = @entityId
		);

		declare @noncredit bit = (
			SELECT CASE WHEN CB.cb04Id = 3 THEN 1 ELSE 0 END FROM CourseCBCode AS cb
				WHERE cb.CourseId = @EntityId
		);

		with RawHoursList as (
			select ''Lecture Hours'' as [Label],
				MinLectureHour as Units,         
				(MinLectureHour * 1) as WeeklyHours,        
				(MinLectureHour * 16) as SixteenWeek,        
				(MinLectureHour * 18) as EightteenWeek,        
				(MinLectureHour * 32.0) as OutClassHours,
				(MinLectureHour * 32.0) as TotalHours,
				1 as IsMin   
			from CourseDescription CD
				inner join CourseCBCode CB on CD.Courseid = CB.CourseId 
					and CB.CB04Id <> 3--N - Non Credit
			where CD.CourseId = @entityId     
			union all    
			select ''Max Lecture Hours'' as [Label],
				MaxLectureHour as Units,         
				(MaxLectureHour * 1) as WeeklyHours,        
				(MaxLectureHour * 16) as SixteenWeek,        
				(MaxLectureHour * 18) as EightteenWeek,        
				(MaxLectureHour * 32) as OutClassHours,
				(MaxLectureHour * 32) as TotalHours,
				0 as IsMin    
			from CourseDescription CD
				inner join CourseCBCode CB on CD.Courseid = CB.CourseId 
					and CB.CB04Id <> 3--N - Non Credit
			where CD.CourseId = @entityId         
			union all	    
			select ''Lab Hours'' as [Label],
				MinLabHour as Units,         
				(MinLabHour * 3) as WeeklyHours,        
				(MinLabHour * 48) as SixteenWeek,        
				(MinLabHour * 54) as EightteenWeek,        
				(MinLabHour * 0.0) as OutClassHours,
				(MinLabHour * 48) as TotalHours,
				1 as IsMin    
			from CourseDescription CD
				inner join CourseCBCode CB on CD.Courseid = CB.CourseId 
					and CB.CB04Id <> 3--N - Non Credit
			where CD.CourseId = @entityId    
			union all	    
			select ''Max Lab Hours'' as [Label],
				MaxLabHour as Units,         
				(MaxLabHour * 3) as WeeklyHours,        
				(MaxLabHour * 48) as SixteenWeek,        
				(MaxLabHour * 54) as EightteenWeek,        
				(MaxLabHour * 0.0) as OutClassHours,
				(MaxLabHour * 48) as TotalHours,
				0 as IsMin    
			from CourseDescription CD
				inner join CourseCBCode CB on CD.Courseid = CB.CourseId 
					and CB.CB04Id <> 3--N - Non Credit
			where CD.CourseId = @entityId
			union all
			select ''Other Hours'' as [Label],     
				MinOtherHour as Units,         
				(0) as WeeklyHours,        
				(0) as SixteenWeek,        
				(0) as EightteenWeek,        
				(54 * MinOtherHour) as OutClassHours,
				(54 * MinOtherHour) as TotalHours,
				1 as IsMin    
			from CourseDescription CD
				inner join CourseCBCode CB on CD.Courseid = CB.CourseId
					and CB.CB04Id <> 3--N - Non Credit
			where CD.CourseId = @entityId
			union all	    
			select ''Max Other Hours'' as [Label],     
				MaxOtherHour as Units,         
				(0) as WeeklyHours,        
				(0) as SixteenWeek,        
				(0) as EightteenWeek,        
				(54 * MaxOtherHour) as OutClassHours,
				(54 * MaxOtherHour) as TotalHours,
				0 as IsMin    
			from CourseDescription CD
				inner join CourseCBCode CB on CD.Courseid = CB.CourseId
					and CB.CB04Id <> 3--N - Non Credit
			where CD.CourseId = @entityId
			union all
			select ''Lecture Hours'' as [Label],
				0 as Units,         
				(MinContactHoursLecture / 16.0) as WeeklyHours,
				MinContactHoursLecture as SixteenWeek,
				MaxContactHoursLecture as EightteenWeek,
				0 as OutClassHours,
				0 as TotalHours,
				1 as IsMin   
			from CourseDescription CD
				inner join CourseCBCode CB on CD.Courseid = CB.CourseId 
					and CB.CB04Id = 3--N - Non Credit
			where CD.CourseId = @entityId            
			union all	    
			select ''Lab Hours'' as [Label],
				0 as Units,         
				(MinContactHoursLab  / 16.0) as WeeklyHours,
				MinContactHoursLab as SixteenWeek,
				MaxContactHoursLab as EightteenWeek,
				(MinContactHoursLab * 0) as OutClassHours,
				(MinContactHoursLab * 0) as TotalHours,
				1 as IsMin    
			from CourseDescription CD
				inner join CourseCBCode CB on CD.Courseid = CB.CourseId 
					and CB.CB04Id = 3--N - Non Credit
			where CD.CourseId = @entityId    
			union all
			select ''Other Hours'' as [Label],     
				MinOtherHour as Units,         
				(0) as WeeklyHours,        
				(0) as SixteenWeek,        
				(0) as EightteenWeek,        
				(54 * MinOtherHour) as OutClassHours,
				(54 * MinOtherHour) as TotalHours,
				1 as IsMin    
			from CourseDescription CD
				inner join CourseCBCode CB on CD.Courseid = CB.CourseId
					and CB.CB04Id = 3
			where CD.CourseId = @entityId
			union all	    
			select ''Max Other Hours'' as [Label],     
				MaxOtherHour as Units,         
				(0) as WeeklyHours,        
				(0) as SixteenWeek,        
				(0) as EightteenWeek,        
				MaxOtherHour as OutClassHours, 
				MaxOtherHour as TotalHours, 
				0 as IsMin    
			from CourseDescription CD
				inner join CourseCBCode CB on CD.Courseid = CB.CourseId 
					and CB.CB04Id = 3--N - Non Credit
			where CD.CourseId = @entityId
		)
		, RawHoursListTotal as (
			select [Label],
				Units,        
				WeeklyHours,        
				SixteenWeek,         
				EightteenWeek,         
				OutClassHours,
				TotalHours,
				IsMin
			from RawHoursList     
			union all	    
			select ''Total Hours'' as [Label],    
				sum(Units) as Units,         
				sum(WeeklyHours) as WeeklyHours,        
				sum(SixteenWeek) as SixteenWeek,        
				sum(EightteenWeek) as EightteenWeek,        
				sum(OutClassHours) as OutClassHours,
				SUM(TotalHours) as TotalHours,
				1 as IsMin
			from RawHoursList    
			where IsMin = 1    
			union all	    
			select ''Total Max Hours'' as [Label],     
				sum(Units) as Units,         
				sum(WeeklyHours) as WeeklyHours,        
				sum(SixteenWeek) as SixteenWeek,        
				sum(EightteenWeek) as EightteenWeek,        
				sum(OutClassHours) as OutClassHours,
				SUM(TotalHours) as TotalHours,
				0 as IsMin     
			from RawHoursList    
			where IsMin = 0
		)
		, HoursList as (	   
			select [Label],       
				coalesce(Units, 0) as Units,             
				coalesce(WeeklyHours, 0) as WeeklyHours,            
				coalesce(SixteenWeek, 0) as SixteenWeek,             
				coalesce(EightteenWeek, 0) as EightteenWeek,             
				coalesce(OutClassHours, 0) as OutClassHours,             
				coalesce(TotalHours, 0) as TotalHours,              
				IsMin	        
			from RawHoursListTotal
		)            
		select 0 as [Value],
			concat(
				''<style type="text/css">
					.tg  {border-collapse:collapse;border-spacing:0;}
					.tg td{border-color:black;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;
				overflow:hidden;padding:10px 5px;word-break:normal;}
					.tg th{border-color:black;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;
				font-weight:normal;overflow:hidden;padding:10px 5px;word-break:normal;}
					.tg .tg-pu0z{background-color:#9b9b9b;border-color:#333333;font-weight:bold;text-align:center;vertical-align:top}
					.tg .tg-y698{background-color:#efefef;border-color:#333333;text-align:center;vertical-align:top}
					.tg .tg-c6of{background-color:#ffffff;border-color:#333333;text-align:center;vertical-align:top}
				</style>
				<table class="tg">
					<thead>
						<tr>
							<th class="tg-pu0z">Hour Type</th>
							<th class="tg-pu0z">'',
							case
								when CB04Id <> 3--N - Non Credit
									then ''Units''
								else ''Hours''
							end
							,''</th>
							<th class="tg-pu0z">Contact Hours (Total Semester Hours - Min)</th>
							<th class="tg-pu0z">Contact Hours (Total Semester Hours - Max)</th>
							''
							, case
								when CB04Id <> 3--N - Non Credit
									then ''<th class="tg-pu0z">Outside-Of-Class Hours</th>''
								else ''''
							end
							, case
								when CB04Id <> 3--N - Non Credit
									then ''<th class="tg-pu0z">Total Hours</th>''
								else ''''
							end
						, ''</tr>
					</thead>
					<tbody>
				''
			) as [Text]
		from CourseCBCode
		where CourseId = @entityId
		union all
		select 0 as [Value]
			, ''<tr>      
				<td class="tg-y698">'' + [Label] + ''</td> 
				<td class="tg-c6of">'' + FORMAT(Units, ''0.00'') + ''</td>       
				<td class="tg-c6of">'' + FORMAT(SixteenWeek, ''0.00'')  + ''</td>       
				<td class="tg-c6of">'' + FORMAT(EightteenWeek, ''0.00'')  + ''</td>'' + 
				case
					when CB.CB04Id <> 3--N - Non Credit
						then ''<td class="tg-c6of">'' + FORMAT(OutClassHours, ''0.00'') + ''</td>''
					else ''''
				end +
				case
					when CB.CB04Id <> 3--N - Non Credit
						then ''<td class="tg-c6of">'' + FORMAT(TotalHours, ''0.00'') + ''</td>''
					else ''''
				end +
			''</tr>'' as [Text]
		from HoursList HL
			inner join CourseCBCode CB on CB.CourseId = @entityId
		where @isVariable = 1
		or IsMin = 1
		or @Noncredit = 1
		union all
		select 0 as [Value]
			, ''</tbody></table>'' as [Text];
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 162
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (
	select templateId FROM @Fields
	UNION
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId in (131, 162)
)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback
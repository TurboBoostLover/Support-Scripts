USE [victorvalley];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15175';
DECLARE @Comments nvarchar(Max) = 
	'Update query in Report';
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
DECLARE @SQL NVARCHAR(MAX) = '
declare @IsVariable bit = (select case YesNo06Id when 1 then 1 else 0 end from CourseYesNo where CourseId = @EntityId);
with RawHoursList as (
    	    select ''Lecture Hours'' as label,
                     MinLectureHour as Units,         
                     (MinLectureHour * 1) as WeeklyHours,        
                     (MinLectureHour * 16) as SixteenWeek,        
                     (MinLectureHour * 18) as EightteenWeek,        
                     (MinLectureHour * 32.0) as OutClassHours,        
                     1 as IsMin   
            from CourseDescription     
            where CourseId = @EntityId     
            union all    
            select ''Max Lecture Hours'' as label,
                     MaxLectureHour as Units,         
                     (MaxLectureHour * 1) as WeeklyHours,        
                     (MaxLectureHour * 16) as SixteenWeek,        
                     (MaxLectureHour * 18) as EightteenWeek,        
                     (MaxLectureHour * 32) as OutClassHours,        
                     0 as IsMin    
            from CourseDescription     
            where CourseId = @EntityId         
            union all	    
            select ''Lab Hours'' as label,
                     MinLabHour as Units,         
                     (MinLabHour * 3) as WeeklyHours,        
                     (MinLabHour * 48) as SixteenWeek,        
                     (MinLabHour * 54) as EightteenWeek,        
                     (MinLabHour * 0.0) as OutClassHours,        
                     1 as IsMin    
            from CourseDescription     
            where CourseId = @EntityId    
            union all	    
            select ''Max Lab Hours'' as label,
                     MaxLabHour as Units,         
                     (MaxLabHour * 3) as WeeklyHours,        
                     (MaxLabHour * 48) as SixteenWeek,        
                     (MaxLabHour * 54) as EightteenWeek,        
                     (MaxLabHour * 0.0) as OutClassHours,        
                     0 as IsMin    
            from CourseDescription     
            where CourseId = @EntityId
            union all	    
            select ''Field Work Hours'' as label,     
                    MinContHour as Units,         
                    (MinContHour * 2) as WeeklyHours,        
                    (MinContHour * 32) as SixteenWeek,        
                    (MinContHour * 36) as EightteenWeek,        
                    (MinContHour * 16) as OutClassHours,        
                    1 as IsMin    
            from CourseDescription     
            where CourseId = @EntityId     
            union all    
            select ''Max Field Work Hours'' as label,
                     MaxContHour as Units,         
                     (MaxContHour * 2) as WeeklyHours,        
                     (MaxContHour * 32) as SixteenWeek,        
                     (MaxContHour * 36) as EightteenWeek,        
                     (MaxContHour * 16) as OutClassHours,        
                     0 as IsMin    
            from CourseDescription     
            where CourseId = @EntityId ),
    RawHoursListTotal as (	    
            select Label,
                     Units,        
                     WeeklyHours,        
                     SixteenWeek,         
                     EightteenWeek,         
                     OutClassHours,        
                     IsMin     
            from RawHoursList     
            union ALL	    
            select ''Total'' as Label,    
                 SUM(Units) AS Units,         
                 SUM(WeeklyHours) as WeeklyHours,        
                 SUM(SixteenWeek) as SixteenWeek,        
                 SUM(EightteenWeek) as EightteenWeek,        
                 SUM(OutClassHours) AS OutClassHours,        
                 1 as IsMin     
            FROM RawHoursList    
            where IsMin = 1    
            union ALL	    
            select ''Total Max'' as Label,     
                SUM(Units) AS Units,         
                SUM(WeeklyHours) as WeeklyHours,        
                SUM(SixteenWeek) as SixteenWeek,        
                SUM(EightteenWeek) as EightteenWeek,        
                SUM(OutClassHours) AS OutClassHours,        
                0 as IsMin     
            FROM RawHoursList    
            where IsMin = 0),
        HoursList as (	   
            select Label,       
                  coalesce(Units, 0) as Units,             
                  coalesce(WeeklyHours, 0) as WeeklyHours,            
                  coalesce(SixteenWeek, 0) as SixteenWeek,             
                  coalesce(EightteenWeek, 0) as EightteenWeek,             
                  coalesce(OutClassHours, 0) as OutClassHours,            
                  IsMin	        
            from RawHoursListTotal)
            
    SELECT 0 AS Value,
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
					<th class="tg-pu0z">Units</th>
					
					<th class="tg-pu0z">Contact Hours (Total Semester Hours - Min)</th>
					<th class="tg-pu0z">Contact Hours (Total Semester Hours - Max)</th>
					<th class="tg-pu0z">Outside-Of-Class Hours</th>
					<th class="tg-pu0z">Total Hours</th>
				</tr>
			</thead>
			<tbody>'' AS Text
    UNION ALL
    SELECT 0 AS Value,
        ''<tr>      
			<td class="tg-y698">'' + Label + ''</td> 
			<td class="tg-c6of">'' + LEFT(CAST((Units) AS NVARCHAR(MAX)), LEN(Units) - 2)+ ''</td>       
			<td class="tg-c6of">'' + LEFT(CAST((SixteenWeek) AS NVARCHAR(MAX)), LEN(SixteenWeek) - 2)+ ''</td>       
			<td class="tg-c6of">'' + LEFT(CAST((EightteenWeek) AS NVARCHAR(MAX)), LEN(EightteenWeek) - 2)+ ''</td>        
			<td class="tg-c6of">'' + LEFT(CAST((OutClassHours) AS NVARCHAR(MAX)), LEN(OutClassHours) - 3)+ ''</td>        
			<td class="tg-c6of">'' + LEFT(CAST((OutClassHours + SixteenWeek) AS NVARCHAR(MAX)), LEN(OutClassHours + SixteenWeek) - 2)+ ''</td>   
        </tr>'' AS Text FROM HoursList
        where @IsVariable = 1 OR IsMin = 1
	UNION All
	SELECT 0 AS Value,
		''</tbody>
		</table>'' As Text
'

DECLARE @SQL2 NVARCHAR(MAX) = '
declare @IsVariable bit = (select case YesNo06Id when 1 then 1 else 0 end from CourseYesNo CYN inner join CourseCBCode CB on CYN.Courseid = CB.CourseId and CB.CB04Id <> 3 where CYN.CourseId = @EntityId);
with RawHoursList as (
    	    select ''Lecture Hours'' as label,
                     MinLectureHour as Units,         
                     (MinLectureHour * 1) as WeeklyHours,        
                     (MinLectureHour * 16) as SixteenWeek,        
                     (MinLectureHour * 18) as EightteenWeek,        
                     (MinLectureHour * 32.0) as OutClassHours,        
                     1 as IsMin   
            from CourseDescription CD
				inner join CourseCBCode CB on CD.Courseid = CB.CourseId 
					and CB.CB04Id <> 3
            where CD.CourseId = @EntityId     
            union all    
            select ''Max Lecture Hours'' as label,
                     MaxLectureHour as Units,         
                     (MaxLectureHour * 1) as WeeklyHours,        
                     (MaxLectureHour * 16) as SixteenWeek,        
                     (MaxLectureHour * 18) as EightteenWeek,        
                     (MaxLectureHour * 32) as OutClassHours,        
                     0 as IsMin    
            from CourseDescription CD
				inner join CourseCBCode CB on CD.Courseid = CB.CourseId 
					and CB.CB04Id <> 3    
            where CD.CourseId = @EntityId         
            union all	    
            select ''Lab Hours'' as label,
                     MinLabHour as Units,         
                     (MinLabHour * 3) as WeeklyHours,        
                     (MinLabHour * 48) as SixteenWeek,        
                     (MinLabHour * 54) as EightteenWeek,        
                     (MinLabHour * 0.0) as OutClassHours,        
                     1 as IsMin    
            from CourseDescription CD
				inner join CourseCBCode CB on CD.Courseid = CB.CourseId 
					and CB.CB04Id <> 3     
            where CD.CourseId = @EntityId    
            union all	    
            select ''Max Lab Hours'' as label,
                     MaxLabHour as Units,         
                     (MaxLabHour * 3) as WeeklyHours,        
                     (MaxLabHour * 48) as SixteenWeek,        
                     (MaxLabHour * 54) as EightteenWeek,        
                     (MaxLabHour * 0.0) as OutClassHours,        
                     0 as IsMin    
            from CourseDescription CD
				inner join CourseCBCode CB on CD.Courseid = CB.CourseId 
					and CB.CB04Id <> 3     
            where CD.CourseId = @EntityId
            union all	    
            select ''Field Work Hours'' as label,     
                    MinContHour as Units,         
                    (MinContHour * 2) as WeeklyHours,        
                    (MinContHour * 32) as SixteenWeek,        
                    (MinContHour * 36) as EightteenWeek,        
                    (MinContHour * 16) as OutClassHours,        
                    1 as IsMin    
            from CourseDescription CD
				inner join CourseCBCode CB on CD.Courseid = CB.CourseId 
					and CB.CB04Id <> 3     
            where CD.CourseId = @EntityId     
            union all    
            select ''Max Field Work Hours'' as label,
                     MaxContHour as Units,         
                     (MaxContHour * 2) as WeeklyHours,        
                     (MaxContHour * 32) as SixteenWeek,        
                     (MaxContHour * 36) as EightteenWeek,        
                     (MaxContHour * 16) as OutClassHours,        
                     0 as IsMin    
            from CourseDescription CD
				inner join CourseCBCode CB on CD.Courseid = CB.CourseId 
					and CB.CB04Id <> 3     
            where CD.CourseId = @EntityId
			union all
			select ''Lecture Hours'' as label,
                     0 as Units,         
                     (MinContactHoursLecture / 16.0) as WeeklyHours,        
                     (MinContactHoursLecture ) as SixteenWeek,        
                     (MinContactHoursLecture * 18.0 / 16.0 ) as EightteenWeek,        
                     (MinContactHoursLecture * 2.0) as OutClassHours,        
                     1 as IsMin   
            from CourseDescription CD
				inner join CourseCBCode CB on CD.Courseid = CB.CourseId 
					and CB.CB04Id = 3
            where CD.CourseId = @EntityId            
            union all	    
            select ''Lab Hours'' as label,
                     0 as Units,         
                     (MinContactHoursLab  / 16.0) as WeeklyHours,        
                     (MinContactHoursLab) as SixteenWeek,        
                     (MinContactHoursLab * 54.0 / 48.0) as EightteenWeek,        
                     (MinContactHoursLab * 0) as OutClassHours,        
                     1 as IsMin    
            from CourseDescription CD
				inner join CourseCBCode CB on CD.Courseid = CB.CourseId 
					and CB.CB04Id = 3     
            where CD.CourseId = @EntityId    
            union all	    
            select ''Field Work Hours'' as label,     
                    0 as Units,         
                    (MinContactHoursOther / 16.0) as WeeklyHours,        
                    (MinContactHoursOther) as SixteenWeek,        
                    (MinContactHoursOther * 36.0 / 32.0 ) as EightteenWeek,        
                    (MinContactHoursOther / 2.0) as OutClassHours,        
                    1 as IsMin    
            from CourseDescription CD
				inner join CourseCBCode CB on CD.Courseid = CB.CourseId 
					and CB.CB04Id = 3     
            where CD.CourseId = @EntityId),
    RawHoursListTotal as (	    
            select Label,
                     Units,        
                     WeeklyHours,        
                     SixteenWeek,         
                     EightteenWeek,         
                     OutClassHours,        
                     IsMin     
            from RawHoursList     
            union ALL	    
            select ''Total'' as Label,    
                 SUM(Units) AS Units,         
                 SUM(WeeklyHours) as WeeklyHours,        
                 SUM(SixteenWeek) as SixteenWeek,        
                 SUM(EightteenWeek) as EightteenWeek,        
                 SUM(OutClassHours) AS OutClassHours,        
                 1 as IsMin     
            FROM RawHoursList    
            where IsMin = 1    
            union ALL	    
            select ''Total Max'' as Label,     
                SUM(Units) AS Units,         
                SUM(WeeklyHours) as WeeklyHours,        
                SUM(SixteenWeek) as SixteenWeek,        
                SUM(EightteenWeek) as EightteenWeek,        
                SUM(OutClassHours) AS OutClassHours,        
                0 as IsMin     
            FROM RawHoursList RHL 		
            where IsMin = 0),
        HoursList as (	   
            select Label,       
                  coalesce(Units, 0) as Units,             
                  coalesce(WeeklyHours, 0) as WeeklyHours,            
                  coalesce(SixteenWeek, 0) as SixteenWeek,             
                  coalesce(EightteenWeek, 0) as EightteenWeek,             
                  coalesce(OutClassHours, 0) as OutClassHours,            
                  IsMin	        
            from RawHoursListTotal)
            
    SELECT 0 AS Value,
        ''<div style="display: table-row;border-bottom:1px solid;">        
        <span style="width:150px;display: inline-block;display: table-cell;"><strong>Hour Type</strong></span>        
        <span style="width:80px;text-align: center;display: table-cell;"><strong>Units</strong></span>        
                
        <span style="width:100px;text-align: center;display: table-cell;"><strong>Contact Hours <br /> (Total Semester Hours - Min)</strong></span>        
        <span style="width:100px;text-align: center;display: table-cell;"><strong>Contact Hours <br /> (Total Semester Hours - Max)</strong></span>        
        <span style="width:150px;text-align: center;display: table-cell;"><strong>Outside-Of-Class <br /> Hours</strong></span>        
        <span style="width:100px;text-align: center;display: table-cell;"><strong>Total Hours</strong></span>    </div>'' AS Text,    
        NULL AS Units,    
        NULL AS WeeklyHours,     
        NULL AS SixteenWeek,     
        NULL AS EightteenWeek,     
        NULL AS OutClassHours,    
        NULL AS Label,    
        NULL AS IsMin
    UNION ALL
    SELECT 0 AS Value,
        ''<div style="display: table-row;">        
        <span style="width:150px;display: inline-block;display: table-cell;">'' + Label + ''</span>        
        <span style="width:80px;text-align: center;display: table-cell;">'' + LEFT(CAST((Units) AS NVARCHAR(MAX)), LEN(Units) - 2)+  ''</span>        
        <span style="width:100px;text-align: center;display: table-cell;">'' + LEFT(CAST((SixteenWeek) AS NVARCHAR(MAX)), LEN(SixteenWeek) - 2)+ ''</span>        
        <span style="width:100px;text-align: center;display: table-cell;">'' + LEFT(CAST((EightteenWeek) AS NVARCHAR(MAX)), LEN(EightteenWeek) - 2)+ ''</span>        
        <span style="width:150px;text-align: center;display: table-cell;">'' + LEFT(CAST((OutClassHours) AS NVARCHAR(MAX)), LEN(OutClassHours) - 3)+ ''</span>        
        <span style="width:100px;text-align: center;display: table-cell;">'' + LEFT(CAST((OutClassHours + SixteenWeek) AS NVARCHAR(MAX)), LEN(OutClassHours + SixteenWeek) - 2)+ ''</span>    
        </div>'' AS Text,    (Units) AS Units,WeeklyHours, SixteenWeek, EightteenWeek,OutClassHours, (SixteenWeek + OutClassHours) as [MinTotalCorseHours], Label AS Label 
		FROM HoursList
        where @IsVariable = 1 OR IsMin = 1;
'

UPDATE MetaForeignKeyCriteriaClient 
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 162

UPDATE MetaForeignKeyCriteriaClient 
SET CustomSql = @SQL2
, ResolutionSql = @SQL2
WHERE Id = 131

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mt.MetaTemplateId FROM MetaTemplate AS mt
	INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE Msf.MetaForeignKeyLookupSourceId in (162, 131)
)
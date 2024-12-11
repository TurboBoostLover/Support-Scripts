USE [victorvalley];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17096';
DECLARE @Comments nvarchar(Max) = 
	'Update Units and Hours Tab';
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
DECLARE @TEXT TABLE (AttId int, TempId int)
INSERT INTO @TEXT
SELECT msfa.Id, mss.MetaTemplateId FROM MetaSelectedFieldAttribute AS msfa
INNER Join MetaSelectedField AS msf on msfa.MetaSelectedFieldId = msf.MetaSelectedFieldId
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE Name = 'subtext' and Value like '%You will need to save the page%'
UNION
SELECT msfa.Id, mss.MetaTemplateId FROM MetaSelectedFieldAttribute AS msfa
INNER Join MetaSelectedField AS msf on msfa.MetaSelectedFieldId = msf.MetaSelectedFieldId
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE Name = 'helptext' and Value like '%You will need to save the page%'

DELETE FROM MetaSelectedFieldAttribute
WHERE Id in (
	SELECT AttId FROM @TEXT
)

DECLARE @SQL NVARCHAR(MAX) = '
DECLARE @text table(Id INT IDENTITY PRIMARY KEY, text nvarchar(max))
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
                     0 as OutClassHours,        
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
                    0 as OutClassHours,        
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

INSERT INTO @text (text)            
SELECT 
    CONCAT(
        ''<div style="display: table; border-collapse: collapse; border: 1px solid; width: auto;">'',
        ''<div style="display: table-row; border-bottom: 1px solid;">'',
            ''<span style="width: 150px; display: table-cell; border: 1px solid;"><strong>Hour Type</strong></span>'',
            ''<span style="width: 80px; text-align: center; display: table-cell; border: 1px solid;"><strong>Units</strong></span>'',
            ''<span style="width: 100px; text-align: center; display: table-cell; border: 1px solid;"><strong>Contact Hours <br /> (Total Semester Hours - Min)</strong></span>'',
            ''<span style="width: 100px; text-align: center; display: table-cell; border: 1px solid;"><strong>Contact Hours <br /> (Total Semester Hours - Max)</strong></span>'',
            CASE WHEN CB04Id <> 3 THEN 
                ''<span style="width: 150px; text-align: center; display: table-cell; border: 1px solid;"><strong>Outside-Of-Class <br /> Hours</strong></span>''
            ELSE '''' END,
            ''<span style="width: 100px; text-align: center; display: table-cell; border: 1px solid;"><strong>Total Hours</strong></span>'',
        ''</div>''
    ) AS Text
FROM CourseCBCode
WHERE Courseid = @entityid

UNION ALL

SELECT 
    CONCAT(
        ''<div style="display: table-row;">'',
            ''<span style="width: 150px; display: table-cell; border: 1px solid;">'' + Label + ''</span>'',
            ''<span style="width: 80px; text-align: center; display: table-cell; border: 1px solid;">'' + LEFT(CAST(Units AS NVARCHAR(MAX)), LEN(Units) - 2) + ''</span>'',
            ''<span style="width: 100px; text-align: center; display: table-cell; border: 1px solid;">'' + LEFT(CAST(SixteenWeek AS NVARCHAR(MAX)), LEN(SixteenWeek) - 2) + ''</span>'',
            ''<span style="width: 100px; text-align: center; display: table-cell; border: 1px solid;">'' + LEFT(CAST(EightteenWeek AS NVARCHAR(MAX)), LEN(EightteenWeek) - 2) + ''</span>'',
            CASE WHEN CB04Id <> 3 THEN 
                ''<span style="width: 150px; text-align: center; display: table-cell; border: 1px solid;">'' + LEFT(CAST(OutClassHours AS NVARCHAR(MAX)), LEN(OutClassHours) - 3) + ''</span>''
            ELSE '''' END,
            ''<span style="width: 100px; text-align: center; display: table-cell; border: 1px solid;">'' + LEFT(CAST(OutClassHours + SixteenWeek AS NVARCHAR(MAX)), LEN(OutClassHours + SixteenWeek) - 2) + ''</span>'',
        ''</div>'',
        ''</div>''
    ) AS Text
FROM HoursList HL
INNER JOIN CourseCBCode CB ON CB.Courseid = @entityid
WHERE @IsVariable = 1 OR IsMin = 1;

SELECT dbo.ConcatWithSep_Agg('''', text)AS Text, 0 as Value FROM @text
'

UPDATE MetaForeignKeyCriteriaClient 
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 131

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT TempId FROM @TEXT
	UNION
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 131
)
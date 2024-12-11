USE [clovis];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15936';
DECLARE @Comments nvarchar(Max) = 
	'Update bad queries for assist';
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
UPDATE MetaForeignKeyCriteriaClient 
SET CustomSql = 'select 0 as Value, convert(char(10), CourseDate, 126) as Text from CourseDate cd		
INNER JOIN CourseDateType cdt ON cd.CourseDateTypeId = cdt.Id 
where cdt.Title = ''Board of Trustees Approval''
and cd.CourseId = @entityId 
and cdt.ClientId = @clientId'
, ResolutionSql = 'select 0 as Value, convert(char(10), CourseDate, 126) as Text from CourseDate cd		
INNER JOIN CourseDateType cdt ON cd.CourseDateTypeId = cdt.Id 
where cdt.Title = ''Board of Trustees Approval''
and cd.CourseId = @entityId 
and cdt.ClientId = @clientId'
WHERE Id = 934

UPDATE MetaForeignKeyCriteriaClient 
SET CustomSql = ';with ContactHours as (	
    select MinLectureHour as LectureHours	
    from CourseDescription	
    where CourseId = @entityId	
    union all	
    select MaxLectureHour as LectureHours	
    from CourseDescription	where CourseId = @entityId)
    
select 0 as Value, max(coalesce(LectureHours, 0)) * 18 as Text from ContactHours'
, ResolutionSql = ';with ContactHours as (	
    select MinLectureHour as LectureHours	
    from CourseDescription	
    where CourseId = @entityId	
    union all	
    select MaxLectureHour as LectureHours	
    from CourseDescription	where CourseId = @entityId)
    
select 0 as Value, max(coalesce(LectureHours, 0)) * 18 as Text from ContactHours'
WHERE Id = 930

UPDATE MetaForeignKeyCriteriaClient 
SET CustomSql = ';with ContactHours as (
		select MinLabHour as LabHours	
		from CourseDescription
		where CourseId = @entityId	
		union all
		select MaxLabHour as LabHours	
		from CourseDescription	where CourseId = @entityId)
		
select 0 as Value, max(coalesce(LabHours, 0)) * 18 as Text from ContactHours'
, ResolutionSql = ';with ContactHours as (
		select MinLabHour as LabHours	
		from CourseDescription
		where CourseId = @entityId	
		union all
		select MaxLabHour as LabHours	
		from CourseDescription	where CourseId = @entityId)
		
select 0 as Value, max(coalesce(LabHours, 0)) * 18 as Text from ContactHours'
WHERE Id = 931

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId in (
		930, 931, 934
	)
)
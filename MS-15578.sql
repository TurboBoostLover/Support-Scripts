USE [peralta];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15578';
DECLARE @Comments nvarchar(Max) = 
	'Show selected values';
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
UPDATE MetaForeignKeyCriteriaClient 
SET CustomSql = '
Declare @CourseClientId int = (Select ClientId from Course where id = @EntityId);
				declare @now datetime = getdate();

				if exists
				(
					select top 1 1 
					from [user] u 
					inner join userRole ur on u.Id = ur.UserId 
					where ur.roleId = 1 and u.Id = @userId
				)
				begin
					--When contenating strings in T-SQL, by default it will make the entire string null if one of the elements is null
					--This was causing the Text to be null if either the subject code or subject title was null
					With AdminSubjects as(
					select  s.SubjectCode as Text, s.Id as Value
					from [Subject] as s
					where
						EXISTS (SELECT 1 FROM [UserRole] ur WHERE ur.UserId = @userId AND ur.ClientId = s.ClientId AND ur.RoleId = 1)
						and @now between s.StartDate and isnull(s.EndDate, @now)
						and s.ClientId = @CourseClientId
					Union 	
					select  s.Title + '' (Wrong College)'' as Text, s.Id as Value
					from [Subject] as s inner join Course c on c.SubjectId = s.Id and c.Id = @EntityId and c.ClientId <> s.ClientId)
					Select Value, Text From AdminSubjects 
					order by Text
				end
				else
				begin
					--When contenating strings in T-SQL, by default it will make the entire string null if one of the elements is null
					--This was causing the Text to be null if either the subject code or subject title was null
					With UOriginationSubjects as(
					select  s.SubjectCode as Text, s.Id as Value
					from [Subject] as s
						INNER join [UserOriginationSubjectPermission] as per on s.Id = per.subjectId  
		
					where per.userId = @userId  
						and @now between s.StartDate and isnull(s.EndDate, @now)
						and per.Active = 1
						and s.ClientId = @CourseClientId
					Union 	
					select  s.Title + '' (Wrong College)'' as Text, s.Id as Value
					from [Subject] as s inner join Course c on c.SubjectId = s.Id and c.Id = @EntityId and c.ClientId <> s.ClientId
					UNION
					select  s.SubjectCode as Text, s.Id as Value
					from [Subject] as s
					WHERE s.Id in (
						SELECT SubjectId FROM Course WHERE Id = @EntityId
					)
					)

					Select Value, Text From UOriginationSubjects 
					order by Text 
				end
'
WHERE Id in (
144
)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mt.MetaTemplateId FROM MetaTemplate AS mt
	INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 144
)
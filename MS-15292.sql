USE [victorvalley];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15292';
DECLARE @Comments nvarchar(Max) = 
	'Update Custom SQl';
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
declare @courseType int = (
	SELECT
		cb.Id
	FROM CourseCbCode ccb
		INNER JOIN CB04 cb ON cb.id = ccb.CB04Id
	WHERE ccb.CourseId = @entityId
),
@success bit = 0;

if (@courseType <> 3)  
begin
	set @success = (
		SELECT
			case
				when COALESCE(MinLectureHour, 0) <> 0 then 1
				when COALESCE(MaxLectureHour, 0) <> 0 then 1
				when COALESCE(MinContHour, 0) <> 0 then 1
				when COALESCE(MaxContHour, 0) <> 0 then 1
				when COALESCE(MinLabHour, 0) <> 0 then 1
				when COALESCE(MaxLabHour, 0) <> 0 then 1
				else 0
			end
		from CourseDescription
		where CourseId = @entityId
	)
END
ELSE
BEGIN
	set @success = (
		select 
			case
				when coalesce(MinContactHoursLecture,0) <> 0 then 1
				when coalesce(MinContactHoursLab,0) <> 0 then 1
				when coalesce(MinContactHoursOther,0) <> 0 then 1
				when COALESCE(MaxLabHour,0) <> 0 then 1
				else 0
			end
		from CourseDescription
		where CourseId = @entityId
	)
END

if (@success = 1)
begin
	SELECT
		Id AS Value
		,Title AS Text
	FROM YesNo
	WHERE Title = ''Yes''
end
'
WHERE Id = 118
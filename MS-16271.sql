USE [laspositas];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16271';
DECLARE @Comments nvarchar(Max) = 
	'Update Course Textbook validation';
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
UPDATE MetaSqlStatement
SET SqlStatement = 'declare @entryCount int = (
    select count(*)
    from CoursePeriodical
    where CourseId = @entityId
		and Author is not null
		and Title is not null
		and Publisher is not null
		and CalendarYear is not null
);

declare @entryCount2 int = (
    select count(*)
    from CourseTextbook 
    where CourseId = @entityId
		and Author is not null
		and Title is not null
		and Publisher is not null
		and CalendarYear is not null
);

declare @entryCount3 int = (
    select count(*)
    from CourseManual
    where CourseId = @entityId
		and Author is not null
		and Title is not null
		and Publisher is not null
);

declare @entryCount4 int = (
    select count(*)
    from CourseSoftware
    where CourseId = @entityId
		and Title is not null
);

declare @entryCount5 int = (
    select count(*)
    from CourseTextOther
    where CourseId = @entityId
);
    
 
select cast(
case
	when @entryCount > 0 or @entryCount2 > 0 or @entryCount3 > 0 or @entryCount4 > 0 or @entryCount5 > 0 
	then 1 
	else 0 end as bit) as IsValidCount;'
WHERE Id = 14

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaControlAttribute AS mca on mca.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE mca.MetaSqlStatementId = 14
)
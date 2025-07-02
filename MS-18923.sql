USE [socccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18923';
DECLARE @Comments nvarchar(Max) = 
	'Fix Course Number/Subject Validation';
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
SET SqlStatement = '
SELECT 
	Case
		WHEN c.StatusAliasId =1 THEN 1
		when exists (
			select top 1 1
			from dbo.Course c2
				inner join ProposalType pt2 on c2.ProposalTypeId = pt2.Id
			where c2.ClientId = c.ClientId
				and c2.SubjectId = c.SubjectId
				and LTRIM(RTRIM(c2.CourseNumber)) = LTRIM(RTrim(c.CourseNumber))
				and pt2.ClientEntityTypeId = pt.ClientEntityTypeId
				and c2.BaseCourseId <> c.BaseCourseId
				and c2.Active = 1
				and c.CourseSuffixId = c2.CourseSuffixId
		) 
		then 0	
		else 1
	END As ISValid
FROM Course c
	inner join ProposalType pt on c.ProposalTypeId = pt.Id
WHERE c.Id = @entityId
'
WHERE Id = 12

UPDATE MetaControlAttribute
SET MetaSqlStatementId = 12
WHERE MetaSqlStatementId in (13, 14)

DELETE FROM MetaSqlStatement
WHERE Id in (13, 14)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaControlAttribute AS mca on mca.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE mca.MetaSqlStatementId = 12
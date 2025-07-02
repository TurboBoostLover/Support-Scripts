USE [nukz];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19299';
DECLARE @Comments nvarchar(Max) = 
	'Update Validation on Faculty Resources tab';
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
UPDATE MetaSqlStatement
SET SqlStatement = '
DECLARE @count int = (
	SELECT Count(Id) FROM ProgramPersonnel
	WHERE ProgramId = @EntityId
)

DECLARE @Valid int = (
	SELECT Count(Id) FROM ProgramPersonnel
	WHERE ProgramId = @EntityId
	and LastName IS NOT NULL
	and FirstName IS NOT NULL
	and PersonnelTitleId IS NOT NULL
	and Degree IS NOT NULL
	and YearObtained IS NOT NULL
	and University IS NOT NULL
	and AreaOfExpertise IS NOT NULL
	and SupervisionExperience IS NOT NULL
	and RecentPublications IS NOT NULL
	and PersonnelTitleId <> 11
)

DECLARE @other int = (
	SELECT Count(Id) FROM ProgramPersonnel
	WHERE ProgramId = @EntityId
	and LastName IS NOT NULL
	and FirstName IS NOT NULL
	and PersonnelTitleId IS NOT NULL
	and Degree IS NOT NULL
	and YearObtained IS NOT NULL
	and University IS NOT NULL
	and AreaOfExpertise IS NOT NULL
	and SupervisionExperience IS NOT NULL
	and RecentPublications IS NOT NULL
	and PersonnelTitleId = 11
	and MaxText01 IS NOT NULL
)

SELECT CASE
WHEN sUM(ISNULL(@Valid, 0) + ISNULL(@other, 0)) = @count and @count >=1 THEN 1 ELSE 0 END AS IsValid
'
WHERE Id = 20

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaControlAttribute AS mca on mca.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE mca.MetaSqlStatementId = 20
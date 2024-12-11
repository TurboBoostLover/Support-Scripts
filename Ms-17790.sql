USE [hkapa];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17790';
DECLARE @Comments nvarchar(Max) = 
	'Fix Validation SQL';
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
DECLARE @Uni int = (
select case when count(pga.GraduateAttributeId) = 0 then 1 else 0 end
from ProgramGraduateAttribute pga
    inner join GraduateAttribute ga on ga.Id = pga.GraduateAttributeId
where ProgramId = @entityId
GROUP by pga.GraduateAttributeId
having count(pga.GraduateAttributeId) > 1
)

declare @gaItemType int = (select Id 
						   from ListItemType
						   where Active = 1
								and ListItemTableName = ''ProgramGraduateAttribute''
								and ListItemTitleColumn = ''GraduateAttributeId'')
	
declare @otherItemType int = (select Id 
							  from ListItemType
							  where Active = 1
								and ListItemTableName = ''ProgramGraduateAttribute''
								and ListItemTitleColumn = ''Rationale'') 

DECLARE @Count int = (SELECT COUNT(Id) FROM ProgramGraduateAttribute WHERE ProgramId = @EntityId and ListItemTypeId = @gaItemType)
DECLARE @Other int = (SELECT COUNT(Id) FROM ProgramGraduateAttribute WHERE ProgramId = @EntityId and ListItemTypeId = @otherItemType)
DECLARE @OtherValid int = (SELECT COUNT(Id) FROM ProgramGraduateAttribute WHERE ProgramId = @EntityId and ListItemTypeId = @otherItemType and Rationale IS NOT NULL)
DECLARE @Valid int = (SELECT COUNT(pga.Id) FROM ProgramGraduateAttribute AS pga where ID IN (SELECT ProgramGraduateAttributeId FROM ProgramGraduateAttributeProgramOutcome) AND ProgramId = @EntityId and pga.ListItemTypeId = @gaItemType)

SELECT CASE
	WHEN @Uni IS NULL and @Count = @Valid and @Other = @OtherValid and @Count >= 1
	THEN 1
	ELSE 0
	END AS IsValid
'
WHERE Id = 4

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaControlAttribute AS mca on mca.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE mca.MetaSqlStatementId = 4
)
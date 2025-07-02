USE [chabot];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18826';
DECLARE @Comments nvarchar(Max) = 
	'Fix Organization Data for the SAO Assesment';
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
UPDATE OrganizationEntity
SET Title = 'Research, Planning, and Institutional Effectiveness'
WHERE Id = 116

UPDATE OrganizationLink 
SET Parent_OrganizationEntityId = 193
WHERE Id = 71

DECLARE @OE INTEGERS

INSERT INTO OrganizationEntity
(OrganizationTierId, Title, ClientId, Code, StartDate)
output inserted.Id INTO @OE
VALUES
(3, 'Building Services', 1, 'SAO', GETDATE()),
(3, 'Print Media and Communication', 1, 'SAO', GETDATE())

INSERT INTO OrganizationLink
(StartDate, ClientId, Child_OrganizationEntityId, Parent_OrganizationEntityId)
SELECT GETDATE(), 1, Id , 142 FROM @OE

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
select oe.Id as [Value], oe.Title as [Text] 
from OrganizationEntity oe inner join OrganizationTier ot on oe.OrganizationTierId = ot.Id 
where ot.SortOrder = 1 
and oe.Code = ''SAO''
ORDER BY oe.Title
'
WHERE Id = 54

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '

SELECT oe.Id As [Value],
oe.Title As [Text],
ol2.Parent_OrganizationEntityId FilterValue
FROM OrganizationEntity oe
INNER JOIN OrganizationLink ol ON ol.Child_OrganizationEntityId = oe.Id
INNER JOIN OrganizationEntity AS oe2 on oe2.Id = ol.Parent_OrganizationEntityId
INNER JOIN OrganizationLink AS ol2 on ol2.Child_OrganizationEntityId = oe2.Id
ORDER BY oe.title
'
WHERE Id = 56

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT MetaTemplateId FROM MetaTemplate AS mt
	INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
	WHERE mtt.EntityTypeId = 6
)
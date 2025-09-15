USE [zu];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18942';
DECLARE @Comments nvarchar(Max) = 
	'Delete Duplicate Fields';
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
WITH DuplicateFields AS (
    SELECT 
        MetaSelectedSectionId,
        MetaAvailableFieldId
    FROM MetaSelectedField
    GROUP BY MetaSelectedSectionId, MetaAvailableFieldId
    HAVING COUNT(*) > 1
),
FieldsWithRowNum AS (
    SELECT 
        msf.MetaSelectedFieldId,
        msf.MetaSelectedSectionId,
        msf.MetaAvailableFieldId,
        ROW_NUMBER() OVER (
            PARTITION BY msf.MetaSelectedSectionId, msf.MetaAvailableFieldId 
            ORDER BY msf.MetaSelectedFieldId
        ) AS rn
    FROM MetaSelectedField msf
    JOIN DuplicateFields df
        ON msf.MetaSelectedSectionId = df.MetaSelectedSectionId
       AND msf.MetaAvailableFieldId = df.MetaAvailableFieldId
)
DELETE FROM MetaSelectedField
WHERE MetaSelectedFieldId IN (
    SELECT MetaSelectedFieldId
    FROM FieldsWithRowNum
    WHERE rn > 1
);


DECLARE @SQL NVARCHAR(MAX) = '
select concat(oe.Code, '' - '', oe.Title) as Text, oe.Id as Value
from course c 
inner join Subject s on c.SubjectId = s.Id
inner join OrganizationSubject os on s.id = os.SubjectId
inner join OrganizationEntity oe2 on os.OrganizationEntityId = oe2.Id
inner join OrganizationLink ol on ol.Child_OrganizationEntityId = oe2.Id
inner join OrganizationEntity oe on oe.Id = ol.Parent_OrganizationEntityId
where os.Active = 1
and ol.Active = 1
and oe.Active = 1
and s.Active = 1
and oe2.Active = 1
and c.Id = @entityId
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id in (
5, 7
)

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId in (
5, 6, 7, 8
)
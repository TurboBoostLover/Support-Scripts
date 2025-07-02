USE [chaffey];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19071';
DECLARE @Comments nvarchar(Max) = 
	'Fix Custom Validation';
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
INSERT INTO MetaSqlStatement
(SqlStatement, SqlStatementTypeId)
VALUES
('DECLARE @Count INT = (
SELECT COUNT(Id)
FROM GenericOrderedList01
WHERE ModuleId = @entityId
);

DECLARE @Valid INT = (
SELECT	Count(Id)
FROM GenericOrderedList01
WHERE ModuleId = @entityId
and ItemTypeId IS NOT NULL
AND ((ItemTypeId = 177 and MaxText03 IS NOT NULL) or ItemTypeId <> 177) --other
AND Id in (SELECT GenericOrderedList01Id FROM GenericOrderedList01Lookup01 WHERE Explain IS NOT NULL)
AND Int02 IS NOT NULL
AND MaxText02 IS NOT NULL
AND YesNo01Id IS NOT NULL
AND Lookup14Id IS NOT NULL
AND Int01 IS NOT NULL
AND Id in (SELECT GenericOrderedList01Id FROM GenericOrderedList01Lookup05)
AND ((Bit_01 = 1 AND MaxText01 IS NOT NULL) or Bit_01 <> 1)
AND (Bit_02 = 1 or Bit_03 = 1 or Bit_04 = 1 or Bit_01 = 1)
);

SELECT CASE 
		WHEN @count = @Valid
		THEN 1
		ELSE 0
		END;', 1)

DECLARE @Id int = SCOPE_IDENTITY()

UPDATE MetaControlAttribute
SET MetaSqlStatementId = @Id
WHERE MetaSelectedSectionId in (
	SELECT mss.MEtaSelectedSectionId FROM MetaSelectedSection AS mss
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	WHERE mss.MetaBaseSchemaId = 2491
	and mt.MetaTemplateTypeId in (41)
	and mt.EndDate IS NULL
	and mss.MetaSectionTypeId = 31
)

INSERT INTO MetaSqlStatement
(SqlStatement, SqlStatementTypeId)
VALUES
('DECLARE @Count INT = (
SELECT COUNT(Id)
FROM GenericOrderedList02
WHERE ModuleId = @entityId
);

DECLARE @Valid INT = (
SELECT	Count(Id)
FROM GenericOrderedList02
WHERE ModuleId = @entityId
and Decimal01 IS NOT NULL
AND Id in (SELECT GenericOrderedList02Id FROM GenericOrderedList02Lookup01 WHERE Explain IS NOT NULL)
AND Id in (SELECT GenericOrderedList02Id FROM GenericOrderedList02Lookup05)
AND MaxText01 Is NOT NULL
AND MaxText02 Is NOT NULL
);

SELECT CASE 
		WHEN @count = @Valid
		THEN 1
		ELSE 0
		END;', 1)

SET @Id = SCOPE_IDENTITY()

UPDATE MetaControlAttribute
SET MetaSqlStatementId = @Id
WHERE MetaSelectedSectionId in (
	SELECT mss.MEtaSelectedSectionId FROM MetaSelectedSection AS mss
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	WHERE mss.MetaBaseSchemaId = 2512
	and mt.MetaTemplateTypeId in (42)
	and mt.EndDate IS NULL
	and mss.MetaSectionTypeId = 31
)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	WHERE mss.MetaBaseSchemaId = 2491
	and mt.MetaTemplateTypeId in (41)
	and mt.EndDate IS NULL
	and mss.MetaSectionTypeId = 31
	UNION
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	WHERE mss.MetaBaseSchemaId = 2512
	and mt.MetaTemplateTypeId in (42)
	and mt.EndDate IS NULL
	and mss.MetaSectionTypeId = 31
)
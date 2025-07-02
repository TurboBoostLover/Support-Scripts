USE [peralta];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18852';
DECLARE @Comments nvarchar(Max) = 
	'Uniform all course forms to one form and one COR for Units and Hours';
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
UPDATE MetaTemplateType
SET ClientId = 1
, TemplateName =
	CASE 
		WHEN MetaTemplateTypeId = 67 THEN 'New Fee-Based Course'
		WHEN MetaTemplateTypeId = 68 THEN 'New Course'
		WHEN MetaTemplateTypeId = 69 THEN 'Modify Course'
		WHEN MetaTemplateTypeId = 70 THEN 'Deactivate Course'
WHERE MetaTemplateTypeId in (
67, 68, 69, 70
)


UPDATE MetaTemplate
SET ClientId = 1
WHERE MetaTemplateTypeId in (
67, 68, 69, 70
)

UPDATE MetaTemplateType
SET Active = 0
WHERE MetaTemplateTypeId in (
	1, 3, 4, 7, 48, 49, 50, 51
)

UPDATE ProposalType
SET MetaTemplateTypeId =
	CASE
		WHEN MetaTemplateTypeId IN (1, 48) THEN 68
		WHEN MetaTemplateTypeId IN (3, 49) THEN 69
		WHEN MetaTemplateTypeId IN (4, 50) THEN 70
		WHEN MetaTemplateTypeId IN (7, 51) THEN 67
		ELSE MetaTemplateTypeId
	END
WHERE MetaTemplateTypeId IN (
	1, 3, 4, 7, 48, 49, 50, 51
)

UPDATE MetaTemplateType 
SET Active = 0
WHERE MetaTemplateTypeId in (
100, 99, 98
)

UPDATE MetaTemplateType
SET ClientId = 1
, TemplateName = 'District Course Outline'
WHERE MetaTemplateTypeId = 52

UPDATE MetaReportTemplateType
SET MetaTemplateTypeId = 
	CASE
		WHEN MetaTemplateTypeId IN (1, 48) THEN 68
		WHEN MetaTemplateTypeId IN (3, 49) THEN 69
		WHEN MetaTemplateTypeId IN (4, 50) THEN 70
		WHEN MetaTemplateTypeId IN (7, 51) THEN 67
		ELSE MetaTemplateTypeId
	END
WHERE MetaTemplateTypeId in (
	1, 3, 4, 7, 48, 49, 50, 51
)

DECLARE @Table TABLE (OldId int, NewId int)
INSERT INTO @Table
VALUES
(1, 139),
(48, 139),
(3, 140),
(49, 140),
(4, 141),
(50, 141),
(7, 10),
(51, 10)

UPDATE c
SET MetaTemplateId = t.NewId
FROM Course AS c
INNER JOIN MetaTemplate AS mt on c.MetaTemplateId = mt.MetaTemplateId
INNER JOIN @TABLE t on t.OldId = mt.MetaTemplateId

SELECT * FROM MetaTemplateType WHERE Active = 1 and EntityTypeId = 1 and IsPresentationView = 0
SELECT * FROM MetaTemplate WHERE MetaTemplateId = 51
--153 Template for COR
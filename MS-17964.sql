USE [laspositas];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17964';
DECLARE @Comments nvarchar(Max) = 
	'Update Static Text';
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
DECLARE @Field Table (FieldId int, TemplateId int)
INSERT INTO @Field
SELECT msf.MetaSelectedFieldId, mss.MetaTemplateId FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE mtt.Active = 1
and mt.Active = 1
and mt.EndDate IS NULL
and mt.IsDraft = 0
and msf.MetaAvailableFieldId IS NULL
and msf.DisplayName like '%Completion Requirements%'

UPDATE MetaSelectedField
SET DisplayName = 'Completion Requirements: 1. Completion of 60 semester units or 90 quarter units that are eligible for transfer to the California State University, including both of the following: a. The California General Education Transfer Curriculum (Cal-GETC). b. A minimum of 18 semester units in a major or area of emphasis, as determined by the community college district. 2. Obtainment of a minimum grade point average of 2.0. Associate Degrees for Transfer (ADT''s) also require that students must earn a "C" (or "P") or better in all courses required for the major or area of emphasis.'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Field
)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT DISTINCT TemplateId FROM @Field
)
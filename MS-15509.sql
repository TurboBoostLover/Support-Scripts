USE [clovis];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15509';
DECLARE @Comments nvarchar(Max) = 
	'Update Min and max labels on OL so they can input data';
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
DECLARE @IdMax INTEGERS
INSERT INTO @IdMax
SELECT Id FROM MetaSelectedSectionAttribute 
WHERE Name  = 'CalcMaxLabel'
and Value = 'Max Hours'

DECLARE @IdMin INTEGERS
INSERT INTO @IdMin
SELECT Id FROM MetaSelectedSectionAttribute 
WHERE Name = 'CalcMinLabel' 
and Value = 'Min Hours'

UPDATE MetaSelectedSectionAttribute
SET Value = 'Min Contact Hours'
WHERE Id in (
	SELECT Id FROM @IdMin
)

UPDATE MetaSelectedSectionAttribute
SET Value = 'Max Contact Hours'
WHERE Id in (
	SELECT Id FROM @IdMax
)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT DISTINCT mt.MEtaTemplateId FROM MetaTemplate AS mt
	INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaSelectedSectionAttribute AS mssa on mssa.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE mssa.Id in (
		SELECT Id FROM @IdMin
		UNION
		SELECT Id FROM @IdMax
	)
)
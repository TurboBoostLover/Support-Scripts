USE [peralta];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13928';
DECLARE @Comments nvarchar(Max) = 
	'Update Lan Assessment 1';
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
INSERT INTO ClientLearningOutcome
(ClientId, Description, SortOrder, StartDate, ParentId)
VALUES
(4,'Career Technical Education',1,GETDATE(),55)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mt.MetaTemplateId
	FROM MetaTemplateType mtt
		INNER JOIN MetaTemplate mt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
	WHERE mt.Active = 1 
		AND mtt.EntityTypeId = 6
		AND mt.IsDraft = 0
		AND mt.EndDate IS NULL
		AND mtt.Active = 1
		AND mtt.IsPresentationView = 0
		AND mtt.ClientId = 4
		AND mtt.MetaTemplateTypeId = 54
)

INSERT INTO Lookup01
(Lookup01ParentId, ClientId, ShortText, SortOrder, StartDate)
VALUES
(NULL, 4, 'Career Technical Education', NULL, GETDATE())

DECLARE @Parent int = SCOPE_IDENTITY()

INSERT INTO Lookup01
(Lookup01ParentId, ClientId, ShortText, SortOrder, StartDate)
VALUES
(@Parent, 4, 'Knowledge Attainment', 1, GETDATE()),
(@Parent, 4, 'Technical Skills', 2, GETDATE()),
(@Parent, 4, 'Problem Solving', 3, GETDATE()),
(@Parent, 4, 'Career Awareness', 4, GETDATE()),
(@Parent, 4, 'Occupational Safety', 5, GETDATE()),
(@Parent, 4, 'Communication/Literacy', 6, GETDATE())
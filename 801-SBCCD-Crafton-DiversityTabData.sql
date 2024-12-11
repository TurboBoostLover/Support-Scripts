USE [sbccd];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14394';
DECLARE @Comments nvarchar(Max) = 
	'Data for lookup 14';
DECLARE @Developer nvarchar(50) = 'Nathan Westergard';
DECLARE @ScriptTypeId int = 2; /*  Default 1 is Support,  
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
INSERT INTO Lookup14
(Parent_Lookup14Id, Title, SortOrder, ClientId, StartDate)
VALUES
(NULL, '(DEIA) principles/strategies', 1, 2, GETDATE())

DECLARE @PARENTID int = SCOPE_IDENTITY()

INSERT INTO Lookup14
(Parent_Lookup14Id, Title, SortOrder, ClientId, StartDate)
VALUES
(@PARENTID, 'Catalog Description', 1, 2, GETDATE()),
(@PARENTID, 'Class Assignments', 2, 2, GETDATE()),
(@PARENTID, 'Content', 3, 2, GETDATE()),
(@PARENTID, 'Course Learning Outcomes', 4, 2, GETDATE()),
(@PARENTID, 'Credit for Prior Learning', 5, 2, GETDATE()),
(@PARENTID, 'Distance Education (course can be offered in different modalities)', 6, 2, GETDATE()),
(@PARENTID, 'Methods of Evaluation (Formative and summative assessments were selected)', 7, 2, GETDATE()),
(@PARENTID, 'Methods of Instruction (Equity-minded instruction, active-learning, and personalized learning strategies were selected)', 8, 2, GETDATE()),
(@PARENTID, 'Objectives', 9, 2, GETDATE()),
(@PARENTID, 'Resources (Zero cost textbooks and/or strategies to lower the costs of resources)', 10, 2, GETDATE())

COMMIT
USE [peralta];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13802';
DECLARE @Comments nvarchar(Max) = 
	'Restore data and delete bad data';
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

DELETE FROM ModuleRelatedModule02Lookup05 WHERE ModuleRelatedModule02Id = 33
DELETE FROM ModuleRelatedModule02 WHERE Id = 33

UPDATE ModuleRelatedModule02
SET MaxText01 = 'Students were graded on their ability to draw a believable three-dimensional space applying the use of one-point linear perspective. Students established a horizon line and vanishing point, and established multiple orthogonal lines using a ruler. All elements of the drawing should relate to the perspectival laws. Consideration was given to composition (how the elements in the drawing relate to each other as well as the edges of the paper), direction (implied spatial dimension), and relationships between positive and negative spaces (how figures, objects, furniture and/or other objects appear to be situated in believable 3D space.'
, MaxText04	 = 'The majority of the students did well with this assignment, creating a believable, three-dimensional environment. Several students (8%) struggled to adequately apply the rules of linear perspective, but did well upon a second attempt.'
, Lookup08Id_01 = 6
, Lookup09Id_01 = 13
, ModifiedDate = GETDATE()
, ModifiedBy_UserId = 1012
, MaxText06 = 'Many of the students used this assignment as an opportunity to be creative about creating an interesting environment (for example, creating complex interior rooms, or unusual places like the interior of a submarine or spaceship). The majority of the class did a good job applying the laws of linear perspective to create a believable sense of depth and dimension.'
, MaxText07 = 'Some students struggle to use the orthogonal lines appropriately.'
WHERE Id = 42

INSERT INTO ModuleRelatedModule02Lookup05
(ModuleRelatedModule02Id, Lookup05Id, MaxText01, ModifiedDate, ModifiedBy_UserId)
VALUES
(42, 15, NULL, GETDATE(), 355),
(42, 24, 'Regular check-ins with students while they work on their assignments to make sure they understand the expectations, and to answer any questions.', GETDATE(), 355),
(42, 35, 'Regular check-ins with faculty in my department', GETDATE(), 355)
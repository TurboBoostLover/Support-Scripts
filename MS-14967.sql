USE [ccsf];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14967';
DECLARE @Comments nvarchar(Max) = 
	'Add GE Outcomes to map to SLOs';
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
INSERT INTO GeneralEducationElementOutcome
(GeneralEducationElementId, Outcome, StartDate, ClientId, SortOrder)
VALUES
(1602, '1. Analyze and articulate concepts of race, racism, ethnicity, and eurocentrism in the U.S. through the lens of decolonization, anti-racism, and equity as related to Native American, African American, Asian American, and/or Latina and Latino American Studies. ', GETDATE(), 57, 1),
(1602, '2. Apply theory and knowledge produced by Native American, African American, Asian American, and/or Latina and Latino American communities to critically describe group affirmation through histories of social struggles and societal contributions.', GETDATE(), 57, 2),
(1602, '3. Analyze critically the intersections of race, racism, and social identities created and experienced by Native American, African American, Asian American, and/or Latina and Latino American communities.', GETDATE(), 57, 3),
(1602, '4. Review critically how struggle, resistance, racial and social justice, solidarity, and liberation experienced and enacted by Native Americans, African Americans, Asian Americans, and/or Latina and Latino Americans shape social policy and community and national politics.', GETDATE(), 57, 4),
(1602, '5. Describe and actively engage with anti-racist and anti-colonial issues and the practices and movements in Native American, African American, Asian American and/or Latina and Latino communities to build a just and equitable society.', GETDATE(), 57, 5),
(1600, '1. Analyze and articulate concepts of race, racism, ethnicity, and eurocentrism in the U.S. through the lens of decolonization, anti-racism, and equity as related to Native American, African American, Asian American, and/or Latina and Latino American Studies. ', GETDATE(), 57, 1),
(1600, '2. Apply theory and knowledge produced by Native American, African American, Asian American, and/or Latina and Latino American communities to critically describe group affirmation through histories of social struggles and societal contributions.', GETDATE(), 57, 2),
(1600, '3. Analyze critically the intersections of race, racism, and social identities created and experienced by Native American, African American, Asian American, and/or Latina and Latino American communities.', GETDATE(), 57, 3),
(1600, '4. Review critically how struggle, resistance, racial and social justice, solidarity, and liberation experienced and enacted by Native Americans, African Americans, Asian Americans, and/or Latina and Latino Americans shape social policy and community and national politics.', GETDATE(), 57, 4),
(1600, '5. Describe and actively engage with anti-racist and anti-colonial issues and the practices and movements in Native American, African American, Asian American and/or Latina and Latino communities to build a just and equitable society.', GETDATE(), 57, 5)

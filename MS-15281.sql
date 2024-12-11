USE [fresno];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15281';
DECLARE @Comments nvarchar(Max) = 
	'Update Admin Report';
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
UPDATE AdminReport
SET ReportSQL = '
SELECT oe.Title AS "Department",
p.Title AS "Program Name",
at.Title AS "Program Type",
co.CalcMin AS "Min Credits",
co.CalcMax AS "Max Credits",
	CASE WHEN s.Title IS NULL
	THEN NULL
	ELSE
CONCAT(''('',s.SubjectCode,'') '',s.Title)
END AS "Subject"
FROM Program p
	INNER JOIN AwardType at ON p.AwardTypeId = at.Id
	INNER JOIN CourseOption co ON co.ProgramId = p.Id
	INNER JOIN OrganizationEntity oe ON p.Tier2_OrganizationEntityId = oe.Id
	LEFT JOIN Subject AS s on s.Id = p.SubjectId
	WHERE p.Active = 1
'
WHERE Id = 1
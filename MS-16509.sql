USE [evc];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16509';
DECLARE @Comments nvarchar(Max) = 
	'UPDATE ILOS';
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
UPDATE ClientLearningOutcome
SET Description = '<b>Communication:</b> The student will demonstrate the use of effective communication that is inclusive and appropriate for the audience and the purpose of the task.'
WHERE Id = 171

UPDATE ClientLearningOutcome
SET Description = '<b>Inquiry and Reasoning:</b> The student will critically evaluate information to interpret ideas and solve problems while considering equitable and inclusive best practices.'
WHERE Id = 172

UPDATE ClientLearningOutcome
SET Description = '<b>Information Competency:</b> The student will define and support an information need with credible sources while also recognizing that privilege and biases exist within the creation of information.'
WHERE Id = 173

UPDATE ClientLearningOutcome
SET Description = '<b>Social Responsibility:</b> Students will incorporate ethical, social, and environmental implications in their choices to foster diversity, equity, and inclusion in their community.'
WHERE Id = 174

UPDATE ClientLearningOutcome
SET Description = '<b>Personal Development:</b> The student will demonstrate growth and self-management to promote life-long learning and personal well-being.'
WHERE Id = 175
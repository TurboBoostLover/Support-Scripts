USE [peralta];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14618';
DECLARE @Comments nvarchar(Max) = 
	'Update HyperLink';
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
UPDATE MetaSelectedFieldAttribute 
SET Value = 'https://laney.edu/institutionaleffectiveness/program-review/#data'
WHERE Value = 'https://app.powerbi.com/view?r=eyJrIjoiZjU2M2M5MzItOTcwZi00Y2U1LWJmODUtYTc0YjlhZGI2ZDhjIiwidCI6ImVlYTE2YTE2LTQ4YWYtNDc3Yi05MTEzLTA1YjFjMDExMjNmZiIsImMiOjZ9&pageName=ReportSectionde32556e136b0a8caccd'

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mt.MetaTemplateId FROM MetaTemplate AS mt
	INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaSelectedSection AS mss2 on mss2.MetaSelectedSection_MetaSelectedSectionId = mss.MetaSelectedSectionId
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss2.MetaSelectedSectionId
	INNER JOIN MetaSelectedFieldAttribute AS msfa on msfa.MetaSelectedFieldId = msf.MetaSelectedFieldId
	WHERE Value = 'https://laney.edu/institutionaleffectiveness/program-review/#data'
)
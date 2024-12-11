USE [nu];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15952';
DECLARE @Comments nvarchar(Max) = 
	'Update Text';
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
DECLARE @SQL NVARCHAR(MAX) = '
		select CASE 
			WHEN pt.ProcessActionTypeId = 1
			THEN ''''
			ELSE
			''The following changes are classified as minor changes:
			<ul>
				<li>Modifications to the program description are considered minor when they reflect language adjustments that do not reflect a change in program learning outcomes.</li>
				<li>Changes to course prerequisites.</li>
				<li>Changes to course descriptions.</li>
				<li>Adjustments to course titles, course numbers, or course prefixes.</li>
				<li>Modifications to the number of units that amount to less than 25% change in the total number of units awarded.</li>
				<li>Modifications to less than 25% of the course learning outcomes (CLO); and</li>
				<li>Changes between letter grading (H/S/U) and other grading systems.</li>
			</ul>'' 
			END as [Text]
			FROM Program AS p
			INNER JOIN ProposalType AS pt on p.ProposalTypeId = pt.Id
			WHERE p.Id = @EntityId
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
, LookupLoadTimingType = 2
WHERE Id = 38

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 38
)
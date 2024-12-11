USE [clovis];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16458';
DECLARE @Comments nvarchar(Max) = 
	'Update PRogram Narrative Report';
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
SELECT 0 AS Value,
CONCAT(
''<b>Effective Term</b>: '', s.Title, ''<br />'',
''<b>Effective Date</b>: '', FORMAT(s.TermStartDate, ''MM/dd/yyy''), ''<br />'',
''<b>Curriculum Committee Approval</b>: '', FORMAT(pd.ProgramDate, ''MM/dd/yyy''), ''<br />'',
''<b>Board of Trustee Approval</b>: '', FORMAT(pd2.ProgramDate, ''MM/dd/yyy''), ''<br />'',
''<b>Program Control Number</b>: '', p.UniqueCode2, ''<br />'',
''<b>Top Code</b>: '', CONCAT(
        SUBSTRING(cb03.Code, 1, LEN(cb03.Code) - 2), 
        ''.'', 
        SUBSTRING(cb03.Code, LEN(cb03.Code) - 1, 2), 
        '' - '', 
        cb03.Description
    ), ''<br />'',
''<b>Cip Code</b>: '', cc.Code, '' - '', cc.Title, ''<br />''
) AS Text
FROM Program AS p
INNER JOIN ProgramProposal AS pp on pp.ProgramId = P.Id
left join ProgramCBCode AS pcb on pcb.ProgramId = p.Id
LEFT JOIN Cb03 AS cb03 on pcb.CB03Id = cb03.ID
LEFT JOIN ProgramSeededLookup AS psl on psl.ProgramId = p.Id
LEFT JOIN CipCode_Seeded AS cc on psl.CipCode_SeededId = cc.ID
LEFT JOIN Semester AS s on pp.SemesterId = s.Id
LEFT JOIN ProgramDate AS pd on pd.ProgramId = p.Id and pd.ProgramDateTypeId = 1
LEFt JOIN ProgramDate AS pd2 on pd2.ProgramId = p.Id and pd2.ProgramDateTypeId = 2
WHERE p.Id = @EntityId
'

UPDATe MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 33

UPDATE MetaTemplate
sET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MEtaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 33
)
USE [hancockcollege];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16319';
DECLARE @Comments nvarchar(Max) = 
	'Update Course Review Admin Report';
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
UPDATE AdminReport
SET ReportSQL = '
SELECT 
		s.SubjectCode as [Prefix],
		c.CourseNumber AS [Course Number],
		c.Title AS [Title],
		cast(CD.CourseDate AS Date) AS [Last Outline Revision],
		CASE
			WHEN cb03.Vocational = 1 THEN ''Yes''
		  WHEN cb03.Description IS NULL THEN ''Not Selected''
			ELSE ''No''
		END AS [CTE]
	FROM Course AS c
		INNER JOIN Subject AS s on c.SubjectId = s.Id
		LEFT JOIN Proposal As p on c.ProposalId = p.Id
		LEFT JOIN CourseDate CD ON CD.CourseId = c.Id
			AND CD.CourseDateTypeId = 5 --Last Outline Revision
		LEFT JOIN CourseCBCode AS cb on cb.CourseId = c.Id
		LEFT JOIN CB03 AS cb03 on cb.CB03Id = cb03.Id
	WHERE c.StatusAliasId = 1
	and c.Active = 1
	ORDER BY s.SubjectCode
	'
WHERE Id = 8
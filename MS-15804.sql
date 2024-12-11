USE [sdccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15804';
DECLARE @Comments nvarchar(Max) = 
	'Add Reports to proposals';
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
DECLARE @REPORTS TABLE (ReportId int, EntityId int)
INSERT INTO @REPORTS
VALUES
(0, 1),
(4, 1),
(43, 1),
(44, 2),
(50, 1),
(57, 2),
(258, 1),
(447, 1),
(464, 2),
(465,2)

INSERT INTO MetaReportTemplateType
(MetaReportId, MetaTemplateTypeId, StartDate)
SELECT
	r.ReportId,
	mtt.MetaTemplateTypeId,
	GETDATE()
FROM MetaTemplateType AS mtt
INNER JOIN MetaTemplate AS mt on mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
INNER JOIN @REPORTS As r on r.EntityId = mtt.EntityTypeId
WHERE mt.Active = 1
AND mt.IsDraft = 0
AND mtt.Active = 1
AND mtt.IsPresentationView = 0

DELETE FROM MetaReportTemplateType
WHERE Id IN (
    SELECT Id
    FROM (
        SELECT Id, ROW_NUMBER() OVER (PARTITION BY MetaReportId, MetaTemplateTypeId ORDER BY Id) AS row_num
        FROM MetaReportTemplateType
    ) AS duplicates
    WHERE row_num > 1
);
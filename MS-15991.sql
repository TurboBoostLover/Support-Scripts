USE hancockcollege;

/*
   Commit



	 Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15991';
DECLARE @Comments nvarchar(Max) = 'Create Custom Admin report "GE report"';
DECLARE @Developer nvarchar(50) = 'Nate W.';
DECLARE @ScriptTypeId int = 1; 
/*  
Default for @ScriptTypeId on this script 
is 1 for  Support,  
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

/*
--------------------------------------------------------------------
Please do not alter the script above this comment?except to set
the Use statement and the variables. 

Notes:  
	1.   In comments put a brief description of what the script does.
         You can also use this to document if we are doing something 
		 that is against meta best practices, but the client is 
		 insisting on, and that the client has been made aware of 
		 the potential consequences
	2.   ScriptTypeId
		 Note:  For Pre and Post Deploy we should follow the following 
		 script naming convention Release Number/Ticket Number/either the 
		 word Predeploy or PostDeploy
		 Example: Release3.103.0_DST-4645_PostDeploy.sql
-----------------Script details go below this line------------------
*/
DECLARE @ar INT;

DECLARE @reportSQL NVARCHAR(MAX) = '
DECLARE @custom NVARCHAR(MAX) = (SELECT CustomSql FROM MetaForeignKeyCriteriaClient WHERE Id = 49);
DECLARE @custom2 NVARCHAR(MAX) = (SELECT CustomSql FROM MetaForeignKeyCriteriaClient WHERE Id = 49);
DECLARE @user INT = (SELECT Id FROM [User] WHERE Email = ''supportadmin@curriqunet.com'');

SELECT c.Id, s.SubjectCode, c.CourseNumber, c.Title, CONCAT(ge.Title, '' - '',  gee.Title) AS [GE Status]
FROM Course c
	INNER JOIN Subject s ON s.Id = c.SubjectId
	INNER JOIN CourseGeneralEducation cge ON cge.CourseId = c.Id
	INNER JOIN GeneralEducationElement gee ON gee.Id = cge.GeneralEducationElementId
	INNER JOIN GeneralEducation ge ON ge.Id = gee.GeneralEducationId
	INNER JOIN StatusAlias sa ON sa.Id = c.StatusAliasId
WHERE gee.IsCore = 1
AND c.Active = 1
AND sa.StatusBaseId = 1
AND EXISTS (SELECT TOP 1 1 FROM MetaTemplate mt
				INNER JOIN MetaSelectedSection mss ON mss.MetaTemplateId = mt.MetaTemplateId
				INNER JOIN MetaSelectedField msf ON mss.MetaSelectedSectionId = msf.MetaSelectedSectionId
			WHERE msf.MetaAvailableFieldId IN (2632, 2633, 2634)
			AND mt.MetaTemplateId = c.MetaTemplateId)
AND gee.Active = 1
and ge.Active = 1
and gee.Id not in (244, 11, 20, 5, 239, 37, 2, 242, 15, 17, 48, 50,19, 36, 9, 10, 7, 240)
UNION
SELECT c.Id, s.SubjectCode, c.CourseNumber, c.Title, CONCAT(ge.Title, '' - '',  gee.Title) AS [GE Status]
FROM Course c
	INNER JOIN Subject s ON s.Id = c.SubjectId
	INNER JOIN CourseGeneralEducation cge ON cge.CourseId = c.Id
	INNER JOIN GeneralEducationElement gee ON gee.Id = cge.GeneralEducationElementId
	INNER JOIN GeneralEducation ge ON ge.Id = gee.GeneralEducationId
	INNER JOIN StatusAlias sa ON sa.Id = c.StatusAliasId
WHERE c.Active = 1
AND sa.StatusBaseId = 1
AND NOT EXISTS (SELECT TOP 1 1 FROM MetaTemplate mt
				INNER JOIN MetaSelectedSection mss ON mss.MetaTemplateId = mt.MetaTemplateId
				INNER JOIN MetaSelectedField msf ON mss.MetaSelectedSectionId = msf.MetaSelectedSectionId
			WHERE msf.MetaAvailableFieldId IN (2632, 2633, 2634)
			AND mt.MetaTemplateId = c.MetaTemplateId)
AND gee.Active = 1
and ge.Active = 1
and gee.Id not in (244, 11, 20, 5, 239, 37, 2, 242, 15, 17, 48, 50,19, 36, 9, 10, 7, 240)
UNION
SELECT c.Id, s.SubjectCode, c.CourseNumber, c.Title, CONCAT(''AHC GE - '', ca.Text) AS [GE Status]
FROM Course c
	INNER JOIN Subject s ON s.Id = c.SubjectId
	INNER JOIN StatusAlias sa ON sa.Id = c.StatusAliasId
	CROSS APPLY dbo.fnBulkResolveCustomSqlQuery(@custom, 1, c.Id, 1, @user, 1, NULL) ca
	INNER JOIN CourseGeneralEducation cge ON cge.CourseId = c.Id AND ca.Value = cge.GeneralEducationElementId
WHERE c.Active = 1
AND sa.StatusBaseId = 1
ORDER BY c.Id
';

INSERT INTO AdminReport(ReportName, ReportSQL, OutputFormatId)
VALUES
('GE Report', @reportSQL, 1);

SET @ar = SCOPE_IDENTITY();

INSERT INTO AdminReportClient(AdminReportId, ClientId)
VALUES
(@ar, 1);

INSERT INTO ClientReports(Title, ClientReportsGroupId, ClientReportsConfigurationId, ClientId, SortOrder, StartDate)
VALUES
('GE Report', 4, 12, 1, 14, CURRENT_TIMESTAMP);
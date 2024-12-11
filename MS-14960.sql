USE [sac];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14960';
DECLARE @Comments nvarchar(Max) = 
	'Update Agenda report query to look at active flag';
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
UPDATE report.AgendaReportQuery
SET QueryText = '
SET @_entityData = (
    SELECT c1.[Id] AS [Key], dbo.concat_agg(dbo.fnHtmlElement(''div'', dm.[Title], NULL)) AS [Text]
    FROM Course c1
    INNER JOIN @entity e ON c1.[Id] = e.[EntityId] AND c1.[Id] = @entityId
    LEFT JOIN (
        SELECT dm.[Title], cdedm.[CourseId]
        FROM [DeliveryMethod] dm
        INNER JOIN [CourseDistanceEducationDeliveryMethod] cdedm ON dm.[Id] = cdedm.[DeliveryMethodId]
				WHERE dm.Active = 1
    ) dm ON dm.[CourseId] = c1.[Id]
    GROUP BY c1.Id
    FOR JSON PATH
);

SET @_entitySummary = (
    SELECT CONCAT(
            dbo.fnHtmlOpenTag(''div'', dbo.fnHtmlAttribute(''class'', ''section'')),
            dbo.fnHtmlStandardLargeField(''Distance Learning Offerings'', [Text], NULL, NULL, '': '', 0),
            dbo.fnHtmlCloseTag(''div'')
        )
    FROM OPENJSON(@_entityData) WITH ([Text] NVARCHAR(MAX) ''$.Text'')
);

SELECT (
        CASE WHEN @_entitySummary IS NULL THEN '' '' ELSE @_entitySummary END
    ) AS [Text], @entityId AS [Value];
		'
WHERE Id = 10
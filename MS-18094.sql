USE [sdccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18094';
DECLARE @Comments nvarchar(Max) = 
	'Clean up data from copying over on the CourseDate information';
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
UPDATE MetaSelectedSection
SET AllowCopy = 0
WHERE MetaBaseSchemaId in (
	87, 150
)

UPDATE MetaSelectedField
SET AllowCopy = 0
WHERE MetaAvailableFieldId in (
	122, 120, 1127,1176
)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT MetaTemplateId FROM MetaSelectedSection WHERE MetaBaseSchemaId in (
		87, 150
	)
)

--This removes the copied over data that has more then 1 result for each date type and removes the oldest ones

DELETE FROM ProgramDate
WHERE Id NOT IN (
    SELECT MAX(Id)
    FROM ProgramDate
    GROUP BY ProgramId, ProgramDateTypeId
);

DELETE FROM CourseDate
WHERE Id NOT IN (
    SELECT MAX(Id)
    FROM CourseDate
    GROUP BY CourseId, CourseDateTypeId
);

DELETE FROM CourseDate
WHERE CourseId in (
	SELECT Id FROM Course WHERE StatusAliasId = 3 --draft
)

DELETE FROM ProgramDate
WHERE ProgramId in (
	SELECT Id FROM Program WHERE StatusAliasId = 3 --draft
	UNION
	SELECT 3542
)
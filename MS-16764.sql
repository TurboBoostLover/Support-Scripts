USE [sac];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16764';
DECLARE @Comments nvarchar(Max) = 
	'Remove CrossListing Tab';
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
DECLARE @ClientId int = 1

DECLARE @Temp INTEGERS
INSERT INTO @Temp
SELECT mss2.MetaTemplateId FROM MetaSelectedSection AS mss
INNER JOIN MetaSelectedSection AS mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
WHERE mss.MetaBaseSchemaId = 124
and mss2.MetaSelectedSection_MetaSelectedSectionId IS NULL

DECLARE @TABS INTEGERS
INSERT INTO @TABS
SELECT mss2.MetaSelectedSectionId FROM MetaSelectedSection AS mss
INNER JOIN MetaSelectedSection AS mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
WHERE mss.MetaBaseSchemaId = 124
and mss2.MetaSelectedSection_MetaSelectedSectionId IS NULL

while exists(select top 1 1 from @TABS)
begin
    declare @TID int = (select top 1 * from @TABS)
    EXEC spBuilderSectionDelete @clientId, @TID
    delete @TABS
    where id = @TID
END

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT Id FROM @Temp
)
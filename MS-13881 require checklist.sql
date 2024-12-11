USE [reedley];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13881';
DECLARE @Comments nvarchar(Max) = 
	'Update MetaControlAttribute to not require more then 1 just require 1 or more';
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
DECLARE @templateId Table (id int)
INSERT INTO @templateId
	SELECT mt.MetaTemplateId
	FROM MetaTemplateType mtt
		INNER JOIN MetaTemplate mt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
	WHERE mt.Active = 1 
		AND mtt.EntityTypeId = 2
		AND mt.IsDraft = 0
		AND mt.EndDate IS NULL
		AND mtt.Active = 1
		AND mtt.IsPresentationView = 0
		AND mtt.ClientId = 1


UPDATE MetaSqlStatement
SET SqlStatement = '
declare @totalCount int = (
	select count(id) 
	from ProgramOutcome
	where Programid = @entityid )

select case
	when @totalCount >= 1
	then 1
	else 0
end;
'
WHERE Id = 6

update MetaTemplate
set LastUpdatedDate = getdate()
WHERE MetaTemplateId in (
	SELECT Id FROM @templateId
)

while exists(select top 1 1 from @templateId)
begin
    declare @TID int = (select top 1 * from @templateId)
    exec upUpdateEntitySectionSummary @entitytypeid = 2,@templateid = @TID
    delete @templateId
    where id = @TID
end
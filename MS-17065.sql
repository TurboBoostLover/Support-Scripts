USE [chabot];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17065';
DECLARE @Comments nvarchar(Max) = 
	'Update requirements on SLO Assessment';
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
UPDATE MetaSqlStatement 
SET SqlStatement = '
DECLARE @Total int = (SELECT Count(Id) FROM ModuleCourseOutcome WHERE ModuleId = @entityID)
DECLARE @Count1 int = (
SELECT Count(mco.Id) FROM ModuleCourseOutcome AS mco
WHERE ModuleId = @entityID
and mco.YesNoId_01 IS NOT NULL
and mco.MaxText01 IS NOT NULL
and (mco.NeedResources <> 1 or mco.NeedResources IS NULL)
and mco.Id in (
	SELECT ModuleCourseOutcomeId FROM ModuleCourseOutcomeEvaluationMethod AS Mcoe INNER JOIN ModuleCourseOutcome AS mco on mcoe.ModuleCourseOutcomeId = mco.Id WHERE mco.ModuleId = @EntityId
))
DECLARE @Count2 int = (
SELECT Count(mco.Id) FROM ModuleCourseOutcome AS mco 
WHERE ModuleId = @entityID
and mco.YesNoId_01 IS NOT NULL
and mco.MaxText01 IS NOT NULL
and mco.NeedResources = 1
and mco.MaxText05 IS NOT NULL
)

SELECT CASE
	WHEN SUM(ISNULL(@Count1, 0) + ISNULL(@Count2, 0)) = @Total THEN 1
	ELSE 0
	END AS IsValid
'
WHERE Id = 9

UPDATE MetaSqlStatement
SET SqlStatement = '
DECLARE @Total int = (SELECT Count(Id) FROM ModuleCourseOutcome WHERE ModuleId = @entityID)
DECLARE @Count1 int = (
SELECT Count(Id) FROM ModuleCourseOutcome WHERE ModuleId = @entityID
and Int02 IS NOT NULL
and Int03 IS NOT NULL
and Int04 IS NOT NULL
and OutcomeMasteryId IS NOT NULL
and MaxText02 IS NOT NULL
)

SELECT
CASE WHEN @Count1 = @Total THEN 1
ELSE 0
END AS Isvalid
'
WHERE Id = 10

DECLARE @Template INTEGERS
INSERT INTO @Template
SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
INNER JOIN MetaControlAttribute AS mca on mca.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE mca.MetaSqlStatementId in (9, 10)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT Id FROM @Template
)

while exists(select top 1 1 from @Template)
begin
    declare @TID int = (select top 1 * from @Template)
    exec upUpdateEntitySectionSummary @entitytypeid = 6,@templateid = @TID
    delete @Template
    where id = @TID
end
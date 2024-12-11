USE [ccsf];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15940';
DECLARE @Comments nvarchar(Max) = 
	'Remove duplicating data and bad data';
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
delete
from ProgramOutcome
where ProgramId is null;

--remove duplicate records from ProgramOutcome table
declare @programOutcomeIds integers;
insert into @programOutcomeIds
select t.Id
from (
	select Id, ProgramId, row_number() over (partition by ProgramId, Outcome order by SortOrder) as duplicateRecords
	from ProgramOutcome
) t
where t.duplicateRecords > 1;

--to be able to remove duplicates from the ProgramOutcome table, I have to first remove the duplicate id(s) from ClientLearningOutcomeProgramOutcome table
delete clopo
from ClientLearningOutcomeProgramOutcome clopo
	inner join @programOutcomeIds poId on clopo.ProgramOutcomeId = poId.Id
;

--remove duplicate records from ProgramOutcome table
delete po
from ProgramOutcome po
	inner join @programOutcomeIds poId on po.Id = poId.Id
;

--remove duplicate records from CourseOutcome table
declare @courseOutcomeIds integers;
insert into @courseOutcomeIds
select t.Id
from (
	select Id, CourseId, row_number() over (partition by CourseId, OutcomeText order by SortOrder) as duplicateRecords
	from CourseOutcome
) t
where t.duplicateRecords > 1;

--to be able to remove the duplicates from CourseOutcome table, I first have to remove the duplicate id(s) from the ProgramOutcomeMatching table
delete pom
from ProgramOutcomeMatching pom
	inner join @courseOutcomeIds coId on pom.CourseOutcomeId = coId.Id
;

--to be able to remove the duplicates from CourseOutcome table, I first have to remove the duplicate id(s) from the CourseOutcomeGeneralEducationOutcome table
delete cogeo
from CourseOutcomeGeneralEducationOutcome cogeo
	inner join @courseOutcomeIds coId on cogeo.CourseOutcomeId = coId.Id
;
--to be able to remove the duplicates from CourseOutcome table, I first have to update one of the duplicate CourseOutcomeId to point to the other CourseOutcomeId that is not being deleted for a assessment
update md
set Reference_CourseOutcomeId = 27030
from ModuleDetail md
where md.Id = 39151;

--to be able to remove the duplicates from CourseOutcome table, I have to null out the PreviousId to other records where the duplicate id(s) are being deleted
update co
set PreviousId = null
from CourseOutcome co
	inner join @courseOutcomeIds coId on co.PreviousId = coId.Id
;

--remove duplicate records from CourseOutcome table
delete co
from CourseOutcome co
	inner join @courseOutcomeIds coId on co.Id = coId.Id
;

--to be able to remove duplicates from ProgramOutcomeMatching table, I first have to null out the PreviousId to other records where the duplicate id(s) are being deleted
with removeDuplicateRecords as (
	select t.Id, t.duplicateRecords
	from (
		select Id, row_number() over (partition by ProgramOutcomeId, CourseOutcomeId order by ProgramOutcomeId, CourseOutcomeId, Id) as duplicateRecords
		from ProgramOutcomeMatching
	) t
	where t.duplicateRecords > 1
)

update pom
set PreviousId = null
from ProgramOutcomeMatching pom
	inner join removeDuplicateRecords rdr on pom.PreviousId = rdr.Id
;

--remove duplicates from ProgramOutcomeMatching table
with removeDuplicateRecords as (
	select t.Id, t.duplicateRecords
	from (
		select pom.Id, row_number() over (partition by pom.ProgramOutcomeId, pom.CourseOutcomeId order by pom.ProgramOutcomeId, CourseOutcomeId, Id) as duplicateRecords
		from ProgramOutcomeMatching pom
	) t
	where t.duplicateRecords > 1
)

delete pom
from ProgramOutcomeMatching pom
	inner join removeDuplicateRecords rdr on pom.Id = rdr.Id
;

DELETE FROM ProgramOutcomeMatching WHERE Id in (
164355,164356,164357,164358,164364, 164365
)

DELETE FROM ClientLearningOutcomeProgramOutcome WHERE Id = 23126
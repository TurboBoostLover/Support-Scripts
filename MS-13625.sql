USE [delta];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13625';
DECLARE @Comments nvarchar(Max) = 
	'Update Admin Report Section-Level SLO Assessment report ';
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
SET QUOTED_IDENTIFIER OFF

DECLARE @SQL NVARCHAR(MAX) = "
select distinct  
crn.CRNnumber + coalesce(' - ' + sem.Title,'') as Section,
case when (ME01.CRNid is not null ) then 'Assessed'
	else 'Not Assessed'
	end as Assessed,
case when OE.Code is not null then  '(' + OE.Code + ') ' + OE.Title
	else OE.Title end as Division,
case when OE2.Code is not null then  '(' + OE2.Code + ') ' + OE2.Title
	else OE2.Title end as Department,
S.SubjectCode + ' - ' + S.Title as Subject,
u.FirstName + ' ' + u.LastName as Originator
from CRN crn
	inner join CRNOffering co on co.CRNId = crn.Id
	inner join Semester sem on co.SemesterId = sem.Id and sem.Active = 1
	inner join Subject S on S.id = CRN.SubjectId and S.Active = 1
	left join OrganizationSubject OS on S.id = OS.SubjectId and OS.Active = 1
	left join OrganizationLink OL on OS.OrganizationEntityId = OL.Child_OrganizationEntityId and OL.Active = 1
	left join OrganizationEntity OE on OL.Parent_OrganizationEntityId = OE.Id and OE.Active = 1
	left join OrganizationEntity OE2 on OS.OrganizationEntityId = OE2.Id and OE2.Active = 1
	left join (
		select*
		from ModuleExtension01
		where ModuleId in (
			select id
			from Module
			where Active = 1 and StatusAliasId = 1)) ME01 on ME01.CRNid=CRN.id
	left join Module m on (m.id - 1)= ME01.id
	left join [User] u on u.id = m.UserId
where (s.Id = @subjectId OR @subjectId = 0)
	and sem.Id = @semesterId
	and ((ME01.CRNid is not null and @Assessedid = 1)
		or
		(ME01.CRNid is null and @Assessedid = 0))
order by crn.CRNnumber + coalesce(' - ' + sem.Title,'')
"
SET QUOTED_IDENTIFIER ON

UPDATE AdminReport
SET ReportSQL = @SQL
WHERE Id = 3
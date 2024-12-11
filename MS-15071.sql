USE [palomar];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15071';
DECLARE @Comments nvarchar(Max) = 
	'Update Admin report';
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
UPDATE AdminReport
SET ReportSQL = '
select
OE1.Title as Division,
OE2.Title as Department,
AT.Title as [Award Type],
P.Title as [Program Title],
cast(SUMMIN.SUMMIN as NVARCHAR(20)) as [Program Min Units],
cast(SUMMAX.SUMMAX as NVARCHAR(20)) as [Program Max Units],
cast(CO.SortOrder as NVARCHAR(20)) as [Block Order],
CO.CourseOptionNote as [Block Title],
Coalesce(PC.ProgramCourseRule,'''') as [Group Title],
PC.SortOrder as [Item Order],
LIT.Title as [Item Type],
concat(S.SubjectCode,'' '',C.CourseNumber) as [Course Title],
ge.title as [GE Title],
GEE.text as [GE Element Code],
CB.code as [Transfer Status],
CB2.code as [SAM  Code],
CP.CraftonCrseId as [Course id],
Coalesce(GC.Title,'''') as [Item Condition],
Coalesce(cast(PC.CalcMin as NVARCHAR(20)),'''') as [Course Min Units],
Coalesce(cast(PC.CalcMax as NVARCHAR(20)),'''') as [Course Max Units],
CO.CalcMin as [Block Min Units],
CO.CalcMax as [Block Max Units],
Coalesce(PC.Header,'''') as [Non-Course Requirement Description],
sub.SubjectCode AS [Program Discipline],
pp.ChancelorNumber AS [Chancelor’s Nbr Ads],
gt.Text25514 AS [Chancelor’s Nbr Certs]
from Program P
	INNER JOIN Subject AS sub on p.SubjectId = sub.Id
	INNER JOIN ProgramProposal AS pp on pp.ProgramId = p.Id
	INNER JOIN Generic255Text AS gt on gt.ProgramId = p.Id
	inner join (
		select ProgramId,SUM(CO2.CalcMin) as SUMMIN from CourseOption CO2 
		group by ProgramId
	) SUMMIN on SUMMIN.ProgramId = P.id
	inner join (
		select ProgramId,SUM(CO2.CalcMax) as SUMMAX from CourseOption CO2 
		group by ProgramId
	) SUMMAX on SUMMAX.ProgramId = P.id
	inner join OrganizationEntity OE1 on P.Tier1_OrganizationEntityId = OE1.Id
	inner join OrganizationEntity OE2 on P.Tier2_OrganizationEntityId = OE2.Id
	inner join AwardType AT on P.AwardTypeId = AT.Id
	inner join CourseOption CO on CO.ProgramId = P.id
	inner join ProgramCourse PC on PC.CourseOptionId = CO.id
	left join GroupCondition GC on PC.GroupConditionId = GC.id
	inner join ListItemType LIT on PC.ListItemTypeId = LIT.id
	left join course C on C.id = PC.CourseId
	left join Subject S on C.SubjectId = S.Id
	left join CourseGeneralEducation CGE on C.id = CGE.CourseId
	left join GeneralEducation GE on CGE.GeneralEducationId = GE.id
	left join GeneralEducationElement GEE on GEE.id = CGE.GeneralEducationElementId
	left join CourseCBCode CCB on C.id = CCB.CourseId
	left join CB05 CB on CCB.CB05Id = CB.Id
	left join CB09 CB2 on CCB.CB09Id = CB2.Id
	left join CourseProposal CP on C.id = CP.CourseId
where P.Active = 1
	and P.StatusAliasId = 1
order by OE1.Title,OE2.Title,P.Title,CO.SortOrder,PC.SortOrder,GE.sortorder,GEE.sortorder
'
WHERE Id = 1007
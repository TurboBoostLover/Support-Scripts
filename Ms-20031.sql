USE [ccsf];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-20031';
DECLARE @Comments nvarchar(Max) = 
	'Update Query for Requisites drop down';
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
DECLARE @Id int = 14

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
DECLARE @Subject int = (SELECT SubjectId FROM CourseRequisite WHERE Id = @pkIdValue)

select 
	c.Id as Value
	,s.SubjectCode + '' '' + c.CourseNumber + '' - '' + c.Title + '' ('' + sa.Title + '')'' as Text,
	s.Id AS filterValue,
	s.Id AS FilterValue
from Course c
	inner join [Subject] s on s.Id = c.SubjectId
	inner join StatusAlias sa on sa.Id = c.StatusAliasId
where c.ClientId = @ClientId
and c.Active = 1
and c.SubjectId = @subject
and sa.StatusBaseId in (1, 2, 4, 6)
union
select c.id as value
	,s.subjectcode + '' '' + c.coursenumber + '' - '' + c.title + '' ('' + sa.title + '') - *Remove SLO Mapping*'' as Text,
	s.Id AS filterValue,
	s.Id AS FilterValue
from courserequisite cr
	inner join courserequisitecourseoutcome crco on cr.id = crco.courserequisiteid
	inner join courseoutcome co on crco.courseoutcomeid = co.id
	inner join course c on co.courseid = c.id
	inner join [subject] s on s.id = c.subjectid
	inner join statusalias sa on sa.id = c.statusaliasid
where cr.courseid = @EntityId
and c.subjectid = @subject
and cr.requisite_courseid <> co.courseid
union
select c.id as value
	,s.subjectcode + '' '' + c.coursenumber + '' - '' + c.title + '' ('' + sa.title + '')'' as Text,
	s.Id AS filterValue,
	s.Id AS FilterValue
from courserequisite cr
	inner join course c on cr.Requisite_CourseId = c.id
	inner join [subject] s on s.id = c.subjectid
	inner join statusalias sa on sa.id = c.statusaliasid
where cr.courseid = @EntityId
order by text;
'
WHERE Id = @Id

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @Id
WHERE MetaAvailableFieldId = 298
and MetaForeignKeyLookupSourceId IS NULL

UPDATE CourseRequisite
SET Requisite_CourseId = 7447
WHERE Id IN (
    26449
);


UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId = @Id
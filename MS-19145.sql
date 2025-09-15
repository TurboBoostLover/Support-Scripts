USE [sbcc];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19145';
DECLARE @Comments nvarchar(Max) = 
	'Update Query text on COR for Requisites';
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
DECLARE @Id int = 22

DECLARE @SQL NVARCHAR(MAX) = '
declare @reqTypeId int
declare @reqTitle NVARCHAR(150)
declare @final NVARCHAR(max) = ''''

declare requisites CURSOR for
select Id,Title
from RequisiteType
where active = 1
order by SortOrder

open requisites

fetch next from requisites into @reqTypeId,@reqTitle

while @@FETCH_STATUS = 0
BEGIN

    declare @combinedReqs NVARCHAR(max) = (
        select 
                STRING_AGG(concat(
                    s.SubjectCode,space(1),c.CourseNumber,space(1)
                    ,case when cr.CourseRequisiteComment is not null then concat(cr.CourseRequisiteComment,space(1)) end
                    ,case when ec.Title is not null then concat(ec.Title,space(1)) end
                    ,case when cr.EnrollmentLimitation is not null then concat(cr.EnrollmentLimitation,space(1)) end
                    ,sp1.Code,con.Title,sp2.Code,space(1)
                ), '''') WITHIN GROUP (ORDER BY cr.SortOrder, cr.Id)
            from CourseRequisite cr
                left join course c on c.id = cr.Requisite_CourseId
                left join Subject s on c.SubjectId = s.Id
                left join EligibilityCriteria ec on ec.id = cr.EligibilityCriteriaId
                left join Condition con on con.Id = cr.ConditionId
				left join SpecialCharacter sp1 on sp1.Id = cr.OpenParen_SpecialCharacterId
				left join SpecialCharacter sp2 on sp2.Id = cr.CloseParen_SpecialCharacterId
            where cr.CourseId = @entityId
            and cr.RequisiteTypeId = @reqTypeId
            group by cr.RequisiteTypeId
    )

    set @final += concat(@reqTitle,'': '',coalesce(@combinedReqs,''None''),''<br>'')    

fetch next from requisites into @reqTypeId,@reqTitle

end

close requisites

deallocate requisites

select 0 as Value, @final as Text
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id= @Id

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId = @Id
USE [clovis];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13862';
DECLARE @Comments nvarchar(Max) = 
	'Add Requisite type to drop down';
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
INSERT INTO RequisiteType
(Title, SortOrder, ClientId, StartDate, Active_Old)
VALUES
('Limitations on Enrollment', 5, 1, GETDATE(),1),
('Entrance Skills', 4, 1, GETDATE(),1)

UPDATE RequisiteType
SET SortOrder = 1
WHERE Id = 3

UPDATE RequisiteType
SET SortOrder = 2
WHERE Id = 4

UPDATE RequisiteType
SET SortOrder = 3
WHERE Id = 2

UPDATE RequisiteType
SET SortOrder = 6
WHERE Id = 1

UPDATE RequisiteType
SET SortOrder = 7
WHERE Id = 5

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
select 0 as [Value]
, rs.[Text]
from (
    select @entityId as Value
    , dbo.ConcatWithSepOrdered_Agg(''<br>'', rto.SortOrder, rrq.RenderedRequisite) as [Text]
    from (
        select @entityId as CourseId
        , rt.Id as RequisiteTypeId 
        , rt.Title as RequisiteType
        ,	dbo.ConcatWithSepOrdered_Agg(space(1), coalesce(rqs.SortOrder, 0), coalesce(rqs.RequisiteRow, ''None'')) as Requisites
        from RequisiteType rt
            left join (
                select cr.CourseId as CourseId
                , cr.RequisiteTypeId
                , concat(
                    s.subjectCode, 
                    case 
                        when s.subjectCode is not null then concat(space(1), c.coursenumber)
                        else c.coursenumber
                        end,
                    case 
                        when c.coursenumber is not null then concat(space(1), cr.CourseRequisiteComment)
                        else cr.CourseRequisiteComment
                        end,
                    case 
                        when cr.CourseRequisiteComment is not null then concat(space(1), con.Title)
                        else con.Title
                        end
                ) as RequisiteRow
                , row_number() over (partition by cr.CourseId order by cr.SortOrder, cr.Id) as SortOrder
                from CourseRequisite cr
                    left join [Subject] s on s.id = cr.SubjectId
                    left join course c on c.id = cr.Requisite_CourseId
                    left join Condition con on con.Id = cr.ConditionId
                where cr.courseId = @entityId
            ) rqs 
                on rt.Id = rqs.RequisiteTypeId
        -- Prerequisite, Corequisite, Anti Requisite, Advisory
        where rt.Id in (1, 2, 3, 4, 5, 6, 7)
        group by rt.Id, rt.Title
    ) rqs
    cross apply (
        select concat(
            rqs.RequisiteType, '': '',
            rqs.Requisites
        ) as RenderedRequisite
    ) rrq
    cross apply (
        select 
            case
                -- Prerequisite
                when rqs.RequisiteTypeId = 1 then 1
                -- Corequisite
                when rqs.RequisiteTypeId = 2 then 2
                -- Advisory
                when rqs.RequisiteTypeId = 3 then 3
                -- Anti Requisite
                when rqs.RequisiteTypeId = 4 then 4
				-- None
                when rqs.RequisiteTypeId = 5 then 5
				-- Limitations on Enrollment
				when rqs.RequisiteTypeId = 6 then 6
				-- Entrance Skills
				When rqs.RequisiteTypeId = 7 then 7
                else -1
            end as SortOrder
    ) rto
) rs
'
WHERE Id = 1377

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
SELECT mt.MetaTemplateId
FROM MetaTemplateType mtt
    INNER JOIN MetaTemplate mt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
WHERE mt.Active = 1 
    AND mtt.EntityTypeId = 1
    AND mt.IsDraft = 0
    AND mt.EndDate IS NULL
    AND mtt.Active = 1
    AND mtt.IsPresentationView = 0
    AND mtt.ClientId = 1
)
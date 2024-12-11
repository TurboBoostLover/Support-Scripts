USE [chaffey];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14272';
DECLARE @Comments nvarchar(Max) = 
	'Delete Legacy data';
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
DELETE FROM CourseEvaluationMethod wHERE EvaluationMethodId in (
	SELECT Id FROM EvaluationMethod WHERE Parent_Id = 58
)

DELETE FROM CourseAdditionalResource WHERE AdditionalResourceId in (
	SELECT Id FROM AdditionalResource WHERE Parent_Id = 68
)

SET QUOTED_IDENTIFIER OFF

DECLARE @SQL nvarchar(max) = "
declare @groupMOE int = (
			select top 1 em.Id
			from CourseEvaluationMethod cem
				inner join EvaluationMethod em on cem.EvaluationMethodId = em.Id
			where cem.CourseId = @entityId
			and em.Parent_Id <> 58--58 = <span style=""color: red;"">Legacy Data (un-check options if checked)</span>
		);

		declare @moe int = (
			select top 1 em.Id
			from CourseEvaluationMethod cem
				inner join EvaluationMethod em on cem.EvaluationMethodId = em.Id
				inner join Course c	on cem.CourseId = c.Id
			where cem.CourseId = @entityId
			and c.MetaTemplateId in (1, 18, 19, 21, 26)--1 = New Course, 18 = Modify Course, 19 = Deactivate Course, 21 = Course Emergency Addendum, 26 = Course Reactivation
			and em.Parent_Id = 58--58 = <span style=""color: red;"">Legacy Data (un-check options if checked)</span>
		);

		declare @checkedMOE nvarchar(max);

		if (@groupMOE is not null)
			begin
				select @checkedMOE = dbo.ConcatWithSepOrdered_Agg(NULL, d.SortOrder, rg.RenderedGroup)
				from (
					select em.Id
					   , em.Title
					   , em.SortOrder
					from EvaluationMethod em
					where em.Parent_Id is null
					and em.Id in (
						select em.Parent_Id
						from CourseEvaluationMethod cem
							inner join EvaluationMethod em on cem.EvaluationMethodId = em.Id
							inner join EvaluationMethod em2 on em.Parent_Id = em2.Id
						where cem.CourseId = @entityId
						and em2.Id <> 58--58 = <span style=""color: red;"">Legacy Data (un-check options if checked)</span>
						--AND em.Id = em2.Id
					)
					AND Id <> 58
				) d
					cross apply (
						select dbo.ConcatWithSepOrdered_Agg(NULL, em.SortOrder, rt.RenderedTitle) as RenderedEntries
						from CourseEvaluationMethod cem
							inner join EvaluationMethod em on cem.EvaluationMethodId = em.Id
							cross apply (
								select 
									concat(
										dbo.fnHtmlOpenTag('li', NULL)
											, em.Title
										, dbo.fnHtmlCloseTag('li')
									) as RenderedTitle
							) rt
						where cem.CourseId = @entityId
						and d.Id = em.Parent_Id
					) re
					cross apply (
						select 
							concat(
								dbo.fnHtmlOpenTag('li', NULL)
									, dbo.fnHtmlOpenTag('div', NULL)
										, d.Title
									, dbo.fnHtmlCloseTag('div')
									, dbo.fnHtmlOpenTag('ul', NULL)
										, re.RenderedEntries
									, dbo.fnHtmlCloseTag('ul')
								, dbo.fnHtmlCloseTag('li')
							) as RenderedGroup
					) rg
			end
		else
			if (@moe is not null)
				begin
					select @checkedMOE = dbo.ConcatWithSepOrdered_Agg(NULL, em.SortOrder, rt.RenderedTitle)
					from CourseEvaluationMethod cem
						inner join EvaluationMethod em on cem.EvaluationMethodId = em.Id
						cross apply (
							select 
								concat(
									dbo.fnHtmlOpenTag('li', NULL)
										, em.Title
									, dbo.fnHtmlCloseTag('li')
								) as RenderedTitle
						) rt
					where cem.CourseId = @entityId
				end
		;

		declare @moeOther nvarchar(max);

		select @moeOther = dbo.Concat_Agg(rt.RenderedTitle)
		from (
			select
				case 
					when c.RationaleOther = 1
						then 
							concat(
								dbo.fnHtmlOpenTag('li', NULL)
									, '<b>Other:</b>'
									, space(1)
									, c.AdvisoryCommittee
								, dbo.fnHtmlCloseTag('li')
							)
						else null
				end as RenderedTitle
			from Course c
			where c.Id = @entityId
		) rt;

		select 0 as [Value]
		   , concat(
				dbo.fnHtmlOpenTag('ul', null)
					, @checkedMOE
					, @moeOther
				, dbo.fnHtmlCloseTag('ul')
			) as [Text]
		;
"

DECLARE @SQL2 NVARCHAR(MAX) = "
declare @groupMOI int = ( SELECT TOP 1
        ar.Id
    FROM CourseAdditionalResource car
    INNER JOIN AdditionalResource ar
        ON car.AdditionalResourceId = ar.Id
    WHERE car.CourseId = @EntityId
    AND ar.Parent_Id <> 68);
    declare @moi int = ( SELECT TOP 1
        ar.Id
    FROM CourseAdditionalResource car
    INNER JOIN AdditionalResource ar
        ON car.AdditionalResourceId = ar.Id
	INNER JOIN Course c	
		ON c.Id = car.CourseId
    WHERE car.CourseId = @EntityId
	AND c.MetaTemplateId IN (1, 18, 19, 21, 26)
    AND ar.Parent_Id = 68);
    declare @checkedMOI nvarchar(max);
    if (@groupMOI is not null)     begin
SELECT
    @checkedMOI = dbo.ConcatWithSepOrdered_Agg(NULL, d.SortOrder, rg.RenderedGroup)
FROM (
SELECT
        ar.Id
       ,ar.Title
       ,ar.SortOrder
    FROM AdditionalResource ar
    WHERE ar.Parent_Id IS NULL
    AND ar.Id in (
			SELECT ar.Parent_Id
        FROM CourseAdditionalResource car
				 INNER JOIN AdditionalResource ar on car.AdditionalResourceId = ar.Id
        INNER JOIN AdditionalResource ar2 ON ar.Parent_Id = ar2.Id
        WHERE car.CourseId = @EntityId
                AND ar.Id <> 68
        )
				and Id <> 68
				) d
CROSS APPLY (SELECT
        dbo.ConcatWithSepOrdered_Agg(NULL, ar.SortOrder, rt.RenderedTitle) AS RenderedEntries
    FROM CourseAdditionalResource car
    INNER JOIN AdditionalResource ar
        ON car.AdditionalResourceId = ar.Id
    CROSS APPLY (SELECT
            CONCAT(dbo.fnHtmlOpenTag('li', NULL), ar.Title, dbo.fnHtmlCloseTag('li')) AS RenderedTitle) rt
    WHERE car.CourseId = @EntityId
    AND d.Id = ar.Parent_Id) re
CROSS APPLY (SELECT
        CONCAT(dbo.fnHtmlOpenTag('li', NULL), dbo.fnHtmlOpenTag('div', NULL), d.Title, dbo.fnHtmlCloseTag('div'), dbo.fnHtmlOpenTag('ul', NULL), re.RenderedEntries, dbo.fnHtmlCloseTag('ul'), dbo.fnHtmlCloseTag('li')) AS RenderedGroup) rg
END
ELSE
IF (@moi IS NOT NULL)
BEGIN
SELECT
    @checkedMOI = dbo.ConcatWithSepOrdered_Agg(NULL, ar.SortOrder, rt.RenderedTitle)
FROM CourseAdditionalResource car
INNER JOIN AdditionalResource ar
    ON car.AdditionalResourceId = ar.Id
CROSS APPLY (SELECT
        CONCAT(dbo.fnHtmlOpenTag('li', NULL), ar.Title, dbo.fnHtmlCloseTag('li')) AS RenderedTitle) rt
WHERE car.CourseId = @EntityId
END;
SELECT
    0 AS [Value]
   ,CONCAT(dbo.fnHtmlOpenTag('ul', NULL), @checkedMOI, dbo.fnHtmlCloseTag('ul')) AS [Text];
"

SET QUOTED_IDENTIFIER ON

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 205

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL2
, ResolutionSql = @SQL2
WHERE Id = 195

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
    AND mtt.IsPresentationView = 1
    AND mtt.ClientId = 1
		AND mtt.MetaTemplateTypeId in (27)
)
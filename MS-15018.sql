USE [sac];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15018';
DECLARE @Comments nvarchar(Max) = 
	'Update Catalog Query text';
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
DECLARE @SQL NVARCHAR(MAX) = '
declare @isHonors bit = (
	select coalesce(c.IsDistanceEd, 0)
	from Course c
	where c.Id = @entityId
);

-- using a window function to get the order of the requisite instead of the 
-- sort order incase there are duplicates
DECLARE @RequisiteOrder table (CRId int, Sort int)
insert INTO @RequisiteOrder (CRID,Sort)
SELECT
	id as CRID,
	ROW_NUMBER() over (order by SortOrder) as sort
FROM courseRequisite
where CourseId = @entityId

DECLARE @requisiteByType table (rtid int, Requistes nvarchar(max), sort int)
INSERt INTO @requisiteByType (rtid,Requistes,sort)
SELECT 
	Rt.id,
	Concat(
		CASE
			WHEN rt.id = 1 --Prerequisite
				then	CASE 
						WHEN cr.Bit15 != 1 OR cr.Bit15 IS NULL
							THEN ''Prerequisite: Completion with a grade of "C" or better or a Passing grade in: ''
						ELSE ''''
						END
			WHEN rt.id = 2 --Corequisite (Concurrent)
				THEN ''Corequisite: Concurrent enrollment in: ''
			WHEN rt.id = 3 --Recommended Preparation
				then	CASE 
						WHEN cr.Bit15 != 1 OR cr.Bit15 IS NULL
							THEN ''Recommended Preparation: Completion with a grade of "C" or better or a Passing grade in: ''
						ELSE ''''
						END
			WHEN RT.id = 5 --Corequisite (Previous or Concurrent)
				then	CASE 
						WHEN cr.Bit15 != 1 OR cr.Bit15 IS NULL
							then ''Corequisite: Completion with a grade of "C" or better or a Passing grade or Concurrent enrollment in: ''
						ELSE ''''
						END
			ELSE rt.Title --All other Requisites type
		END,
		dbo.ConcatWithSepOrdered_Agg(
			'' '',
			ro.Sort,
			CONCAT(
				Case
					when cr.Requisite_CourseId is not null 
						and cr.RequisiteTypeId is not null 
						and cr.RequisiteTypeId <> 4 --Other
					then concat(s.SubjectCode, '' '', rc.CourseNumber)
				END,
				CASE
					when len(cr.EnrollmentLimitation) >0
						then 
							concat(
								space(1),
								cr.EnrollmentLimitation
							)
				END,
				'' '',con.Title
			)
		),
		'';''
	),
	min(ro.sort) As sort
FROM CourseRequisite cr
	left join RequisiteType rt on cr.RequisiteTypeId = rt.Id
	INNER JOIN @RequisiteOrder ro on cr.id = ro.CRId
	left join Condition con on cr.ConditionId = con.Id
	left join Course rc on cr.Requisite_CourseId = rc.Id
	left join [Subject] s on rc.SubjectId = s.Id
Group by Rt.id, rt.Title, cr.Bit15

SELECT
	CONCAT(
		CASE
			when @isHonors =1
			then ''Requisite: A college GPA or high school GPA for first term college students of 3.0 or higher;<br>''
		end,
		dbo.ConcatWithSepOrdered_Agg(''<br>'',sort,Requistes)
	)As Text,
	0 AS Value
FROM @requisiteByType
'

UPDATE MetaForeignKeyCriteriaClient 
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 14

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mt.MetaTemplateId FROM MetaTemplate AS mt
	INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 14
)
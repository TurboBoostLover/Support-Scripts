USE [clovis];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14487';
DECLARE @Comments nvarchar(Max) = 
	'Create mew Course Outline Report';
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

exec spBuilderTemplateActivate @clientId = 1, @metaTemplateId = 29, @metaTemplateTypeId = 11
--Hard Code its on live and wont change

------------------------------------------------------------------------
Declare @clientId int =1, -- SELECT Id, Title FROM Client 
	@Entitytypeid int =1; -- SELECT * FROM EntityType (1 = course, 2 = program, 6 = module)

declare @templateId integers

INSERT INTO @templateId
SELECT mt.MetaTemplateId
FROM MetaTemplateType mtt
    INNER JOIN MetaTemplate mt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
WHERE mt.Active = 1 
    AND mtt.EntityTypeId = @entityTypeId
    AND mt.IsDraft = 0
    AND mt.EndDate IS NULL
    AND mtt.Active = 1
    AND mtt.IsPresentationView = 1		--comment out if doing reports and forms
    AND mtt.ClientId = @clientId
		AND mtt.MetaTemplateTypeId in (11)		--comment back in if just doing some of the mtt's

declare @FieldCriteria table (
	TabName nvarchar(255) index ixRecalcFieldCriteria_TabName,
	TableName sysname index ixRecalcFieldCriteria_TableName,
	ColumnName sysname index ixRecalcFieldCriteria_ColumnName,
	Action nvarchar(max)
);
/************************* Put fields Here ***********************
*************************Only Edit Values************************/
insert into @FieldCriteria (TabName, TableName, ColumnName,Action)
values
('NULL', 'CourseQueryText', 'QueryTextId_02','Update'),
('NULL', 'CourseQueryText', 'QueryTextId_03','UpdateHalf'),
('NULL', 'CourseQueryText', 'QueryTextId_50','Update2'),
('Units & Hours', 'CourseQueryText', 'QueryTextId_49','Update3'),
('Requisites', 'CourseQueryText', 'QueryTextId_48','Update4'),
('Transfer/General Education:', 'CourseQueryText', 'QueryTextId_47','Update5'),
('Objectives & Outcomes:', 'CourseQueryText', 'QueryTextId_46','Update6'),
('Methods of Instruction:', 'CourseQueryText', 'QueryTextId_45','Update7'),
('Sample Homework & Out-of-Class Assignments:', 'CourseQueryText', 'QueryTextId_44','Update8'),
('Methods of Evaluation/Grading', 'CourseQueryText', 'QueryTextId_42','Update9'),
('Texts & Course Reading Materials', 'CourseQueryText', 'QueryTextId_41','Update10'),
('Distance Education', 'CourseQueryText', 'QueryTextId_40','Update11'),
('Course Description', 'Course', 'Description', 'Text'),
('Special Equipment, Facilities, etc.', 'GenericMaxText', 'TextMax12', 'Text'),
('Units & Hours', 'CourseDescription', 'GradeOptionId', 'Lookup')

declare @Fields table (
	FieldId int primary key,
	SectionId int,
	Action nvarchar(max),
	TabId int,
	TemplateId int,
	sortorder int,
	mtt int
);

insert into @Fields (FieldId,SectionId,Action,TabId,TemplateId,sortorder, mtt)
select msf.metaselectedfieldid,msf.MetaSelectedSectionId,rfc.Action,mss.MetaSelectedSectionId,mss.MetaTemplateId ,msf.RowPosition, mt.MetaTemplateTypeId
from MetaTemplate mt
inner join MetaSelectedSection mss
	on mt.MetaTemplateId = mss.MetaTemplateId
inner join MetaSelectedSection mss2
	on mss.MetaSelectedSectionId = mss2.MetaSelectedSection_MetaSelectedSectionId
inner join MetaSelectedField msf
	on mss2.MetaSelectedSectionId = msf.MetaSelectedSectionId
inner join MetaAvailableField maf
	on msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
inner join @FieldCriteria rfc
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName)
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/
Drop Table if Exists #SeedIds
Create Table #SeedIds (row_num int,Id int)
;WITH x AS (SELECT n FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) v(n)),Numbers as(
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL))  as Id
FROM x ones, x tens, x hundreds--, x thousands, x tenthousands, x hundredthousands
)	Merge #SeedIds as t
	Using (
	  select Id from Numbers
	  )
	As s 
	on 1=0
	When not matched and s.Id < 100000 then
	insert (Id)
	Values(s.Id);

	delete from #SeedIds where exists (Select Id from MetaForeignKeyCriteriaClient mfkcc where mfkcc.Id = #SeedIds.Id)

	Merge #SeedIds as t
	using (
			SELECT  ROW_NUMBER() OVER (
			ORDER BY Id
		   ) row_num, Id from #SeedIds
	)as s on s.Id = t.Id
	When  matched then Update
	Set t.row_num = s.row_num;
	Select * from #SeedIds Order by row_num asc

DECLARE @MAX int = (SELECT Id FROM #SeedIds WHERE row_num = 1)
DECLARE @MAX2 int = (SELECT Id FROM #SeedIds WHERE row_num = 2)
DECLARE @MAX3 int = (SELECT Id FROM #SeedIds WHERE row_num = 3)
DECLARE @MAX4 int = (SELECT Id FROM #SeedIds WHERE row_num = 4)
DECLARE @MAX5 int = (SELECT Id FROM #SeedIds WHERE row_num = 5)
DECLARE @MAX6 int = (SELECT Id FROM #SeedIds WHERE row_num = 6)
DECLARE @MAX7 int = (SELECT Id FROM #SeedIds WHERE row_num = 7)
DECLARE @MAX8 int = (SELECT Id FROM #SeedIds WHERE row_num = 8)
DECLARE @MAX9 int = (SELECT Id FROM #SeedIds WHERE row_num = 9)
DECLARE @MAX10 int = (SELECT Id FROM #SeedIds WHERE row_num = 10)
DECLARE @MAX11 int = (SELECT Id FROM #SeedIds WHERE row_num = 11)

SET QUOTED_IDENTIFIER OFF

DECLARE @CSQL NVARCHAR(MAX) = "
Select 0 AS Value,
FORMAT(TermStartDate, 'MM/dd/yyyy') AS Text
FROM CourseProposal AS cp
INNER JOIN Semester AS s on cp.SemesterId = s.Id
WHERE cp.CourseId = @EntityId
"

DECLARE @RSQL NVARCHAR(MAX) = "
DECLARE @CC DATETIME = (SELECT CourseDate FROM CourseDate WHERE CourseDateTypeId = 1 and CourseId = @EntityId)
DECLARE @BT DATETIME = (SELECT CourseDate FROM CourseDate WHERE CourseDateTypeId = 2 and CourseId = @EntityId)

Select DISTINCT 0 AS Value,
Concat(
	'<b>Curriculum Committee Approval Date:</b>',
		CASE
			WHEN @CC IS NOT NULL
				THEN FORMAT(@CC, 'MM/dd/yyyy')
				ELSE ''
			END
	,'<br>',
	'<b>Board of Trustees Approval Date:</b>', 
	CASE
			WHEN @BT IS NOT NULL
				THEN FORMAT(@BT, 'MM/dd/yyyy')
				ELSE ''
			END
	,'<br>'
) AS Text
FROM CourseDate AS cd
WHERE cd.CourseId = @EntityId
"

DECLARE @XSQL NVARCHAR(MAX) = "
select 0 as [Value]
, rs.[Text]
from (
    select @entityId as Value
    , dbo.ConcatWithSepOrdered_Agg('<br>', rto.SortOrder, rrq.RenderedRequisite) as [Text]
    from (
        select @entityId as CourseId
        , rt.Id as RequisiteTypeId 
        , rt.Title as RequisiteType
        ,	dbo.ConcatWithSepOrdered_Agg(space(1), coalesce(rqs.SortOrder, 0), coalesce(rqs.RequisiteRow, 'None')) as Requisites
        from RequisiteType rt
            left join (
                select cr.CourseId as CourseId
                , cr.RequisiteTypeId
                , concat(
                    s.subjectCode, 
                    case 
                        when s.subjectCode is not null then concat(space(1), c.coursenumber)
                        else c.coursenumber
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
    '<b>',rqs.RequisiteType, '</b>: ',
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
"

DECLARE @ZSQL NVARCHAR(MAX) = "
DECLARE @TEXT1 NVARCHAR(100) = '<b>Objectives: In the process of completing this course, students will:</b><ol><li>'
DECLARE @TEXT2 NVARCHAR(100) = '</ol><br><b>Student Learning Outcomes: Upon completion of this course, students will be able to:</b>'

DECLARE @OBJ NVARCHAR(MAX) = (SELECT  dbo.ConcatWithSep_Agg('<li>', co.Text) FROM CourseObjective AS co WHERE co.CourseId = @EntityId)
DECLARE @OUT NVARCHAR(MAX) = (SELECT dbo.ConcatWithSep_Agg('<li>', co.OutcomeText) FROM CourseOutcome AS co WHERE co.CourseId = @EntityId)

SELECT DISTINCT 0 AS Value,
CONCAT(@TEXT1,
	CASE
		WHEN @OBJ IS NULL THEN 'None'
		ELSE @OBJ
	END,
@TEXT2, '<ol><li>',
		CASE
		WHEN @OUT IS NULL THEN 'None'
		ELSE @OUT
	END,
	'</ol>'
) AS Text
"

DECLARE @ASQL NVARCHAR(MAX) = "
SELECT 0 AS Value,CONCAT(
'<p>Methods of Instruction  may include but are not limited to:</p>',
dbo.ConcatWithSepOrdered_Agg('<br>', it.SortOrder, It.Title),
CASE 
	WHEN LEN(cam.OtherMethods) > 0
	THEN CONCAT('<br>',cam.OtherMethods)
	ELSE ''
END
) AS Text
FROM Course AS C
INNER JOIN CourseInstructionType AS cit on cit.CourseId = c.Id
INNER JOIN InstructionType AS It on cit.InstructionTypeId = It.Id
LEFT JOIN CourseArrangedMethodOfInstruction AS cam on cam.CourseId = C.Id
WHERE cit.CourseId = @EntityId
group by cam.OtherMethods
"

DECLARE @DSQL NVARCHAR(MAX) = "
DECLARE @LIST NVARCHAR(MAX) = (SELECT dbo.ConcatWithSepOrdered_Agg('<br>', d.SortOrder, d.Title) FROM CourseDesignation AS cd INNER JOIN Designation AS d on cd.DesignationId = d.Id WHERE cd.CourseId = @EntityId)

SELECT 0 AS Value,
CONCAT(
@LIST,
CASE
	WHEN LEN(gt.TextMax04) > 0
	THEN CONCAT('<br>',gt.TextMax04)
	ELSE ''
END 
) AS Text
FROM GenericMaxText AS gt where gt.CourseId = @EntityId
"

DECLARE @TSQL NVARCHAR(MAX) = "
SELECT 0 AS Value,
CONCAT('<b>',em.Title, '</b> ',
	CASE WHEN LEN(cem.Rationale) > 0
	THEN CONCAT('<br>',cem.Rationale)
	ELSE ''
	END
	) AS Text
FROM CourseEvaluationMethod AS cem
INNER JOIN EvaluationMethod AS em on cem.EvaluationMethodId = em.Id
WHERE cem.CourseId = @EntityId
order by em.Id
"

DECLARE @NSQL NVARCHAR(MAX) = "
SELECT DISTINCT 
    0 AS Value,
    CONCAT(
        '<b>Course is approved for Distance Education:</b><br>', 
        (
            SELECT dbo.ConcatWithSep_Agg('<br>', d.Description)
            FROM (
                SELECT DISTINCT dej.Description
                FROM CourseDistanceEducationJustification AS cdej
                INNER JOIN DistanceEducationJustification AS dej ON cdej.DistanceEducationJustificationId = dej.Id
                WHERE cdej.CourseId = @EntityId
                    AND dej.Active = 1
                    AND cdej.Active = 1
            ) AS d
        ),
        CASE
            WHEN cmd.CourseId IS NOT NULL THEN CONCAT(
                '<br><b>Mode(s) of delivery</b><br>', 
                (
                    SELECT dbo.ConcatWithSep_Agg('<br>', dm.Description)
                    FROM (
                        SELECT DISTINCT dm.Description
                        FROM CourseDistanceEducationDeliveryMethod AS cmd
                        INNER JOIN DeliveryMethod AS dm ON cmd.DeliveryMethodId = dm.Id
                        WHERE cmd.CourseId = @EntityId
                    ) AS dm
                )
            )
            ELSE ''
        END
    ) AS Text
FROM Course AS c
INNER JOIN CourseDistanceEducationDeliveryMethod AS cmd ON cmd.CourseId = c.Id
WHERE c.Id = @EntityId;
"

DECLARE @YSQL NVARCHAR(MAX) = "
DECLARE @TABLE TABLE (gee NVARCHAR(MAX))
INSERT INTO @TABLE
SELECT 
CONCAT('<b>', ge.Title, '</b>', '<br>', dbo.ConcatWithSep_Agg('<br>', gee.Title)
)
FROM Course AS c
LEFT JOIN CourseGeneralEducation AS cge on cge.CourseId = c.Id
LEFT JOIN GeneralEducationElement AS gee on cge.GeneralEducationElementId = gee.Id
LEFT JOIN GeneralEducation AS ge on gee.GeneralEducationId = ge.Id
WHERE c.Id = @EntityId
group by ge.Title

DECLARE @CID TABLE (CID NVARCHAR(MAX))
INSERT INTO @CID
SELECT
c.ClientCode
FROM Course AS c
WHERE c.Id = @EntityId

SELECT 0 AS Value,
	CASE
		WHEN gee IS NOT NULL 
			THEN  gee
		ELSE ''
	END
AS Text FROM @TABLE
UNION
SELECT 1 AS Value,
CONCAT('<b> C-ID:</b>', CID)AS Text FROM @CID
"

DECLARE @ISQL NVARCHAR(MAX) = "
DECLARE @CombinedData TABLE (Category NVARCHAR(50), Details NVARCHAR(MAX))

INSERT INTO @CombinedData (Category, Details)
SELECT 'Textbooks' AS Category, CONCAT('<ol><li>', COALESCE(dbo.ConcatWithSep_Agg('<li>', t.Details), 'None'), '</ol>')
FROM (
    SELECT CONCAT(ct.Author, ', ', ct.Title,
            CASE
                WHEN ct.Edition IS NOT NULL THEN CONCAT(', ', ct.Edition)
                ELSE ''
            END,
            CASE
                WHEN ct.City IS NOT NULL THEN CONCAT(', ', ct.City)
                ELSE ''
            END,
            CASE
                WHEN ct.Publisher IS NOT NULL THEN CONCAT(', ', ct.Publisher)
                ELSE ''
            END,
            CASE
                WHEN ct.CalendarYear IS NOT NULL THEN CONCAT(', ', ct.CalendarYear)
                ELSE ''
            END) AS Details
    FROM CourseTextbook AS ct
    WHERE ct.CourseId = @EntityId
) AS t

UNION ALL

SELECT 'Manuals' AS Category, CONCAT('<ol><li>', COALESCE(dbo.ConcatWithSep_Agg('<li>', m.Details), 'None'), '</ol>')
FROM (
    SELECT CONCAT(cm.Author, ', ', cm.Title,
            CASE
                WHEN cm.CalendarYear IS NOT NULL THEN CONCAT(', ', cm.CalendarYear)
                ELSE ''
            END,
            CASE
                WHEN cm.Publisher IS NOT NULL THEN CONCAT(', ', cm.Publisher)
                ELSE ''
            END) AS Details
    FROM CourseManual AS cm
    WHERE cm.CourseId = @EntityId
) AS m

UNION ALL

SELECT 'Periodicals' AS Category, CONCAT('<ol><li>', COALESCE(dbo.ConcatWithSep_Agg('<li>', p.Details), 'None'), '</ol>')
FROM (
    SELECT CONCAT(cp.Title,
            CASE
                WHEN cp.Author IS NOT NULL THEN CONCAT(', ', cp.Author)
                ELSE ''
            END,
            CASE
                WHEN cp.PublicationName IS NOT NULL THEN CONCAT(', ', cp.PublicationName)
                ELSE ''
            END,
            CASE
                WHEN cp.PublicationYear IS NOT NULL THEN CONCAT(', ', cp.PublicationYear)
                ELSE ''
            END,
            CASE
                WHEN cp.Volume IS NOT NULL THEN CONCAT(', ', cp.Volume)
                ELSE ''
            END) AS Details
    FROM CoursePeriodical AS cp
    WHERE cp.CourseId = @EntityId
) AS p

UNION ALL

SELECT 'Software' AS Category, CONCAT('<ol><li>', COALESCE(dbo.ConcatWithSep_Agg('<li>', s.Details), 'None'), '</ol>')
FROM (
    SELECT CONCAT(cs.Title,
            CASE
                WHEN cs.Edition IS NOT NULL THEN CONCAT(', ', cs.Edition)
                ELSE ''
            END,
            CASE
                WHEN cs.Publisher IS NOT NULL THEN CONCAT(', ', cs.Publisher)
                ELSE ''
            END) AS Details
    FROM CourseSoftware AS cs
    WHERE cs.CourseId = @EntityId
) AS s

UNION ALL

SELECT 'Other' AS Category, CONCAT('<ol><li>', COALESCE(dbo.ConcatWithSep_Agg('<li>', o.Details), 'None'), '</ol>')
FROM (
    SELECT ct.TextOther AS Details
    FROM CourseTextOther AS ct
    WHERE ct.CourseId = @EntityId
) AS o

SELECT 0 AS Value,
       CONCAT('<b>', cd.Category, '</b>', cd.Details) AS Text
FROM @CombinedData AS cd
WHERE cd.Details IS NOT NULL
"

DECLARE @PSQL NVARCHAR(MAX) = "
SELECT 0 AS Value,CONCAT('<b>Units:</b>',
CASE
	WHEN cd.MaxCreditHour IS NOT NULL AND cd.MaxCreditHour > cd.MinCreditHour
		THEN CONCAT(FORMAT(cd.MinCreditHour, '##0.00#'), ' - ', FORMAT(cd.MaxCreditHour, '##0.00#'))
	ELSE FORMAT(cd.MinCreditHour, '##0.00#')
END,
'<br><b>Number of Weeks:</b> 18',
CASE
	WHEN cd.MaxLectureHour IS NOT NULL AND cd.MaxLectureHour > cd.MinLectureHour
		THEN CONCAT('<br><b>Lecture Hours Per Week:</b>', FORMAT(cd.MinLectureHour, '##0.00#'), ' - ', FORMAT(cd.MaxLectureHour, '##0.00#'))
	ELSE CONCAT('<br><b>Lecture Hours Per Week:</b>',FORMAT(cd.MinLectureHour, '##0.00#'))
END,
CASE
	WHEN cd.MaxLabHour IS NOT NULL AND cd.MaxLabHour > cd.MinLabHour
		THEN CONCAT('<br><b>Lab Hours Per Week:</b>', FORMAT(cd.MinLabHour, '##0.00#'), ' - ', FORMAT(cd.MaxLabHour, '##0.00#'))
	ELSE CONCAT('<br><b>Lab Hours Per Week:</b>',FORMAT(cd.MinLabHour, '##0.00#'))
END,
CASE
	WHEN cd.MaxOtherHour IS NOT NULL AND cd.MaxOtherHour > cd.MinOtherHour
		THEN CONCAT('<br><b>Activity Hours Per Week:</b>', FORMAT(cd.MinOtherHour, '##0.00#'), ' - ', FORMAT(cd.MaxOtherHour, '##0.00#'))
	ELSE CONCAT('<br><b>Activity Hours Per Week:</b>',FORMAT(cd.MinOtherHour, '##0.00#'))
END,
CASE
	WHEN cd.MaxContactHoursOther IS NOT NULL AND cd.MaxContactHoursOther > cd.MinContactHoursOther
		THEN CONCAT('<br><b>Total In-Class Contact Hours:</b>', FORMAT(cd.MinContactHoursOther, '##0.00#'), ' - ', FORMAT(cd.MaxContactHoursOther, '##0.00#'))
	ELSE CONCAT('<br><b>Total In-Class Contact Hours:</b>',FORMAT(cd.MinContactHoursOther, '##0.00#'))
END,
CASE
	WHEN cd.MaxFieldHour IS NOT NULL AND cd.MaxFieldHour > cd.MinFieldHour
		THEN CONCAT('<br><b>Total Out-of-Class Contact Hours:</b>', FORMAT(cd.MinFieldHour, '##0.00#'), ' - ', FORMAT(cd.MaxFieldHour, '##0.00#'))
	ELSE CONCAT('<br><b>Total Out-of-Class Contact Hours:</b>',FORMAT(cd.MinFieldHour, '##0.00#'))
END,
CASE
	WHEN cd.MaxFieldHour + cd.MaxContactHoursOther IS NOT NULL AND cd.MaxFieldHour + cd.MaxContactHoursOther > cd.MinFieldHour + cd.MaxContactHoursOther
		THEN CONCAT('<br><b>Total Student Learning Hours (Contact Hours):</b>', FORMAT(cd.MinFieldHour + cd.MinContactHoursOther, '##0.00#'), ' - ', FORMAT(cd.MaxFieldHour + cd.MaxContactHoursOther, '##0.00#'))
	ELSE CONCAT('<br><b>Total Student Learning Hours (Contact Hours):</b>',FORMAT(cd.MinFieldHour + cd.MinContactHoursOther, '##0.00#'))
END
) AS Text
FROM Course AS c
LEFT JOIN CourseDescription AS cd on cd.CourseId = c.Id
WHERE c.Id = @EntityId
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'CourseQueryText', 'Id', 'Title', @CSQL, @CSQL, 'Order By SortOrder', 'Semester Date', 2),
(@MAX2, 'CourseQueryText', 'Id', 'Title', @RSQL, @RSQL, 'Order By SortOrder', 'Approval Dates', 2),
(@MAX3, 'CourseQueryText', 'Id', 'Title', @XSQL, @XSQL, 'Order By SortOrder', 'Requisites', 2),
(@MAX4, 'CourseQueryText', 'Id', 'Title', @ZSQL, @ZSQL, 'Order By SortOrder', 'Objectives and Outcomes', 2),
(@MAX5, 'CourseQueryText', 'Id', 'Title', @ASQL, @ASQL, 'Order By SortOrder', 'Methods of instruciton', 2),
(@MAX6, 'CourseQueryText', 'Id', 'Title', @DSQL, @DSQL, 'Order By SortOrder', 'Homework', 2),
(@MAX7, 'CourseQueryText', 'Id', 'Title', @TSQL, @TSQL, 'Order By SortOrder', 'Evalution Methods', 2),
(@MAX8, 'CourseQueryText', 'Id', 'Title', @NSQL, @NSQL, 'Order By SortOrder', 'Distance Ed', 2),
(@MAX9, 'CourseQueryText', 'Id', 'Title', @YSQL, @YSQL, 'Order By SortOrder', 'Gen Ed', 2),
(@MAX10, 'CourseQueryText', 'Id', 'Title', @ISQL, @ISQL, 'Order By SortOrder', 'Textbooks', 2),
(@MAX11, 'CourseQueryText', 'Id', 'Title', @PSQL, @PSQL, 'Order By SortOrder', 'Units', 2)

UPDATE MetaSelectedField
SET DisplayName = NULL
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Text'
)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX
, DefaultDisplayType = 'QueryText'
, MetaPresentationTypeId = 103
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update'
)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX2
, DefaultDisplayType = 'QueryText'
, MetaPresentationTypeId = 103
, DisplayName = NULL
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'UpdateHalf'
)

Update MetaSelectedSection
SET MetaSectionTypeId = 18
, MetaBaseSchemaId = 89
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = 'Update2'
)

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 2525
, DefaultDisplayType = 'TelerikCombo'
, MetaPresentationTypeId = 33
, FieldTypeId = 5
, DisplayName = NULL
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update2'
)

UPDATE MetaSelectedField
SET DisplayName = 'SCCCD Course Numbering<br><p style="font-weight: normal;">1-99 Associate degree applicable, transferable
<br>100-199 Associate degree applicable, non-transferable
<br>200-299 Non-degree, non-transferable
<br>300-399 Noncredit</p>'
WHERE MetaSelectedFieldId in (
	SELECT msf.MetaSelectedFieldId FROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	INNER JOIN @Fields AS f on mss.MetaSelectedSection_MetaSelectedSectionId = f.TabId
	WHERE mss.SortOrder = 2
	AND msf.RowPosition = 1
)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX3
, DefaultDisplayType = 'QueryText'
, MetaPresentationTypeId = 103
, DisplayName = NULL
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update4'
)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX4
, DefaultDisplayType = 'QueryText'
, MetaPresentationTypeId = 103
, DisplayName = NULL
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update6'
)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX5
, DefaultDisplayType = 'QueryText'
, MetaPresentationTypeId = 103
, DisplayName = NULL
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update7'
)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX6
, DefaultDisplayType = 'QueryText'
, MetaPresentationTypeId = 103
, DisplayName = NULL
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update8'
)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX7
, DefaultDisplayType = 'QueryText'
, MetaPresentationTypeId = 103
, DisplayName = NULL
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update9'
)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX8
, DefaultDisplayType = 'QueryText'
, MetaPresentationTypeId = 103
, DisplayName = NULL
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update11'
)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX9
, DefaultDisplayType = 'QueryText'
, MetaPresentationTypeId = 103
, DisplayName = NULL
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update5'
)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX10
, DefaultDisplayType = 'QueryText'
, MetaPresentationTypeId = 103
, DisplayName = NULL
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update10'
)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX11
, DefaultDisplayType = 'QueryText'
, MetaPresentationTypeId = 103
, DisplayName = NULL
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update3'
)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = 130
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Lookup'
)

UPDATE MetaReport
SET ReportAttributes = '{"isPublicReport":false,"reportTemplateId":29}'
WHERE Id = 362
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback
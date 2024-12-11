USE [sdccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17901';
DECLARE @Comments nvarchar(Max) = 
	'Add text to COR when course is non-credit';
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
DECLARE @Sec int = (SELECT mss.MetaSelectedSectionId FROM MetaSelectedSection AS mss
INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
INNER JOIN MetaSelectedField As msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE mtt.MetaTemplateTypeId = 4
and msf.MetaAvailableFieldId = 8986)

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

SET QUOTED_IDENTIFIER OFF

DECLARE @CSQL NVARCHAR(MAX) = "
SELECT 0 AS Value,
CASE WHEN cb.CB04Id = 3
		THEN 
		'<div>
    <label class=""iq-data-field-label field-label"">Institutional Student Learning Outcomes</label>
    <ol>
        <li>Social Responsibility
            <p>SDCCE students demonstrate interpersonal skills by learning and working cooperatively in a diverse environment.</p>
        </li>
        <li>Effective Communication
            <p>SDCCE students demonstrate effective communication skills.</p>
        </li>
        <li>Critical Thinking
            <p>SDCCE students critically process information, make decisions, and solve problems independently or cooperatively.</p>
        </li>
        <li>Personal and Professional Development
            <p>SDCCE students pursue short term and life-long learning goals, mastering necessary skills and using resource management and self-advocacy skills to cope with changing situations in their lives.</p>
        </li>
        <li>Diversity, Equity, Inclusion, Anti-racism and Access
            <p>SDCCE students critically and ethically engage with local and global issues using principles of equity, civility, and compassion as they apply their knowledge and skills: exhibiting awareness, appreciation, respect, and advocacy for diverse individuals, groups, and cultures.</p>
        </li>
    </ol>
</div>'
ELSE ''
END AS Text
FROM Course AS c LEFT JOIN CourseCBCode AS cb on cb.CourseId = c.Id where c.Id = @EntityId
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'Course', 'Id', 'Title', @CSQL, @CSQL, 'Order By SortOrder', 'HelpText When Course is non-credit', 2)

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
values
(
NULL, -- [DisplayName]
8972, -- [MetaAvailableFieldId]
@Sec, -- [MetaSelectedSectionId]
1, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
17, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'QueryText', -- [DefaultDisplayType]
1, -- [MetaPresentationTypeId]
100, -- [Width]
2, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
1, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
5, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
@MAX, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
)

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = 'SELECT CASE WHEN cb.CB04Id = 3 THEN CONCAT
	(
	''<label class="field-label"><div class="c-labels-container"><div class="c-labels" id="c-title-label"> COURSE TITLE:</div><div class="c-labels" id="c-units-label">&nbsp;</div></div></label><div class = "title-units-container">'',
	''<div class = "title-units" id = "c-title">'', 
	c.Title,
	''</div><div class = "title-units" id = "c-units"><br></div></div>&nbsp;<br>'', COALESCE(g.Description, '''')) ELSE CONCAT
	(
	''<label class="field-label"><div class="c-labels-container"><div class="c-labels" id="c-title-label"> COURSE TITLE:</div><div class="c-labels" id="c-units-label">Units:</div></div></label><div class = "title-units-container">'',
	''<div class = "title-units" id = "c-title">'', 
	c.Title,
	''</div>'',
	''<div class = "title-units" id = "c-units">'',
	CASE 
		WHEN cd.MaxCreditHour IS NOT NULL AND cd.MaxCreditHour <> 0
		THEN CONCAT
			(
			FORMAT(cd.MinCreditHour , ''###.###''), 
			'' - '', 
			FORMAT(cd.MaxCreditHour, ''###.###'')
			)
		ELSE FORMAT(cd.MinCreditHour, ''###.###'')
	END,
	''<br>'',
	COALESCE(g.Description, ''''),
	''</div></div>''
	) END AS Text
FROM Course c
	INNER JOIN CourseCBCode AS cb on cb.CourseId = c.Id
	INNER JOIN CourseDescription cd ON cd.CourseId = c.Id
	LEFT JOIN GradeOption AS g on cd.GradeOptionId = g.Id
WHERE c.Id = @entityId'
, ResolutionSql = 'SELECT CASE WHEN cb.CB04Id = 3 THEN CONCAT
	(
	''<label class="field-label"><div class="c-labels-container"><div class="c-labels" id="c-title-label"> COURSE TITLE:</div><div class="c-labels" id="c-units-label">&nbsp;</div></div></label><div class = "title-units-container">'',
	''<div class = "title-units" id = "c-title">'', 
	c.Title,
	''</div><div class = "title-units" id = "c-units"><br></div></div>&nbsp;<br>'', COALESCE(g.Description, '''')) ELSE CONCAT
	(
	''<label class="field-label"><div class="c-labels-container"><div class="c-labels" id="c-title-label"> COURSE TITLE:</div><div class="c-labels" id="c-units-label">Units:</div></div></label><div class = "title-units-container">'',
	''<div class = "title-units" id = "c-title">'', 
	c.Title,
	''</div>'',
	''<div class = "title-units" id = "c-units">'',
	CASE 
		WHEN cd.MaxCreditHour IS NOT NULL AND cd.MaxCreditHour <> 0
		THEN CONCAT
			(
			FORMAT(cd.MinCreditHour , ''###.###''), 
			'' - '', 
			FORMAT(cd.MaxCreditHour, ''###.###'')
			)
		ELSE FORMAT(cd.MinCreditHour, ''###.###'')
	END,
	''<br>'',
	COALESCE(g.Description, ''''),
	''</div></div>''
	) END AS Text
FROM Course c
	INNER JOIN CourseCBCode AS cb on cb.CourseId = c.Id
	INNER JOIN CourseDescription cd ON cd.CourseId = c.Id
	LEFT JOIN GradeOption AS g on cd.GradeOptionId = g.Id
WHERE c.Id = @entityId'
WHERE Id = 129

UPDATE MetaSelectedField
sET DisplayName = NULL
WHERE MetaForeignKeyLookupSourceId = 129

DECLARE @CID int = (
SELECT msf.MetaSelectedFieldId FROM MetaSelectedSection AS mss
INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
INNER JOIN MetaSelectedField As msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE mtt.MetaTemplateTypeId = 4
and msf.MetaAvailableFieldId = 2672
and mt.Active = 1
)

INSERT INTO MetaSelectedFieldAttribute
(Name, Value ,MetaSelectedFieldId)
VALUES
('ShouldDisplayCheckQuery', 'SELECT CAST(CASE
	WHEN ISNULL(Cb.CB04Id, 1) <> 3
	THEN 1
	ELSE 0
END as bit) as ShouldDisplay, null as JsonAttributes
FROM Course AS c
LEFT JOIN CourseCBCode AS cb on cb.CourseId = c.Id
WHERE c.Id = @EntityId', @CID)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT Mss.MetaTemplateId FROM MetaSelectedSection AS mss
	WHERE Mss.MetaSelectedSectionId = @Sec
)
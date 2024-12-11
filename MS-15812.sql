USE [hancockcollege];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15812';
DECLARE @Comments nvarchar(Max) = 
	'Update Course Outline report and make new PRogram Outline report';
DECLARE @Developer nvarchar(50) = 'Nathan Westergard';
DECLARE @ScriptTypeId int = 2; /*  Default 1 is Support,  
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
Declare @clientId int =1, -- SELECT Id, Title FROM Client 
	@Entitytypeid int =2; -- SELECT * FROM EntityType (1 = course, 2 = program, 6 = module)

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
		AND mtt.MetaTemplateTypeId in (38)		--comment back in if just doing some of the mtt's
/********************** Changes go HERE **************************************************/
DECLARE @TAB1 int = (
	SELECT mss.MEtaSelectedSectionId FROM MetaSelectedSection as mss
	INNER JOIN @templateId AS t on mss.MetaTemplateId = t.Id
	WHERE mss.SectionName = 'New Section 1'
)

DECLARE @TAB2 int = (
	SELECT mss.MEtaSelectedSectionId FROM MetaSelectedSection as mss
	INNER JOIN @templateId AS t on mss.MetaTemplateId = t.Id
	WHERE mss.SectionName = 'New Section 2'
)

DECLARE @TAB3 int = (
	SELECT mss.MEtaSelectedSectionId FROM MetaSelectedSection as mss
	INNER JOIN @templateId AS t on mss.MetaTemplateId = t.Id
	WHERE mss.SectionName = 'Program Requirements'
)

DECLARE @Sec1 int = (
	SELECT mss2.MEtaSelectedSectionId FROM MetaSelectedSection as mss
	INNER JOIN @templateId AS t on mss.MetaTemplateId = t.Id
	INNER JOIN MetaSelectedSection AS mss2 on mss2.MetaSelectedSection_MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE mss.SectionName = 'New Section 1'
)

DECLARE @Sec2 int = (
	SELECT mss2.MEtaSelectedSectionId FROM MetaSelectedSection as mss
	INNER JOIN @templateId AS t on mss.MetaTemplateId = t.Id
	INNER JOIN MetaSelectedSection AS mss2 on mss2.MetaSelectedSection_MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE mss.SectionName = 'New Section 2'
)

DECLARE @Sec3 int = (
	SELECT mss2.MEtaSelectedSectionId FROM MetaSelectedSection as mss
	INNER JOIN @templateId AS t on mss.MetaTemplateId = t.Id
	INNER JOIN MetaSelectedSection AS mss2 on mss2.MetaSelectedSection_MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE mss.SectionName = 'Program Requirements'
)

UPDATE MetaSelectedSection
SET DisplaySectionName = 0
WHERE MetaSelectedSectionId in (
@TAB1, @TAB2
)

UPDATE MetaSelectedSection
SET MetaSectionTypeId = 15
WHERE MetaSelectedSectionId in (
@TAB1, @TAB2, @TAB3
)

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

SET QUOTED_IDENTIFIER OFF

DECLARE @CSQL NVARCHAR(MAX) = "
DECLARE @TABLE TABLE (outcome nvarchar(max), pid int)
INSERT INTO @TABLE
SELECT po.Outcome, po.ProgramId
FROM ProgramOutcome AS po
where po.ProgramId = @EntityId
order by SortOrder

SELECT 0 AS Value,
CASE 
	WHEN (SELECT top 1 pid FROM @TABLE) IS NULL
	THEN 'There are no outcomes available.'
	ELSE
CONCAT(
'<b>The graduate of the ', at.Title, ' in ', p.Title, ' will:</b><br><ul><li>',
dbo.ConcatWithSep_Agg('<li>', t.outcome)
)
END AS Text
FROM Program As p
INNER JOIN AwardType AS at on p.AwardTypeId = at.Id
LEFT JOIN @TABLE AS t on p.Id = t.pid
where p.Id = @EntityId
group by at.Title, p.Title
"

DECLARE @SQL2 NVARCHAR(MAX) = "
		declare @isNonCredit bit = (
			select
				case
					when p.AwardTypeId in (
						select Id
						from AwardType
						where Title like '%Certificate of Competency%'
						or Title like '%Certificate of Completion%'
					)
						then 1
					else 0
				end
			from Program as p
			where p.Id = @entityId
		);

		declare @queryString nvarchar(max) = '
			declare @extraDetailsDisplay StringPair;

			drop table if exists #renderedInjections;

			create table #renderedInjections (
				TableName sysname,
				Id int,
				InjectionType nvarchar(255),
				RenderedText nvarchar(max),
				primary key (TableName, Id, InjectionType)
			);

			declare @blockTag nvarchar(10) = ''div'';
			declare @dataElementTag nvarchar(10) = ''span'';
			declare @identifierWrapperTag nvarchar(5) = ''sup'';
			declare @labelTag nvarchar(10) = ''span'';
			declare @listTag nvarchar(10) = ''ul'';
			declare @listItemTag nvarchar(10) = ''li'';

			declare @classAttrib nvarchar(10) = ''class'';

			declare @space nvarchar(5) = '' '';
			declare @empty nvarchar(1) = '''';

			declare @distanceEdIdentifierWrapperClass nvarchar(100) = ''course-approved-for-de-identifier'';
			declare @distanceEdIdentifierText nvarchar(10) = ''DE'';

			declare @minCrossListingDate datetime = (
				select min(clc.AddedOn)
				from CrossListingCourse clc
			);

			--select @isNonCredit;

			insert into #renderedInjections (TableName, Id, InjectionType, RenderedText)
			select
				''ProgramSequence'' as TableName, ps.Id, ''CourseEntryLeftColumnReplacement'' as InjectionType,
				concat(
					dbo.fnHtmlOpenTag(@dataElementTag, concat(
						dbo.fnHtmlAttribute(@classAttrib, ''course-identifier''), @space,
						dbo.fnHtmlAttribute(''data-course-id'', c.Id)
					)),
						dbo.fnHtmlOpenTag(@dataElementTag, concat(
							dbo.fnHtmlAttribute(@classAttrib, ''subject-code''), @space,
							dbo.fnHtmlAttribute(''title'', dbo.fnHtmlEntityEscape(s.Title))
						)),
							s.SubjectCode,
						dbo.fnHtmlCloseTag(@dataElementTag), @space,
						dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-number'')),
							c.CourseNumber,
						dbo.fnHtmlCloseTag(@dataElementTag),
					dbo.fnHtmlCloseTag(@dataElementTag),
					case
						when cde.IsApproved = 1 then
							concat(
								dbo.fnHtmlOpenTag(@identifierWrapperTag, dbo.fnHtmlAttribute(@classAttrib, @distanceEdIdentifierWrapperClass)),
									@distanceEdIdentifierText,
								dbo.fnHtmlCloseTag(@identifierWrapperTag)
							)
						else ''''
					end
				) as [Text]
			from ProgramSequence ps
			inner join Course c on ps.CourseId = c.Id
			inner join [Subject] s on c.SubjectId = s.Id
			left outer join CourseDistanceEducation cde on c.Id = cde.CourseId
			where (
				ps.ProgramId = @entityId
				or exists (
					select top 1 1
					from ProgramSequence ps2
					where ps2.ProgramId = @entityId
					and ps.Id = ps2.ReferenceId
				)
			);

			declare @clcourses table (Id int, RelatedCourseList nvarchar(max));

			insert into @clcourses
			select
				c.Id as Id,
				--dbo.ConcatWithSep_Agg('', '', concat(s.SubjectCode, @space, gcd.CourseNumber)) as clc_courses
				replace(dbo.fnTrimWhitespace(dbo.fn_GetCurrentCoursesInCrosslisting (c.Id, 0, 0, 0)), '' ,'', '','') as clc_courses
			from ProgramSequence ps
				inner join Course c on ps.CourseId = c.Id and c.IsCrossListed = 1
				cross apply fn_GetClcData(c.Id, 1, NULL) gcd
				inner join Crosslisting cl on gcd.CrossListingId = cl.Id
				inner join [Subject] s on s.Id = gcd.SubjectId
					where (
						ps.ProgramId = @entityId
						or exists (
							select top 1 1
							from ProgramSequence ps2
							where ps2.ProgramId = @entityId
							and ps.Id = ps2.ReferenceId
						)
					)		
			group by c.Id;

			insert into #renderedInjections (TableName, Id, InjectionType, RenderedText)
			select
				''ProgramSequence'' as TableName, ps.Id, ''CourseEntryMiddleColumn'' as InjectionType,
				case
					when c.IsCrossListed = 1
						then concat(
							dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, ''course-cross-listing-list'')),
								''<b>Same as: </b>'', @space,	clc.RelatedCourseList,
							dbo.fnHtmlCloseTag(@blockTag)
						)
					when rcl.RelatedCourseList is not null
						then concat(
							dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, ''course-cross-listing-list'')),
								''<b>Same as: </b>'', @space,	rcl.RelatedCourseList,
							dbo.fnHtmlCloseTag(@blockTag)
						)
				end as [Text]
			from ProgramSequence ps
				inner join Course c on ps.CourseId = c.Id
				inner join [Subject] sj on c.SubjectId = sj.Id
				left join @clcourses clc on clc.Id = c.Id
				outer apply (
					select crc.CourseId as Id, dbo.ConcatWithSep_Agg('', '', concat(crc.SubjectCode, '' '', crc.CourseNumber)) as RelatedCourseList
					from  (
						select
							top 100 percent drc.CourseId,
								rcs.SubjectCode,
								rc.CourseNumber
						from (
							/*Some courses have the same course cross-listed multiple times,
								so using a distinct is the easiest and most efficient way
								to remove the duplicates*/
							select distinct crc.CourseId, rc.Id as RelatedCourseId
							from CourseRelatedCourse crc
								inner join Course rc on rc.Id = coalesce(crc.Related_CourseId, crc.RelatedCourseId)
							where crc.CourseId = c.Id
								and c.IsCrossListed = 0
								and coalesce(c.CreatedOn, c.CreatedDate) < @minCrossListingDate
						) drc
							inner join Course rc on drc.RelatedCourseId = rc.Id
							inner join [Subject] rcs on rc.SubjectId = rcs.Id
			
						order by rcs.SubjectCode, rc.CourseNumber, rc.Id
					) crc
					group by crc.CourseId
				) rcl 
			where (
				ps.ProgramId = @entityId
				or exists (
					select top 1 1
					from ProgramSequence ps2
					where ps2.ProgramId = @entityId
					and ps.Id = ps2.ReferenceId
				)
			);
			
			insert into #renderedInjections (TableName, Id, InjectionType, RenderedText)
			select ''ProgramSequence'' as TableName
				, ps.Id
				, ''CourseEntryRightColumnReplacement''
				, case
					when @isNonCredit = 1
						then
							concat(
								format(cd.TeachingUnitsLecture, ''0.0'')
								, case
									when cd.Variable = 1
									or cyn.YesNo07Id = 1
										then 
											concat(
												''-''
												, format(cd.TeachingUnitsWork, ''0.0'')
											)
									else ''''
								end
							)
					else
						concat(
							format(cd.MinCreditHour, ''0.0'')
							, case
								when cd.Variable = 1
								or cyn.YesNo07Id = 1
									then 
										concat(
											''-''
											, format(cd.MaxCreditHour, ''0.0'')
										)
								else ''''
							end
						)
				end as RenderedText
			from ProgramSequence ps
				left join CourseDescription cd on ps.CourseId = cd.CourseId
				left join CourseYesNo cyn on cd.CourseId = cyn.CourseId
			where ps.ProgramId = @entityId;

			declare @courseLeftColumQuery nvarchar(max) =
			''select Id as [Value], RenderedText as [Text]
			from #renderedInjections ri
			where ri.TableName = ''''ProgramSequence'''' and ri.Id = @id
			and ri.InjectionType = ''''CourseEntryLeftColumnReplacement'''';
			'';

			declare @courseMiddleColumnQuery nvarchar(max) =
			''select Id as [Value], RenderedText as [Text]
			from #renderedInjections ri
			where ri.TableName = ''''ProgramSequence'''' and ri.Id = @id
			and ri.InjectionType = ''''CourseEntryMiddleColumn'''';
			'';

			declare @CourseUnitsOveride nvarchar(max) =''
				select Id as [Value]
					, RenderedText as [Text]
				from #renderedInjections ri
				where ri.TableName = ''''ProgramSequence''''
				and ri.Id = @id
				and ri.InjectionType = ''''CourseEntryRightColumnReplacement''''
				;
			'';
		
			insert into @extraDetailsDisplay (String1, String2)
			values
				(''CourseEntryLeftColumnReplacement'', @courseLeftColumQuery)
				, (''CourseEntryMiddleColumn'', @courseMiddleColumnQuery)
				, (''CourseEntryRightColumnReplacement'', @CourseUnitsOveride )
			;

			declare @config StringPair;

			insert into @config (String1, String2)
			values (''BlockItemTable'', ''ProgramSequence'');

			exec upGenerateGroupConditionsCourseBlockDisplay @entityId = @entityId, @extraDetailsDisplay = @extraDetailsDisplay, @config = @config, @outputTotal = 0, @combineBlocks = 0;

			drop table if exists #renderedInjections;
		';

		declare @serializedParameters nvarchar(max) = (
			select
				@entityId as id
				, json_query(
					concat(
						'[',
							dbo.fnGenerateBulkResolveQueryParameter('@entityId', @entityId, 'int'),
							',',
							dbo.fnGenerateBulkResolveQueryParameter('@isNonCredit', @isNonCredit, 'bool'),
						']'
					)
				) as [parameters]
			for json path
		);

		declare @serializedResults nvarchar(max);

		exec dbo.upBulkResolveQuery @queryString = @queryString, @serializedParameters = @serializedParameters, @serializedResults = @serializedResults output;

		--select @serializedResults;

		declare @results table ([Value] int, [Text] nvarchar(max), SortOrder int, MinimumCreditHours decimal, MaximumCreditHours decimal)
		insert into @results
		select @entityId as [Value]
			, out.[Text]
			, out.SortOrder
			, out.MinimumCreditHours
			, out.MaximumCreditHours
		from openjson(@serializedResults) with (
				ParamsParseSuccess bit '$.paramsParseSuccess',
				EntityResultSets nvarchar(max) '$.entityResultSets' as json,
				StatusMessages nvarchar(max) '$.statusMessages' as json
			) srr --srr = serialized results root
			outer apply openjson(srr.EntityResultSets) with (
				Id int '$.id',
				SortOrder int '$.sortOrder',
				QuerySuccess bit '$.querySuccess',
				ResultSets nvarchar(max) '$.resultSets' as json
			) ers
			outer apply openjson(ers.ResultSets) with (
				ResultSetNumber int '$.resultSetNumber',
				Results nvarchar(max) '$.results' as json
			) rs
			outer apply openjson(rs.Results) with (
				SerializedResult nvarchar(max) '$.serializedResult' as json,
				StatusMessages nvarchar(max) '$.statusMessages' as json
			) res
			outer apply openjson(res.SerializedResult) with (
				[Value] int '$.Value',
				[Text] nvarchar(max) '$.Text' ,
				SortOrder int '$.SortOrder',
				MinimumCreditHours decimal '$.MinimumCreditHours',
				MaximumCreditHours decimal '$.MaximumCreditHours'
			) out
		;

		DECLARE @OLD bit = (
		SELECT 
			CASE
				WHEN p.MetaTemplateId in (109, 108, 107, 95, 36, 35, 34, 24, 23, 22, 1)
				THEN 1
				ELSE 0
			END
			FROM Program AS p 
			WHERE p.Id = @EntityId
		)
		
		declare @tottalMin decimal(16,3) = (
			SELECT 
			CASE WHEN @OLD = 1
			THEN
				(SELECT SUM(CalcMin)
			FROM CourseOption WHERE ProgramId = @EntityId
			AND CalcMin IS NOT NULL)
			ELSE
				(SELECT SUM(CalcMin)
			FROM ProgramSequence WHERE ProgramId = @EntityId
			AND CalcMin IS NOT NULL)
			END
			FROM Program AS p
			WHERE p.Id = @EntityId
		);
		
		declare @tottalMax decimal (16,3) = (
			select sum(CalcMax) 
			from (
				select
					case
						when @isNonCredit = 0
							then CalcMax
						else coalesce(CalcMax, isNull(cd.TeachingUnitsWork, 0))
					end as CalcMax  
				from ProgramSequence ps 
					left join CourseDescription cd on ps.CourseId = cd.CourseId
				where ProgramId = @entityId
				and (Parent_Id is null
					or @IsNonCredit = 1
				)
			) s
		);

		insert into @results ([Value], [Text], SortOrder)
		select @entityId as [Value]
			, concat(
				'<div class=""row course-blocks-total-credits"">
					<div class=""col-xs-12 col-sm-12 col-md-12 full-width-column text-right text-end"">
						<span class=""grand-total-units-label"">'
							, case
								when @isNonCredit = 1
									then 'Total Hours'
								else 'Total'
							end
						, '</span>'
						, '<span class=""grand-total-units-label-colon"">:</span>'
						, '<span class=""grand-total-units-display"">'
							, format(@tottalmin, '0.0')
							, case
								when @tottalmin <> @tottalmax
								and @tottalmax <> 0
								and @tottalmax > @tottalMin
									then
										concat(
											'-<wbr>'
											, format(@tottalmax, '0.0')
										)
								else ''
							end
						, '</span>'
					, '</div>'
				, '</div>'
			) as [Text]
			, (
				select max(SortOrder)
				from @results
			) + 1
		;

		select [Value]
			, dbo.ConcatOrdered_Agg(SortOrder, CONCAT('<div style=""width: 170%"">', [Text], '</div>'), 1) as [Text]
		from @results
		group by [Value];
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'ProgramOutcome', 'Id', 'Title', @CSQL, @CSQL, 'Order By SortOrder', 'PLO list for program outline report', 2),
(@MAX2, 'CourseBlocks', 'Id', 'Title', @SQL2, @SQL2, 'Order By SortOrder', 'Course Blocks for Program Outline', 2)

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
values
(
'Title', -- [DisplayName]
1225, -- [MetaAvailableFieldId]
@Sec1, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Textbox', -- [DefaultDisplayType]
1, -- [MetaPresentationTypeId]
300, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
NULL, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
1, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
),
(
'Award Type', -- [DisplayName]
1100, -- [MetaAvailableFieldId]
@Sec1, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
1, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'TelerikCombo', -- [DefaultDisplayType]
33, -- [MetaPresentationTypeId]
150, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
NULL, -- [LabelStyleId]
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
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
)
,
(
'Description', -- [DisplayName]
1257, -- [MetaAvailableFieldId]
@Sec1, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
2, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Editor', -- [DefaultDisplayType]
26, -- [MetaPresentationTypeId]
100, -- [Width]
2, -- [WidthUnit]
120, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
NULL, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
1, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
)
,
(
'QueryText_02', -- [DisplayName]
9166, -- [MetaAvailableFieldId]
@Sec2, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'QueryText', -- [DefaultDisplayType]
103, -- [MetaPresentationTypeId]
300, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
NULL, -- [LabelStyleId]
0, -- [LabelVisible]
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
,
(
'QueryText_03', -- [DisplayName]
9167, -- [MetaAvailableFieldId]
@Sec3, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'QueryText', -- [DefaultDisplayType]
103, -- [MetaPresentationTypeId]
300, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
NULL, -- [LabelStyleId]
0, -- [LabelVisible]
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
@MAX2, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
)

DELETE FROM MetaReportTemplateType
WHERE MetaReportId = 107

DECLARE @reportId int = 494
DECLARE @reportTitle NVARCHAR(MAX) = 'Program Outline'
DECLARE @newMT int = (SELECT Id FROM @templateId)
DECLARE @entityId int = 2	--1-Courses, 2-Programs, 6-Modules
DECLARE @reportType int = 13		--2-CourseCompare, 4-CourseAllFields, 6-Program/ModuleCompare, 13-Program/ModuleAllFields

DECLARE @reportAttribute NVARCHAR(MAX) = concat('{"reportTemplateId":', @newMt,'}')

INSERT INTO MetaReport
(Id,Title,MetaReportTypeId,OutputFormatId,ReportAttributes)
VALUES
(@reportId, @reportTitle, @reportType, 5, @reportAttribute)


INSERT INTO MetaReportTemplateType
(MetaReportId, MetaTemplateTypeId, StartDate)
SELECT
	@reportId,
	mtt.MetaTemplateTypeId,
	GETDATE()
FROM MetaTemplateType AS mtt
INNER JOIN MetaTemplate AS mt
	on mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
WHERE mtt.EntityTypeId = @entityId
AND mt.Active = 1
AND mt.IsDraft = 0
AND mtt.Active = 1
AND mtt.IsPresentationView = 0

DECLARE @MAX3 INT = (SELECT MAX(ID) FROM MetaReportActionType) + 1

INSERT INTO MetaReportActionType
(Id, MetaReportId, ProcessActionTypeId)
VALUES
(@MAX3,@reportId,1),
(@MAX3 + 1,@reportId,2),
(@MAX3 + 2,@reportId,3)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId = @newMT

DECLARE @programId INT;
 
DROP Table IF Exists #calculationResults
create table #calculationResults
(
    TableName sysname,
    Id int,
    Min decimal(16, 3),
    Max decimal(16, 3),
    IsVariable bit
);
declare programCursor cursor fast_forward for
    select Id
from Program;
open programCursor;
fetch next from programCursor
    into @programId;
while @@fetch_status = 0
    begin;
    exec upCalculateNestedCourseBlockEntries @entityId = @programId, @resultTable = '#calculationResults';
    fetch next from programCursor
        into @programId;
end;
close programCursor;
deallocate programCursor;

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
SELECT
'Course Content', -- [DisplayName]
2556, -- [MetaAvailableFieldId]
mss.MEtaSelectedSectionId, -- [MetaSelectedSectionId]
1, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
2, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'CKEditor', -- [DefaultDisplayType]
25, -- [MetaPresentationTypeId]
100, -- [Width]
2, -- [WidthUnit]
250, -- [Height]
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
1, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM MetaSelectedSection As mss
INNER JOIN MetaTemplate As mt on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
INNER JOIN MetaSelectedField As msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE mtt.MetaTemplateTypeId = 31
and mt.Active = 1
AND mt.EndDate IS NULL
and msf.MetaAvailableFieldId = 3454
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (
select Distinct Id FROM @templateId
UNION
SELECT mt.MetaTemplateId FROM MetaSelectedSection As mss
INNER JOIN MetaTemplate As mt on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
INNER JOIN MetaSelectedField As msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE mtt.MetaTemplateTypeId = 31
and mt.Active = 1
AND mt.EndDate IS NULL
and msf.MetaAvailableFieldId = 3454
)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

commit
--rollback
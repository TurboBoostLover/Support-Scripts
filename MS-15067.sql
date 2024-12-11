USE [cuesta];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15067';
DECLARE @Comments nvarchar(Max) = 
	'Bunch of course updates';
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
DECLARE @FIELDS INTEGERS
INSERT INTO @FIELDS
SELECT msf.MetaSelectedFieldId
FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaSelectedSection AS mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
INNER JOIN MetaTemplate AS mt on mss2.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE mtt.MetaTemplateTypeId = 9
AND mss2.SectionName = 'Codes/Dates'

UPDATE MetaSelectedField
SET ReadOnly = 0
WHERE MetaSelectedFieldId in (
	SELECT * FROM @FIELDS
)

INSERT INTO MetaSelectedFieldRolePermission
(MetaSelectedFieldId, AccessRestrictionType, RoleId)
SELECT * , 2, 1
FROM @FIELDS
UNION
SELECT * , 1, 4
FROM @FIELDS

UPDATE MetaSelectedSection
SET SectionName = 'Requisite Course SLO''s'
WHERE MetaSelectedSectionId in (
	SELECT mss.MEtaSelectedSectionId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaAvailableFieldId = 922
)

UPDATE OutputTemplateClient 
SET TemplateQuery = '
declare 
	  @hoursScale0 int = 0
	, @hoursScale1 int = 1
	, @hoursScale2 int = 2
	, @hoursScale3 int = 3
	, @truncateInsteadOfRound int = 0
;

declare 
	  @hoursDecimalFormat0 nvarchar(10) = concat(''F'', @hoursScale0)
	, @hoursDecimalFormat1 nvarchar(10) = concat(''F'', @hoursScale1)
	, @hoursDecimalFormat2 nvarchar(10) = concat(''F'', @hoursScale2)
	, @hoursDecimalFormat3 nvarchar(10) = concat(''F'', @hoursScale3)
	, @empty nvarchar(1) = ''''
	, @space nvarchar(5) = '' ''
	, @2space nvarchar(5) = ''&nbsp;''
	, @beginParen nvarchar(5) = ''(''
	, @endParen nvarchar(5) = '')''
	, @newLine nvarchar(5) = ''
	''
	, @Colon nvarchar(5) = '':''
	, @classAttrib nvarchar(10) = ''class''
	, @titleAttrib nvarchar(10) = ''title''
	, @openComment nvarchar(10) = ''<!-- ''
	, @closeComment nvarchar(10) = '' -->''
	, @dash nvarchar(5) = ''—''
	, @Break nvarchar(5) = ''<br>''
;

declare @elementTags table (
	Id int,
	ElementTitle nvarchar(255) unique nonclustered,
	ElementTag nvarchar(10)
);

insert into @elementTags (Id, ElementTitle, ElementTag)
values
(1, ''SummaryWrapper'', ''div''),
(2, ''Row'', ''div''),
(3, ''Column'', ''div''),
(4, ''DataElement'', ''span''),
(5, ''Block'', ''div''),
(6, ''Label'', ''b''),
(7, ''Spacer'', ''br''),
(8, ''BoldDataElement'', ''b''),
(9, ''SecondaryLabel'', ''u''),
(10, ''ItalicElement'',''i'')
;

declare
	--The tag name to use for the group wrappers
	@summaryWrapperTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = ''SummaryWrapper''
)
,
--The tag name to use for the row wrappers
@rowTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = ''Row''
)
,
--The tag name to use for the column wrappers
@columnTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = ''Column''
)
,
--The tag name to use for the wrappers of the individual data elements inside the columns
@dataElementTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = ''DataElement''
)
,
--The tag name to use for generic layout blocks
@blockTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = ''Block''
)
,
--The tag name to use for wrapping labels
@labelTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = ''Label''
)
,
--The tag name for elements to insert vertical blank lines between other elements
@spacerTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = ''Spacer''
)
,
--The tag name to use for wrappers around invidual data elements that should be bolded by default
--This allows for bolding of elements w/o having to edit the CSS
@boldDataElementTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = ''BoldDataElement''
)
,
--The tag name for secondary labels; ones that need a different formatting than the primary labels
@secondaryLabelTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = ''SecondaryLabel''
),
@italicDataElementTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = ''ItalicElement''
)
;

declare @elementClasses table (
	Id int primary key,
	ClassSetTitle nvarchar(255) unique nonclustered,
	Wrapper nvarchar(255),
	LeftColumn nvarchar(255),
	MiddleColumn nvarchar(255),
	RightColumn nvarchar(255),
	FullWidthColumn nvarchar(255),

	--Computed full class attributes
	WrapperAttrib as coalesce(''class="'' + Wrapper + ''"'', ''''),
	LeftColumnAttrib as coalesce(''class="'' + LeftColumn + ''"'', ''''),
	MiddleColumnAttrib as coalesce(''class="'' + MiddleColumn + ''"'', ''''),
	RightColumnAttrib as coalesce(''class="'' + RightColumn + ''"'', ''''),
	FullWidthColumnAttrib as coalesce(''class="'' + FullWidthColumn + ''"'', '''')
);

insert into @elementClasses (Id, ClassSetTitle, Wrapper, LeftColumn, MiddleColumn, RightColumn, FullWidthColumn)
values
(1, ''ThreeColumn'', ''row'', ''col-xs-3 col-sm-3 col-md-1 text-left left-column'', ''col-xs-6 col-sm-6 col-md-10 text-left middle-column'', ''col-xs-3 col-sm-3 col-md-1 text-right right-column'', null),
(2, ''TwoColumnShorterRight'', ''row'', ''col-xs-9 col-md-9 col-md-9 text-left left-column'', null, ''col-xs-3 col-sm-3 col-md-3 text-right right-column'', null),
(3, ''TwoColumnShortRight'', ''row'', ''col-xs-8 col-sm-8 col-md-8 text-left left-column'', null, ''col-xs-4 col-sm-4 col-md-4 text-left right-column'', null),
(4, ''FullWidthRow'', ''row'', null, null, null, ''col-xs-12 col-sm-12 col-md-12 text-left full-width-column'')
;

declare @transferType1 NVARCHAR(max) = ''Acceptable to CSU, UC or Private''
declare @transferType2 NVARCHAR(max) = ''Acceptable to CSU or Private College''

--#endregion

declare @modelRoot table 
(
	CourseId int,
	InsertOrder int identity(1, 1) primary key,
	RootData nvarchar(max)
);


insert into @modelRoot (CourseId)
	select em.[Key]
	from @entityModels em
		inner join Course C on C.id = em.[Key]
		inner join Subject S on S.id = C.subjectid
	order by s.SubjectCode, dbo.fnCourseNumberToNumeric(c.CourseNumber),C.entitytitle;


declare @modelRootData table
(
	--Transfer nvarchar(max),
	CourseId int primary key
	, SubjectCode nvarchar(max)
	, CourseNumber nvarchar(max)
	, CourseTitle nvarchar(max)
	, CourseCredits nvarchar(max)
	, CourseDescription nvarchar(max)
	, CourseRequisites nvarchar(max)
	, Hours nvarchar(max)
	, Type nvarchar(max)
	, GradingMethod nvarchar(max)
	, Descp nvarchar(max)
	, Repeatability nvarchar(max)
	, CID nvarchar(max)
	, Transfer nvarchar(max)
);

insert into @modelRootData (
    CourseId
	, SubjectCode
	, CourseNumber
	, CourseTitle
	, CourseDescription
	, CourseCredits
	, CourseRequisites
	, Hours 
	, Type 
	, GradingMethod 
	, Descp
	, Repeatability
	, CID
	, Transfer
)
select
	C.id as CourseId
	, s.SubjectCode as SubjectCode
	, c.CourseNumber as CourseNumber
	, c.Title as CourseTitle
	, lTrim(rTrim(c.[Description])) as CourseDescription
	, concat(units.MinUnits
		, CASE
			WHEN Cd.Variable = 1
				THEN CONCAT('' to '', units.MaxUnits)
			else ''''
		  END) as CourseCredits
	, REQ.Text as CourseRequisites
	, Hourstxt.text as Hours 
	, Type.text as Type 
	, GradingMethod.text as GradingMethod 
	, COURSE_DESC as Descp
	, ''Repeatable: '' + R.Code + '' Time'' + case when R.id <> 6 then ''s'' else '''' end as Repeatability
	, ''C-ID:'' + C.PatternNumber as CID
	, Transfer.text as Transfer
from @modelRoot mr
	inner join course C on C.id = MR.CourseId
	inner join CourseAttribute CA on C.id = CA.CourseId
	inner join CourseProposal CP on CP.CourseId = C.id
	inner join Subject S on C.SubjectId = S.id
	inner join CourseDescription CD on CD.CourseId = C.id
	inner join Semester S2 on s2.Id = CP.SemesterId
	left join Repeatability R on CP.RepeatabilityId = R.id
	inner join CourseCBCode CB on CB.courseid = C.id
	outer apply (
		select coalesce(dbo.ConcatWithSep_Agg(@Break,PluralRT.Title + @Colon + @space + A.text),@empty) as [Text]
		from (
			select cr.ListItemTypeId,Rt.Id,dbo.ConcatWithSepOrdered_Agg(@space,CR.SortOrder,concat(coalesce(s2.Subjectcode + @space + c2.CourseNumber,cr.CourseRequisiteComment), @space + con.Title)) as Text
			from CourseRequisite cr
				left join Course c2 on cr.Requisite_CourseId = c2.Id
				left join [Subject] s2 on c2.SubjectId = s2.Id
				left join RequisiteType rt on cr.RequisiteTypeId = rt.Id
				left join MinimumGrade mg on mg.Id = cr.MinimumGradeId
				left join CourseRequisite cr2 on CR.Parent_Id = CR2.id
				outer apply(select top 1 1 as id from CourseRequisite cr3 where CR.Parent_Id = CR3.Parent_Id and CR3.SortOrder > CR.SortOrder) cr3
				left join Condition con on con.Id = cr2.GroupConditionId and CR3.id is not null
			where cr.CourseId = C.id
			group by RT.id, cr.ListItemTypeId
		) A
		LEFT join RequisiteType RT on A.id = RT.Id
		Outer apply
		(
			select case 
				when RT.Title = ''Advisory''
				then ''Advisories''
				when RT.Title = ''Limitation on Enrollment''
				then ''Limitations on Enrollment''
				when A.ListItemTypeId = 14
				then ''Non Course Requirement''
				else RT.Title + ''s'' 
			end as Title
		) PluralRT
	) REQ
	outer apply (
		select CASE
			WHEN ca.DistrictCourseTypeId IN (1, 2) --Credit
				THEN 
					CAST(
						CAST(COALESCE(cd.MinLectureHour, 0) AS DECIMAL(16, 2))  
						+ (FLOOR((CAST(COALESCE(cd.MinLabHour, 0) AS DECIMAL(16, 2))  / 3) * 2) *.5 )
						+ (CAST(COALESCE(cd.MinFieldHour, 0) AS DECIMAL(16, 2))  / 2) 
						AS DECIMAL(16, 2)
						)
			WHEN ca.DistrictCourseTypeId IN (3)    --NonCredit
				THEN 0
		END as MinUnits,
		CASE
			WHEN ca.DistrictCourseTypeId IN (1, 2) --Credit
				THEN 
					CAST(
						CAST(COALESCE(cd.MaxLectureHour, 0) AS DECIMAL(16, 2))  
						+ (FLOOR((CAST(COALESCE(cd.MaxLabHour, 0) AS DECIMAL(16, 2))  / 3) * 2) *.5 )
						+ (CAST(COALESCE(cd.MaxFieldHour, 0) AS DECIMAL(16, 2))  / 2) 
						AS DECIMAL(16, 2)
						)
			WHEN ca.DistrictCourseTypeId IN (3)    --NonCredit
				THEN 0
		END as MaxUnits
	) Units
	outer apply (
		select cast(COALESCE(CD.MinLectureHour,0) + COALESCE(CD.MinLabHour,0) AS DECIMAL(16, 2) ) as MinHPW,
			cast(COALESCE(CD.MaxLectureHour,0) + COALESCE(CD.MaxLabHour,0) AS DECIMAL(16, 2) ) as MaxHPW,
			cast(COALESCE(CD.MinLectureHour,0) AS DECIMAL(16, 2) ) as minLecH,
			cast(COALESCE(CD.MaxLectureHour,0) AS DECIMAL(16, 2) ) as maxLecH,
			cast(COALESCE(CD.MinLabHour,0) AS DECIMAL(16, 2) ) as minLabH,
			cast(COALESCE(CD.MaxLabHour,0) AS DECIMAL(16, 2) ) as maxLabH
	) Hours
	outer apply (
		select case when Cd.Variable = 1 then concat(Hours.MinHPW,'' - '',Hours.MaxHPW,'' hours per week: ('',Hours.minLecH,'' - '',Hours.maxLecH,'' lecture hours/'',Hours.minLabH,'' - '',Hours.maxLabH,'' lab hours)'')
			else concat(Hours.MinHPW,'' hours per week: ('',Hours.minLecH,'' lecture hours/'',Hours.minLabH,'' lab hours)'')
		end as [text]
	) Hourstxt
	outer apply (
		select DCT.Description as [text]
		from DistrictCourseType DCT
		where DCT.id = CA.DistrictCourseTypeId
	) Type
	outer apply (
		select dbo.ConcatWithSepOrdered_Agg('', '',GradeO.id,GradeO.Description) as [text]
		from GradeOption GradeO
			inner join CourseGradeOption CGO on CGO.GradeOptionid = GradeO.id
		where CGO.courseid = C.id
	) GradingMethod
	outer apply (
		select case when CB.CB05Id = 1 then ''Transfer: CSU; UC'' when CB.CB05Id = 2 then ''Transfer: CSU'' else '''' end as text
	) Transfer

select mr.CourseId as [Value]
	-- custom-course-summary-context-wrapper
	, concat(
		dbo.fnHtmlOpenTag(@summaryWrapperTag,
			dbo.fnHtmlAttribute(@classAttrib, ''custom-course-summary-context-wrapper'')
			),
			-- another nested wrapper
			dbo.fnHtmlOpenTag(@summaryWrapperTag, concat(
				dbo.fnHtmlAttribute(@classAttrib, ''container-fluid course-summary-wrapper''), @space,
				dbo.fnHtmlAttribute(''data-course-id'', mrd.CourseId)
				)
				),
				-- Course Title row (Course subject code, number, title, credits)
				dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, ''course-title-row''))),
					dbo.fnHtmlOpenTag(@columnTag, dbo.fnhtmlattribute(@classAttrib, ecfw.FullWidthColumn)),
						dbo.fnHtmlOpenTag(@boldDataElementTag, dbo.fnhtmlattribute(@classAttrib, ''course-subject-code'')),
							UPPER(mrd.SubjectCode),
						dbo.fnHtmlCloseTag(@boldDataElementTag),
						@Space,
						dbo.fnHtmlOpenTag(@boldDataElementTag, dbo.fnhtmlattribute(@classAttrib, ''course-number'')),
							UPPER(SUBSTRING(mrd.CourseNumber, PATINDEX(''%[^0]%'', mrd.CourseNumber+''.''), LEN(mrd.CourseNumber)) ),
						dbo.fnHtmlCloseTag(@boldDataElementTag),
						dbo.fnHtmlOpenTag(@boldDataElementTag, dbo.fnhtmlattribute(@classAttrib, ''course-number-title-separator'')),
						@Space,@2Space,@2Space,@Space,
						dbo.fnHtmlCloseTag(@boldDataElementTag),
						dbo.fnHtmlOpenTag(@boldDataElementTag, dbo.fnhtmlattribute(@classAttrib, ''course-title'')),
							mrd.CourseTitle,
						dbo.fnHtmlCloseTag(@boldDataElementTag),
						@Space,@2Space,@2Space,@Space,
						dbo.fnHtmlOpenTag(@boldDataElementTag, dbo.fnhtmlattribute(@classAttrib, ''course-credits'')),
							mrd.CourseCredits,
						dbo.fnHtmlCloseTag(@boldDataElementTag),
					dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag),
				-- Hours Row
				dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, ''course-hours-row''))),
					dbo.fnHtmlOpenTag(@columnTag, dbo.fnhtmlattribute(@classAttrib, ecfw.FullWidthColumn)),
						dbo.fnHtmlOpenTag(@italicDataElementTag, dbo.fnhtmlattribute(@classAttrib, ''course-Hours'')),
							mrd.Hours,
						dbo.fnHtmlCloseTag(@italicDataElementTag),
					dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag),
				-- Course Type Row
				dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, ''course-type-Row''))),
					dbo.fnHtmlOpenTag(@columnTag, dbo.fnhtmlattribute(@classAttrib, ecfw.FullWidthColumn)),
						dbo.fnHtmlOpenTag(@italicDataElementTag, dbo.fnhtmlattribute(@classAttrib, ''course-type'')),
							mrd.Type,
						dbo.fnHtmlCloseTag(@italicDataElementTag),
					dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag),
				-- Course Type Row
				dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, ''course-GradingMethod-Row''))),
					dbo.fnHtmlOpenTag(@columnTag, dbo.fnhtmlattribute(@classAttrib, ecfw.FullWidthColumn)),
						dbo.fnHtmlOpenTag(@italicDataElementTag, dbo.fnhtmlattribute(@classAttrib, ''course-GradingMethod'')),
							mrd.GradingMethod,
						dbo.fnHtmlCloseTag(@italicDataElementTag),
					dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag),
				-- Course Requisites Row 
				dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, ''course-requisites-row''))),
					dbo.fnHtmlOpenTag(@columnTag, dbo.fnhtmlattribute(@classAttrib, ecfw.FullWidthColumn)),
						dbo.fnHtmlOpenTag(@italicDataElementTag, dbo.fnhtmlattribute(@classAttrib, ''course-requisites'')),
							mrd.CourseRequisites,
						dbo.fnHtmlCloseTag(@italicDataElementTag),
					dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag),
				-- Course Description Row 
				dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, ''course-Description-row''))),
					dbo.fnHtmlOpenTag(@columnTag, dbo.fnhtmlattribute(@classAttrib, ecfw.FullWidthColumn)),
						dbo.fnHtmlOpenTag(@DataElementTag, dbo.fnhtmlattribute(@classAttrib, ''course-Description'')),
							mrd.CourseDescription,
						dbo.fnHtmlCloseTag(@DataElementTag),
					dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag),
				-- Course Transfer Row 
				dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, ''course-Transfer-row''))),
					dbo.fnHtmlOpenTag(@columnTag, dbo.fnhtmlattribute(@classAttrib, ecfw.FullWidthColumn)),
						dbo.fnHtmlOpenTag(@italicDataElementTag, dbo.fnhtmlattribute(@classAttrib, ''course-Transfer'')),
							mrd.Transfer,
						dbo.fnHtmlCloseTag(@italicDataElementTag),
					dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag),
				-- Repeatability Row
				dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, ''course-GradingMethod-Row''))),
					dbo.fnHtmlOpenTag(@columnTag, dbo.fnhtmlattribute(@classAttrib, ecfw.FullWidthColumn)),
						dbo.fnHtmlOpenTag(@italicDataElementTag, dbo.fnhtmlattribute(@classAttrib, ''course-GradingMethod'')),
							mrd.Repeatability,
						dbo.fnHtmlCloseTag(@italicDataElementTag),
					dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag),
				-- C-ID Row
				dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, ''course-GradingMethod-Row''))),
					dbo.fnHtmlOpenTag(@columnTag, dbo.fnhtmlattribute(@classAttrib, ecfw.FullWidthColumn)),
						dbo.fnHtmlOpenTag(@italicDataElementTag, dbo.fnhtmlattribute(@classAttrib, ''course-GradingMethod'')),
							mrd.CID,
						dbo.fnHtmlCloseTag(@italicDataElementTag),
					dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag),
			dbo.fnHtmlCloseTag(@summaryWrapperTag),
		dbo.fnHtmlCloseTag(@summaryWrapperTag),''</div>''
	) as [Text]
from @modelRoot mr
inner join @modelRootData mrd on mr.CourseId = mrd.CourseId
inner join @elementClasses ecfw on ecfw.Id = 4 --4 = FullWidthRow
inner join @elementClasses ec2C on ec2C.Id = 2 --3 = Two col
order by mr.InsertOrder;
'
WHERE Id = 1

DECLARE @SQL NVARCHAR(MAX) = '
		declare @textbooks nvarchar(max);
		declare @manuals nvarchar(max);
		declare @periodicals nvarchar(max);
		declare @software nvarchar(max);
		declare @other nvarchar(max);
		declare @notes nvarchar(max);
		
		select @textbooks = coalesce(@textbooks, '''') +
			concat(
				Author
				, '' ''
				, ''<i>''
					, Title
				, ''</i>''
				, case
					when Edition is not null
						then
							concat(
								'' (''
								, Edition
								, ''/e). ''
							)
					else ''''
				end
				, Publisher + '', ''
				, City + '', ''
				, case
					when CalendarYear is not null
						then
							concat(
								''(''
								, CalendarYear
								, '').''
							)
					else ''''
				end
				, case
					when Rational is not null
						then
							concat(
								''(''
								, Rational
								, '').''
							)
					else ''''
				end
				, ''<br />''
			)
		from CourseTextbook
		where CourseId = @entityId;

		select @manuals = coalesce(@manuals, '''') +
			concat(
				Title
				, '', ''
				, Author
				, '', ''
				, Publisher
				, '', ''
				, CalendarYear
				, ''<br />''
			)
		from CourseManual
		where CourseId = @entityId;

		select @periodicals = coalesce(@periodicals, '''') +
			concat(
				Title
				, '', ''
				, Author
				, '', ''
				, PublicationName
				, '', ''
				, Volume
				, '', ''
				, PublicationYear
				, ''<br />''
			)
		from CoursePeriodical
		where courseid = @entityId;

		select @software = coalesce(@software, '''') +
			concat(
				Title
				, '', ''
				, Edition
				, '', ''
				, Publisher
				, ''<br />''
			)
		from CourseSoftware
		where CourseId = @entityId;

		select @other = coalesce(@other, '''') + 
			concat(
				TextOther
				, ''<br />
			'')
		from CourseTextOther
		where CourseId = @entityId;

		select @notes = coalesce(@notes, '''') + 
			concat(
				[Text]
				, ''<br />''
			)
		from CourseNote
		where courseid = @entityId;

		select 	0 as [Value]
			, concat(
				case 
					when @textbooks is null
						then ''''
					else ''<b>Textbooks:</b> <br />''
				end
				, @textbooks
				, case
					when @manuals is null
						then ''''
					else ''<b>Manuals: </b><br />''
				end
				, @manuals
				, case
					when @periodicals is null
						then ''''
					else ''<b>Periodicals: </b><br />''
				end
				, @periodicals
				, case
					when @software is null
						then ''''
					else ''<b>Software: </b><br />''
				end
				, @software
				, case
					when @other is null
						then ''''
					else ''<b>Other: </b><br />''
				end
				, @other
				, case
					when @notes is null
						then ''''
					else ''<b>Notes: </b><br />''
				end
				, @notes
			) as [Text]
		;
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE ID = 56174224

DECLARE @SQL2 NVARCHAR(MAX) = '
SELECT COALESCE(dbo.ConcatWithSepOrdered_Agg(''<br>'', COALESCE(RT.SortOrder, 3), COALESCE(PluralRT.Title, '' '') + '' '' + A.text), '''') AS [Text]
FROM (
    SELECT
        RT.id,
        dbo.ConcatWithSepOrdered_Agg('' '', CR.SortOrder, CONCAT(COALESCE(s2.Subjectcode + '' '' + c2.CourseNumber, cr.CourseRequisiteComment), '' '' + con.Title)) AS Text,
        cr.ListItemTypeId
    FROM
        CourseRequisite cr
        LEFT JOIN Course c2 ON cr.Requisite_CourseId = c2.Id
        LEFT JOIN [Subject] s2 ON c2.SubjectId = s2.Id
        LEFT JOIN RequisiteType rt ON cr.RequisiteTypeId = rt.Id
        LEFT JOIN MinimumGrade mg ON mg.Id = cr.MinimumGradeId
        LEFT JOIN CourseRequisite cr2 ON CR.Parent_Id = CR2.id AND cr2.ListItemTypeId <> 3
        OUTER APPLY (
            SELECT TOP 1 1 AS id
            FROM CourseRequisite cr3
            WHERE CR.Parent_Id = CR3.Parent_Id AND CR3.SortOrder > CR.SortOrder
        ) cr3
        LEFT JOIN Condition con ON con.Id = cr2.GroupConditionId AND CR3.id IS NOT NULL
    WHERE
        cr.CourseId = @EntityID
        AND cr.ListItemTypeId <> 3
    GROUP BY
        RT.id,
        cr.ListItemTypeId
) A
LEFT JOIN RequisiteType RT ON A.id = RT.Id
LEFT JOIN ListItemType lt ON A.ListItemTypeId = lt.Id
OUTER APPLY (
    SELECT CASE
            WHEN RT.Title = ''Advisory'' THEN ''Advisories''
            WHEN RT.Title = ''Limitation on Enrollment'' THEN ''Limitations on Enrollment''
            WHEN lt.Id = 14 THEN ''Non Course Requirements''
            ELSE RT.Title + ''s''
        END AS Title
) PluralRT;
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL2
, ResolutionSql = @SQL2
WHERE ID = 56174212

DECLARE @SQL3 NVARCHAR(MAX) = '
		select 0 as [Value]
			, concat(
				''<div style="padding-bottom: 5px;">''
					, ''<b>Department: </b>''
					, oeDep.Title
				, ''</div>''
				, ''<div style="padding-bottom: 5px;">''
					, ''<b>Division: </b>''
					, oeDiv.Title
				, ''</div>''
			) as [Text]
		from Course c
			inner join [Subject] s on c.SubjectId = s.Id
			inner join OrganizationSubject os on s.Id = os.SubjectId
			inner join OrganizationEntity oeDep on os.OrganizationEntityId = oeDep.Id
			inner join OrganizationLink ol on oeDep.Id = ol.Child_OrganizationEntityId
			inner join OrganizationEntity oeDiv on ol.Parent_OrganizationEntityId = oeDiv.Id
		where c.Id = @entityId
		and ol.Active = 1
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL3
, ResolutionSql = @SQL3
WHERE Id = 56174218

DECLARE @Sections TABLE (SectionId int, TemplateId int)
INSERT INTO @Sections
SELECT mss.MetaSelectedSectionId, mt.MetaTemplateId FROM MetaSelectedSection AS mss
INNER JOIN MetaSelectedSection AS mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
INNER JOIN MetaTemplate AS mt on mss2.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE mt.Active = 1 
    AND mtt.EntityTypeId = 1
    AND mt.IsDraft = 0
    AND mt.EndDate IS NULL
    AND mtt.Active = 1
    AND mtt.IsPresentationView = 0		--comment out if doing reports and forms
    AND mtt.ClientId = 1
		AND mss.MetaBaseSchemaId = 248

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
SELECT
'Comments', -- [DisplayName]
151, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
2, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'TextArea', -- [DefaultDisplayType]
17, -- [MetaPresentationTypeId]
100, -- [Width]
2, -- [WidthUnit]
100, -- [Height]
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
FROM @Sections

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mt.MetaTemplateId FROM MetaTemplate AS mt
	INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaSelectedField AS msf on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId
	INNER JOIN @FIELDS AS f on f.Id = msf.MetaSelectedFieldId
	UNION
	SELECT mt.MetaTemplateId FROM MetaTemplate AS mt
	INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaSelectedField AS msf on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId
	WHERE msf.MetaAvailableFieldId = 922
	UNION
	SELECT mt.MetaTemplateId FROM MetaTemplate AS mt
	INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaSelectedField AS msf on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId in (56174224, 56174212, 56174218)
	UNION
	SELECT TemplateId FROM @Sections
)